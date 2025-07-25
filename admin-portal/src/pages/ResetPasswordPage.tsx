import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import {
  Box,
  Paper,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Container,
  InputAdornment,
  useTheme
} from '@mui/material';
import {
  Business as BusinessIcon,
  Lock as LockIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  ArrowBack as ArrowBackIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

const ResetPasswordPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');
  const [token, setToken] = useState('');
  const [tokenValid, setTokenValid] = useState(false);
  const [tokenLoading, setTokenLoading] = useState(true);
  
  const navigate = useNavigate();
  const theme = useTheme();

  useEffect(() => {
    const tokenFromUrl = searchParams.get('token');
    if (tokenFromUrl) {
      setToken(tokenFromUrl);
      validateToken(tokenFromUrl);
    } else {
      setTokenLoading(false);
      setError('Invalid reset link. Please request a new password reset.');
    }
  }, [searchParams]);

  const validateToken = async (resetToken: string) => {
    try {
      const response = await apiService.post('/api/auth/validate-reset-token', { token: resetToken }) as any;
      if (response.valid) {
        setTokenValid(true);
      } else {
        setError('This reset link has expired or is invalid. Please request a new password reset.');
      }
    } catch (err: any) {
      console.error('Token validation error:', err);
      setError('Failed to validate reset link. Please try again.');
    } finally {
      setTokenLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validation
    if (password.length < 8) {
      setError('Password must be at least 8 characters long');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setIsSubmitting(true);

    try {
      const response = await apiService.post('/api/auth/reset-password', { 
        token, 
        newPassword: password 
      }) as any;
      
      if (response.success) {
        setSuccess(true);
      } else {
        setError(response.message || 'Failed to reset password');
      }
    } catch (err: any) {
      console.error('Reset password error:', err);
      setError(err.response?.data?.message || 'Failed to reset password. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleBackToLogin = () => {
    navigate('/login');
  };

  const handleTogglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  const handleToggleConfirmPasswordVisibility = () => {
    setShowConfirmPassword(!showConfirmPassword);
  };

  if (tokenLoading) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          p: 2
        }}
      >
        <Container component="main" maxWidth="sm">
          <Paper
            elevation={24}
            sx={{
              p: 4,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              borderRadius: 3,
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(255, 255, 255, 0.2)'
            }}
          >
            <CircularProgress size={60} />
            <Typography variant="h6" sx={{ mt: 2 }}>
              Validating reset link...
            </Typography>
          </Paper>
        </Container>
      </Box>
    );
  }

  if (success) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          p: 2
        }}
      >
        <Container component="main" maxWidth="sm">
          <Paper
            elevation={24}
            sx={{
              p: 4,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              borderRadius: 3,
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(255, 255, 255, 0.2)'
            }}
          >
            {/* Logo/Brand Section */}
            <Box sx={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: 2, 
              mb: 4,
              p: 2,
              borderRadius: 2,
              bgcolor: 'primary.main',
              color: 'white'
            }}>
              <BusinessIcon sx={{ fontSize: 40 }} />
              <Box>
                <Typography variant="h4" component="h1" sx={{ fontWeight: 700, lineHeight: 1 }}>
                  SNS Rooster
                </Typography>
                <Typography variant="subtitle1" sx={{ opacity: 0.9 }}>
                  Admin Portal
                </Typography>
              </Box>
            </Box>

            <Alert severity="success" sx={{ mb: 3, width: '100%' }}>
              <Typography variant="h6" gutterBottom>
                Password Reset Successful!
              </Typography>
              <Typography variant="body2">
                Your super admin password has been successfully reset. You can now log in with your new password.
              </Typography>
            </Alert>

            <Button
              variant="contained"
              onClick={handleBackToLogin}
              sx={{
                textTransform: 'none',
                borderRadius: 2,
                py: 1.5,
                px: 4,
              }}
            >
              Go to Login
            </Button>
          </Paper>
        </Container>
      </Box>
    );
  }

  if (!tokenValid) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          p: 2
        }}
      >
        <Container component="main" maxWidth="sm">
          <Paper
            elevation={24}
            sx={{
              p: 4,
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              borderRadius: 3,
              background: 'rgba(255, 255, 255, 0.95)',
              backdropFilter: 'blur(10px)',
              border: '1px solid rgba(255, 255, 255, 0.2)'
            }}
          >
            {/* Logo/Brand Section */}
            <Box sx={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: 2, 
              mb: 4,
              p: 2,
              borderRadius: 2,
              bgcolor: 'primary.main',
              color: 'white'
            }}>
              <BusinessIcon sx={{ fontSize: 40 }} />
              <Box>
                <Typography variant="h4" component="h1" sx={{ fontWeight: 700, lineHeight: 1 }}>
                  SNS Rooster
                </Typography>
                <Typography variant="subtitle1" sx={{ opacity: 0.9 }}>
                  Admin Portal
                </Typography>
              </Box>
            </Box>

            <Alert severity="error" sx={{ mb: 3, width: '100%' }}>
              <Typography variant="h6" gutterBottom>
                Invalid Reset Link
              </Typography>
              <Typography variant="body2">
                {error}
              </Typography>
            </Alert>

            <Button
              variant="outlined"
              onClick={handleBackToLogin}
              startIcon={<ArrowBackIcon />}
              sx={{
                textTransform: 'none',
                borderRadius: 2,
              }}
            >
              Back to Login
            </Button>
          </Paper>
        </Container>
      </Box>
    );
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        p: 2
      }}
    >
      <Container component="main" maxWidth="sm">
        <Paper
          elevation={24}
          sx={{
            p: 4,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            borderRadius: 3,
            background: 'rgba(255, 255, 255, 0.95)',
            backdropFilter: 'blur(10px)',
            border: '1px solid rgba(255, 255, 255, 0.2)'
          }}
        >
          {/* Logo/Brand Section */}
          <Box sx={{ 
            display: 'flex', 
            alignItems: 'center', 
            gap: 2, 
            mb: 4,
            p: 2,
            borderRadius: 2,
            bgcolor: 'primary.main',
            color: 'white'
          }}>
            <BusinessIcon sx={{ fontSize: 40 }} />
            <Box>
              <Typography variant="h4" component="h1" sx={{ fontWeight: 700, lineHeight: 1 }}>
                SNS Rooster
              </Typography>
              <Typography variant="subtitle1" sx={{ opacity: 0.9 }}>
                Admin Portal
              </Typography>
            </Box>
          </Box>

          <Typography component="h2" variant="h5" gutterBottom sx={{ fontWeight: 600, mb: 1 }}>
            Reset Super Admin Password
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 4, textAlign: 'center' }}>
            Enter your new password below
          </Typography>

          <Box component="form" onSubmit={handleSubmit} sx={{ width: '100%' }}>
            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}

            <TextField
              margin="normal"
              required
              fullWidth
              name="password"
              label="New Password"
              type={showPassword ? 'text' : 'password'}
              id="password"
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={isSubmitting}
              sx={{ mb: 2 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <LockIcon color="action" />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <Button
                      type="button"
                      onClick={handleTogglePasswordVisibility}
                      sx={{ minWidth: 'auto', p: 1 }}
                    >
                      {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                    </Button>
                  </InputAdornment>
                ),
              }}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              name="confirmPassword"
              label="Confirm New Password"
              type={showConfirmPassword ? 'text' : 'password'}
              id="confirmPassword"
              autoComplete="new-password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              disabled={isSubmitting}
              sx={{ mb: 3 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <LockIcon color="action" />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <Button
                      type="button"
                      onClick={handleToggleConfirmPasswordVisibility}
                      sx={{ minWidth: 'auto', p: 1 }}
                    >
                      {showConfirmPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                    </Button>
                  </InputAdornment>
                ),
              }}
            />

            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={isSubmitting || !password || !confirmPassword}
              sx={{
                py: 1.5,
                fontSize: '1.1rem',
                fontWeight: 600,
                textTransform: 'none',
                borderRadius: 2,
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                '&:hover': {
                  boxShadow: '0 6px 20px rgba(0,0,0,0.2)',
                }
              }}
            >
              {isSubmitting ? (
                <CircularProgress size={24} color="inherit" />
              ) : (
                'Reset Password'
              )}
            </Button>

            <Box sx={{ mt: 3, textAlign: 'center' }}>
              <Button
                variant="text"
                size="small"
                onClick={handleBackToLogin}
                startIcon={<ArrowBackIcon />}
                sx={{
                  color: 'text.secondary',
                  textTransform: 'none',
                  '&:hover': {
                    textDecoration: 'underline',
                  }
                }}
              >
                Back to Login
              </Button>
            </Box>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
};

export default ResetPasswordPage; 