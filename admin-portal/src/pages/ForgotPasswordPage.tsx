import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
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
  Email as EmailIcon,
  ArrowBack as ArrowBackIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');
  
  const navigate = useNavigate();
  const theme = useTheme();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsSubmitting(true);

    try {
      const response = await apiService.post('/api/auth/forgot-password', { email }) as any;
      
      if (response.success) {
        setSuccess(true);
      } else {
        setError(response.message || 'Failed to send reset email');
      }
    } catch (err: any) {
      console.error('Forgot password error:', err);
      setError(err.response?.data?.message || 'Failed to send reset email. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleBackToLogin = () => {
    navigate('/login');
  };

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
                Reset Code Sent!
              </Typography>
              <Typography variant="body2">
                We've sent a password reset code to <strong>{email}</strong>.
                Please check your email and use the code to reset your password.
              </Typography>
            </Alert>

            <Typography variant="body2" color="text.secondary" sx={{ mb: 4, textAlign: 'center' }}>
              If you don't see the email, check your spam folder. The reset code will expire in 1 hour.
            </Typography>

            <Box sx={{ display: 'flex', gap: 2, flexDirection: { xs: 'column', sm: 'row' }, width: '100%' }}>
              <Button
                variant="contained"
                onClick={() => navigate('/reset-password-code')}
                sx={{
                  textTransform: 'none',
                  borderRadius: 2,
                  py: 1.5,
                  px: 4,
                  flex: 1,
                  '&:hover': {
                    boxShadow: '0 6px 20px rgba(0,0,0,0.2)',
                  }
                }}
              >
                Enter Reset Code
              </Button>
              
              <Button
                variant="outlined"
                onClick={handleBackToLogin}
                startIcon={<ArrowBackIcon />}
                sx={{
                  textTransform: 'none',
                  borderRadius: 2,
                  py: 1.5,
                  px: 4,
                  borderColor: 'primary.main',
                  color: 'primary.main',
                  flex: 1,
                  '&:hover': {
                    borderColor: 'primary.dark',
                    backgroundColor: 'primary.main',
                    color: 'white',
                  }
                }}
              >
                Back to Login
              </Button>
            </Box>
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
            Forgot Password
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 4, textAlign: 'center' }}>
            Enter your email address and we'll send you a code to reset your password
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
              id="email"
              label="Email Address"
              name="email"
              type="email"
              autoComplete="email"
              autoFocus
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={isSubmitting}
              sx={{ mb: 3 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <EmailIcon color="action" />
                  </InputAdornment>
                ),
              }}
            />

            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={isSubmitting || !email}
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
                'Send Reset Code'
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

export default ForgotPasswordPage; 