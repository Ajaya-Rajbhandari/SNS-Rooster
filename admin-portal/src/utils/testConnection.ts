import apiService from '../services/apiService';
import API_CONFIG from '../config/api';

interface LoginResponse {
  token: string;
  user: {
    _id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: string;
  };
}

interface UsersResponse {
  users: any[];
  totalPages: number;
  currentPage: number;
  total: number;
}

export const testBackendConnection = async (email?: string, password?: string) => {
  try {
    // Test 1: Basic connectivity
    await fetch(`${API_CONFIG.BASE_URL}/`);
    
    // Test 2: Super admin login (if credentials provided)
    let loginResponse: LoginResponse | null = null;
    if (email && password) {
      loginResponse = await apiService.post<LoginResponse>('/api/auth/login', {
        email,
        password
      });
    }
    
    // Test 3: Get users with token (if login successful)
    let usersResponse: UsersResponse | null = null;
    if (loginResponse?.token) {
      usersResponse = await apiService.get<UsersResponse>('/api/super-admin/users');
    }
    
    return {
      success: true,
      message: 'All tests passed',
      data: {
        backendReachable: true,
        loginSuccessful: !!loginResponse,
        usersCount: usersResponse?.users?.length || 0,
        totalUsers: usersResponse?.total || 0,
        userRole: loginResponse?.user?.role
      }
    };
    
  } catch (error: any) {
    return {
      success: false,
      message: error.message,
      error: error.response?.data || error
    };
  }
}; 