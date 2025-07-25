import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import SuperAdminRoute from './components/SuperAdminRoute';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import CompanyManagementPage from './pages/CompanyManagementPage';
import SubscriptionPlanManagementPage from './pages/SubscriptionPlanManagementPage';
import TestConnectionPage from './pages/TestConnectionPage';
import UserManagementPage from './pages/UserManagementPage';
import ChangePasswordPage from './pages/ChangePasswordPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import ResetPasswordPage from './pages/ResetPasswordPage';
import ResetPasswordWithCodePage from './pages/ResetPasswordWithCodePage';
import AnalyticsPage from './pages/AnalyticsPage';
import MonitoringPage from './pages/MonitoringPage';
import SettingsPage from './pages/SettingsPage';

// Placeholder components
const NotFoundPage = () => <div>404 - Page Not Found</div>;

// Create a modern theme
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
      light: '#42a5f5',
      dark: '#1565c0',
    },
    secondary: {
      main: '#dc004e',
    },
    background: {
      default: '#f5f5f5',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h4: {
      fontWeight: 700,
    },
    h6: {
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 12,
  },
  components: {
    MuiCard: {
      styleOverrides: {
        root: {
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
          border: '1px solid rgba(0,0,0,0.08)',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        },
      },
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Navigate to="/login" replace />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />
            <Route path="/reset-password-code" element={<ResetPasswordWithCodePage />} />
            <Route path="/test" element={<TestConnectionPage />} />
            <Route 
              path="/dashboard" 
              element={
                <ProtectedRoute>
                  <DashboardPage />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/companies" 
              element={
                <SuperAdminRoute>
                  <CompanyManagementPage />
                </SuperAdminRoute>
              } 
            />
            <Route 
              path="/subscription-plans" 
              element={
                <SuperAdminRoute>
                  <SubscriptionPlanManagementPage />
                </SuperAdminRoute>
              } 
            />
            <Route 
              path="/users" 
              element={
                <SuperAdminRoute>
                  <UserManagementPage />
                </SuperAdminRoute>
              } 
            />
            <Route 
              path="/analytics" 
              element={
                <SuperAdminRoute>
                  <AnalyticsPage />
                </SuperAdminRoute>
              } 
            />
            <Route 
              path="/monitoring" 
              element={
                <SuperAdminRoute>
                  <MonitoringPage />
                </SuperAdminRoute>
              } 
            />
            <Route 
              path="/settings" 
              element={
                <SuperAdminRoute>
                  <SettingsPage />
                </SuperAdminRoute>
              } 
            />
            <Route 
              path="/change-password" 
              element={
                <ProtectedRoute>
                  <ChangePasswordPage />
                </ProtectedRoute>
              } 
            />
            <Route path="*" element={<NotFoundPage />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
