import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { AuthProvider } from './contexts/AuthContext';
import { CacheProvider } from './contexts/CacheContext';
import { SidebarProvider } from './contexts/SidebarContext';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import CompanyManagementPage from './pages/CompanyManagementPage';
import ArchivedCompaniesPage from './pages/ArchivedCompaniesPage';
import UserManagementPage from './pages/UserManagementPage';
import SubscriptionPlanManagementPage from './pages/SubscriptionPlanManagementPage';
import AnalyticsPage from './pages/AnalyticsPage';
import SettingsPage from './pages/SettingsPage';
import MonitoringPage from './pages/MonitoringPage';
import TestConnectionPage from './pages/TestConnectionPage';
import ChangePasswordPage from './pages/ChangePasswordPage';
import BillingPage from './pages/BillingPage';
import SuperAdminRoute from './components/SuperAdminRoute';
import AdminRoute from './components/AdminRoute';

// Create theme
const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <CacheProvider>
          <SidebarProvider>
            <Router>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/test-connection" element={<TestConnectionPage />} />
              
              {/* Protected Routes */}
              <Route path="/" element={
                <SuperAdminRoute>
                  <Layout>
                    <DashboardPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/dashboard" element={
                <SuperAdminRoute>
                  <Layout>
                    <DashboardPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/companies" element={
                <SuperAdminRoute>
                  <Layout>
                    <CompanyManagementPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/companies/archived" element={
                <SuperAdminRoute>
                  <Layout>
                    <ArchivedCompaniesPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/users" element={
                <SuperAdminRoute>
                  <Layout>
                    <UserManagementPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/subscription-plans" element={
                <SuperAdminRoute>
                  <Layout>
                    <SubscriptionPlanManagementPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/analytics" element={
                <SuperAdminRoute>
                  <Layout>
                    <AnalyticsPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/settings" element={
                <SuperAdminRoute>
                  <Layout>
                    <SettingsPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/billing" element={
                <SuperAdminRoute>
                  <Layout>
                    <BillingPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/monitoring" element={
                <SuperAdminRoute>
                  <Layout>
                    <MonitoringPage />
                  </Layout>
                </SuperAdminRoute>
              } />
              
              <Route path="/change-password" element={
                <AdminRoute>
                  <Layout>
                    <ChangePasswordPage />
                  </Layout>
                </AdminRoute>
              } />
            </Routes>
          </Router>
          </SidebarProvider>
        </CacheProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
