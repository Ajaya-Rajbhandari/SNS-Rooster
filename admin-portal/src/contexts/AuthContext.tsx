import React, { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';
import apiService from '../services/apiService';

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
  isAuthenticated: boolean;
  validateToken: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(localStorage.getItem('authToken'));
  const [isLoading, setIsLoading] = useState(true);

  // Set up token in localStorage for apiService
  useEffect(() => {
    if (token) {
      localStorage.setItem('authToken', token);
    } else {
      localStorage.removeItem('authToken');
    }
  }, [token]);

  // Validate token with server
  const validateToken = useCallback(async (): Promise<boolean> => {
    if (!token) return false;
    
    try {
      const response = await apiService.get<{valid: boolean, user: User}>('/api/auth/validate');
      if (response.valid && response.user) {
        setUser(response.user);
        localStorage.setItem('user', JSON.stringify(response.user));
        return true;
      }
      return false;
    } catch (error) {
      // If validation endpoint is not available, try to use stored user data
      const storedUser = localStorage.getItem('user');
      if (storedUser) {
        try {
          const userData = JSON.parse(storedUser);
          setUser(userData);
          return true;
        } catch (parseError) {
          return false;
        }
      }
      return false;
    }
  }, [token]);

  // Check if token is valid on app start
  useEffect(() => {
    const checkToken = async () => {
      if (token) {
        const isValid = await validateToken();
        if (!isValid) {
          setToken(null);
          setUser(null);
          localStorage.removeItem('authToken');
          localStorage.removeItem('user');
          localStorage.removeItem('superAdminToken');
          localStorage.removeItem('refreshToken');
          localStorage.removeItem('companyId');
        }
      }
      setIsLoading(false);
    };

    checkToken();
  }, []); // Only run once on mount

  const login = async (email: string, password: string): Promise<boolean> => {
    try {
      setIsLoading(true);
      
      const response = await apiService.post<{token: string, user: User}>('/api/auth/login', {
        email,
        password
      });

      const { token: newToken, user: userData } = response;

      if (newToken && userData) {
        setToken(newToken);
        setUser(userData);
        localStorage.setItem('authToken', newToken);
        localStorage.setItem('user', JSON.stringify(userData));
        
        // Store super admin token separately if needed
        if (userData.role === 'super_admin') {
          localStorage.setItem('superAdminToken', newToken);
        }
        
        return true;
      }
      
      return false;
    } catch (error) {
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem('authToken');
    localStorage.removeItem('user');
    localStorage.removeItem('superAdminToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('companyId');
  };

  const value: AuthContextType = {
    user,
    token,
    isLoading,
    login,
    logout,
    isAuthenticated: !!token && !!user,
    validateToken
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}; 