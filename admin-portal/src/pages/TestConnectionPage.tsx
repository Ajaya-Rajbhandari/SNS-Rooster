import React, { useState } from 'react';
import {
  Box,
  Button,
  Typography,
  Paper,
  Alert,
  CircularProgress,
  Container,
  TextField
} from '@mui/material';
import apiService from '../services/apiService';

const TestConnectionPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState<string>('');
  const [testEmail, setTestEmail] = useState('');
  const [testPassword, setTestPassword] = useState('');

  const testLogin = async () => {
    if (!testEmail || !testPassword) {
      setError('Please enter test credentials');
      return;
    }

    setLoading(true);
    setError('');
    setResult(null);

    try {
      const response = await apiService.post('/api/auth/login', {
        email: testEmail,
        password: testPassword
      });

      setResult({
        type: 'login',
        data: response,
        success: true
      });

      // Test subscription plans with the token
      if ((response as any).token) {
        try {
          const plansResponse = await apiService.get('/api/super-admin/subscription-plans');
          setResult({
            type: 'plans',
            data: plansResponse,
            success: true
          });
        } catch (plansError: any) {
          setError(`Plans error: ${plansError.response?.data?.message || plansError.message}`);
        }
      }
    } catch (err: any) {
      setError(`Login error: ${err.response?.data?.message || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const testPlans = async () => {
    setLoading(true);
    setError('');
    setResult(null);

    try {
      const response = await apiService.get('/api/super-admin/subscription-plans');
      setResult({
        type: 'plans',
        data: response,
        success: true
      });
    } catch (err: any) {
      setError(`Plans error: ${err.response?.data?.message || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const checkAuthToken = () => {
    const token = localStorage.getItem('authToken');
    const user = localStorage.getItem('user');
    
    setResult({
      type: 'auth_check',
      data: {
        hasToken: !!token,
        tokenLength: token?.length || 0,
        hasUser: !!user,
        user: user ? JSON.parse(user) : null
      },
      success: true
    });
  };

  return (
    <Container maxWidth="md">
      <Box sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" gutterBottom>
          Admin Portal Connection Test
        </Typography>
        
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
            Test Credentials
          </Typography>
          
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mb: 3 }}>
            <TextField
              fullWidth
              label="Test Email"
              value={testEmail}
              onChange={(e) => setTestEmail(e.target.value)}
              placeholder="Enter test email"
            />
            <TextField
              fullWidth
              label="Test Password"
              type="password"
              value={testPassword}
              onChange={(e) => setTestPassword(e.target.value)}
              placeholder="Enter test password"
            />
          </Box>
          
          <Box sx={{ display: 'flex', gap: 2, mb: 3 }}>
            <Button
              variant="outlined"
              onClick={checkAuthToken}
              disabled={loading}
            >
              Check Auth Token
            </Button>
            
            <Button
              variant="contained"
              onClick={testLogin}
              disabled={loading || !testEmail || !testPassword}
            >
              Test Login
            </Button>
            
            <Button
              variant="outlined"
              onClick={testPlans}
              disabled={loading}
            >
              Test Plans (with token)
            </Button>
          </Box>

          {loading && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <CircularProgress size={20} />
              <Typography>Testing...</Typography>
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mt: 2 }}>
              {error}
            </Alert>
          )}

          {result && (
            <Alert severity={result.success ? 'success' : 'error'} sx={{ mt: 2 }}>
              <Typography variant="h6">
                {result.type === 'login' && 'Login Test'}
                {result.type === 'plans' && 'Subscription Plans Test'}
                {result.type === 'auth_check' && 'Auth Token Check'}
              </Typography>
              <pre style={{ fontSize: '12px', overflow: 'auto' }}>
                {JSON.stringify(result.data, null, 2)}
              </pre>
            </Alert>
          )}
        </Paper>

        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Instructions
          </Typography>
          <Typography variant="body2" paragraph>
            1. <strong>Check Auth Token</strong> - Verify if you're logged in
          </Typography>
          <Typography variant="body2" paragraph>
            2. <strong>Test Login</strong> - Login with test credentials and test subscription plans
          </Typography>
          <Typography variant="body2" paragraph>
            3. <strong>Test Plans</strong> - Test subscription plans with existing token
          </Typography>
          <Typography variant="body2" color="text.secondary">
            If login works but plans don't, there's an authentication issue.
            If nothing works, check if the backend is running on port 5000.
          </Typography>
        </Paper>
      </Box>
    </Container>
  );
};

export default TestConnectionPage; 