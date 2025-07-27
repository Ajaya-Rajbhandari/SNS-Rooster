import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface AdminRouteProps {
  children: React.ReactNode;
}

const AdminRoute: React.FC<AdminRouteProps> = ({ children }) => {
  const { isAuthenticated, user, isLoading } = useAuth();

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // Allow admin and super_admin roles
  if (user && (user.role === 'admin' || user.role === 'super_admin')) {
    return <>{children}</>;
  }

  // Redirect to dashboard if not authorized
  return <Navigate to="/dashboard" replace />;
};

export default AdminRoute; 