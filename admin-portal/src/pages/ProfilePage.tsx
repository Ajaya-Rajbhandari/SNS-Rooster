import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Avatar,
  Divider,
  Alert,
  CircularProgress,
  Chip,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions
} from '@mui/material';
import {
  Edit as EditIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  Person as PersonIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Business as BusinessIcon,
  Security as SecurityIcon,
  PhotoCamera as PhotoCameraIcon
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import apiService from '../services/apiService';

interface ProfileData {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  role: string;
  avatar: string;
  isEmailVerified: boolean;
  lastLogin: string;
  createdAt: string;
}

interface SecuritySettings {
  twoFactorEnabled: boolean;
  loginNotifications: boolean;
  passwordChangeNotifications: boolean;
}

const ProfilePage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  
  const [profileData, setProfileData] = useState<ProfileData>({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    email: user?.email || '',
    phone: '',
    role: user?.role || 'super_admin',
    avatar: '',
    isEmailVerified: false,
    lastLogin: '',
    createdAt: new Date().toISOString()
  });

  const [securitySettings, setSecuritySettings] = useState<SecuritySettings>({
    twoFactorEnabled: false,
    loginNotifications: true,
    passwordChangeNotifications: true
  });

  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [showAvatarDialog, setShowAvatarDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);

  const handleSave = async () => {
    setIsLoading(true);
    try {
      // Here you would typically call an API to update the profile
      // For now, we'll simulate the update
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setMessage({ type: 'success', text: 'Profile updated successfully!' });
      setIsEditing(false);
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to update profile. Please try again.' });
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancel = () => {
    setProfileData({
      firstName: user?.firstName || '',
      lastName: user?.lastName || '',
      email: user?.email || '',
      phone: '',
      role: user?.role || 'super_admin',
      avatar: '',
      isEmailVerified: false,
      lastLogin: '',
      createdAt: new Date().toISOString()
    });
    setIsEditing(false);
    setMessage(null);
  };

  const handleSecuritySettingChange = (setting: keyof SecuritySettings, value: any) => {
    setSecuritySettings(prev => ({
      ...prev,
      [setting]: value
    }));
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      // Validate file type
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
      if (!allowedTypes.includes(file.type)) {
        setMessage({ type: 'error', text: 'Please select a valid image file (JPG, PNG, GIF, WebP)' });
        return;
      }
      
      // Validate file size (5MB limit)
      if (file.size > 5 * 1024 * 1024) {
        setMessage({ type: 'error', text: 'File size must be less than 5MB' });
        return;
      }
      
      setSelectedFile(file);
    }
  };

  const handleAvatarUpload = async () => {
    if (!selectedFile) {
      setMessage({ type: 'error', text: 'Please select a file first' });
      return;
    }

    setUploadingAvatar(true);
    try {
      const formData = new FormData();
      formData.append('profilePicture', selectedFile);
      
      // Add any other profile fields that might need updating
      formData.append('firstName', profileData.firstName);
      formData.append('lastName', profileData.lastName);
      formData.append('email', profileData.email);
      if (profileData.phone) {
        formData.append('phone', profileData.phone);
      }

      const response = await apiService.patch<any>('/api/auth/me', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response && response.profile) {
        setProfileData(prev => ({
          ...prev,
          avatar: response.profile.avatar || response.profile.profilePicture || '',
          firstName: response.profile.firstName || prev.firstName,
          lastName: response.profile.lastName || prev.lastName,
          email: response.profile.email || prev.email,
          phone: response.profile.phone || prev.phone,
        }));
        
        setMessage({ type: 'success', text: 'Profile picture uploaded successfully!' });
        setShowAvatarDialog(false);
        setSelectedFile(null);
      }
    } catch (error: any) {
      console.error('Avatar upload error:', error);
      setMessage({ 
        type: 'error', 
        text: error.response?.data?.message || 'Failed to upload profile picture. Please try again.' 
      });
    } finally {
      setUploadingAvatar(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  return (
    <Box sx={{ maxWidth: 1200, margin: '0 auto' }}>
      <Typography variant="h4" gutterBottom sx={{ mb: 3 }}>
        Profile Settings
      </Typography>

      {message && (
        <Alert severity={message.type} sx={{ mb: 3 }} onClose={() => setMessage(null)}>
          {message.text}
        </Alert>
      )}

      <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
        {/* Profile Information Card */}
        <Card sx={{ flex: '1 1 600px' }}>
          <CardContent>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h6">Personal Information</Typography>
              <Box>
                {!isEditing ? (
                  <Button
                    variant="outlined"
                    startIcon={<EditIcon />}
                    onClick={() => setIsEditing(true)}
                  >
                    Edit Profile
                  </Button>
                ) : (
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                      variant="contained"
                      startIcon={isLoading ? <CircularProgress size={20} /> : <SaveIcon />}
                      onClick={handleSave}
                      disabled={isLoading}
                    >
                      Save
                    </Button>
                    <Button
                      variant="outlined"
                      startIcon={<CancelIcon />}
                      onClick={handleCancel}
                      disabled={isLoading}
                    >
                      Cancel
                    </Button>
                  </Box>
                )}
              </Box>
            </Box>

            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <TextField
                label="First Name"
                value={profileData.firstName}
                onChange={(e) => setProfileData(prev => ({ ...prev, firstName: e.target.value }))}
                disabled={!isEditing}
                InputProps={{
                  startAdornment: <PersonIcon sx={{ mr: 1, color: 'action.active' }} />
                }}
                sx={{ flex: '1 1 200px' }}
              />
              <TextField
                label="Last Name"
                value={profileData.lastName}
                onChange={(e) => setProfileData(prev => ({ ...prev, lastName: e.target.value }))}
                disabled={!isEditing}
                InputProps={{
                  startAdornment: <PersonIcon sx={{ mr: 1, color: 'action.active' }} />
                }}
                sx={{ flex: '1 1 200px' }}
              />
            </Box>

            <TextField
              fullWidth
              label="Email Address"
              value={profileData.email}
              onChange={(e) => setProfileData(prev => ({ ...prev, email: e.target.value }))}
              disabled={!isEditing}
              InputProps={{
                startAdornment: <EmailIcon sx={{ mr: 1, color: 'action.active' }} />
              }}
              sx={{ mt: 2 }}
            />
            {profileData.isEmailVerified && (
              <Chip
                label="Email Verified"
                color="success"
                size="small"
                sx={{ mt: 1 }}
              />
            )}

            <TextField
              fullWidth
              label="Phone Number"
              value={profileData.phone}
              onChange={(e) => setProfileData(prev => ({ ...prev, phone: e.target.value }))}
              disabled={!isEditing}
              InputProps={{
                startAdornment: <PhoneIcon sx={{ mr: 1, color: 'action.active' }} />
              }}
              sx={{ mt: 2 }}
            />

            <TextField
              fullWidth
              label="Role"
              value={profileData.role === 'super_admin' ? 'Super Admin' : profileData.role}
              disabled
              InputProps={{
                startAdornment: <BusinessIcon sx={{ mr: 1, color: 'action.active' }} />
              }}
              sx={{ mt: 2 }}
            />
          </CardContent>
        </Card>

        {/* Avatar and Quick Actions */}
        <Card sx={{ flex: '0 1 300px' }}>
          <CardContent>
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', mb: 3 }}>
              <Avatar
                sx={{
                  width: 120,
                  height: 120,
                  fontSize: '3rem',
                  backgroundColor: '#1976d2',
                  mb: 2
                }}
                src={profileData.avatar}
              >
                {profileData.firstName?.charAt(0) || 'S'}
              </Avatar>
              <Button
                variant="outlined"
                startIcon={<PhotoCameraIcon />}
                onClick={() => setShowAvatarDialog(true)}
                disabled={!isEditing}
              >
                Change Photo
              </Button>
            </Box>

            <Divider sx={{ my: 2 }} />

            <Typography variant="h6" gutterBottom>
              Account Information
            </Typography>
            
            <List dense>
              <ListItem>
                <ListItemIcon>
                  <PersonIcon />
                </ListItemIcon>
                <ListItemText
                  primary="Member Since"
                  secondary={profileData.createdAt ? formatDate(profileData.createdAt) : 'N/A'}
                />
              </ListItem>
              <ListItem>
                <ListItemIcon>
                  <SecurityIcon />
                </ListItemIcon>
                <ListItemText
                  primary="Last Login"
                  secondary={profileData.lastLogin ? formatDate(profileData.lastLogin) : 'N/A'}
                />
              </ListItem>
            </List>
          </CardContent>
        </Card>
      </Box>

      {/* Security Settings */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Security Settings
          </Typography>
          
          <Box sx={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
            <FormControlLabel
              control={
                <Switch
                  checked={securitySettings.twoFactorEnabled}
                  onChange={(e) => handleSecuritySettingChange('twoFactorEnabled', e.target.checked)}
                />
              }
              label="Two-Factor Authentication"
            />
            <Typography variant="body2" color="text.secondary" sx={{ ml: 4 }}>
              Add an extra layer of security to your account
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', gap: 4, flexWrap: 'wrap', mt: 2 }}>
            <FormControlLabel
              control={
                <Switch
                  checked={securitySettings.loginNotifications}
                  onChange={(e) => handleSecuritySettingChange('loginNotifications', e.target.checked)}
                />
              }
              label="Login Notifications"
            />
            <Typography variant="body2" color="text.secondary" sx={{ ml: 4 }}>
              Get notified when someone logs into your account
            </Typography>
          </Box>
          
          <Box sx={{ display: 'flex', gap: 4, flexWrap: 'wrap', mt: 2 }}>
            <FormControlLabel
              control={
                <Switch
                  checked={securitySettings.passwordChangeNotifications}
                  onChange={(e) => handleSecuritySettingChange('passwordChangeNotifications', e.target.checked)}
                />
              }
              label="Password Change Notifications"
            />
            <Typography variant="body2" color="text.secondary" sx={{ ml: 4 }}>
              Get notified when your password is changed
            </Typography>
          </Box>

          <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              onClick={() => navigate('/change-password')}
            >
              Change Password
            </Button>
            <Button
              variant="outlined"
              color="error"
              onClick={() => setShowDeleteDialog(true)}
            >
              Delete Account
            </Button>
          </Box>
        </CardContent>
      </Card>

      {/* Avatar Upload Dialog */}
      <Dialog open={showAvatarDialog} onClose={() => setShowAvatarDialog(false)}>
        <DialogTitle>Change Profile Photo</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary">
            Upload a new profile photo. Supported formats: JPG, PNG, GIF, WebP (max 5MB)
          </Typography>
          <Box sx={{ mt: 2, textAlign: 'center' }}>
            <input
              accept="image/*"
              style={{ display: 'none' }}
              id="avatar-upload"
              type="file"
              onChange={handleFileSelect}
            />
            <label htmlFor="avatar-upload">
              <Button variant="contained" component="span">
                Choose File
              </Button>
            </label>
            {selectedFile && (
              <Typography variant="body2" sx={{ mt: 1 }}>
                Selected: {selectedFile.name}
              </Typography>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            setShowAvatarDialog(false);
            setSelectedFile(null);
          }}>
            Cancel
          </Button>
          <Button 
            variant="contained" 
            onClick={handleAvatarUpload}
            disabled={!selectedFile || uploadingAvatar}
            startIcon={uploadingAvatar ? <CircularProgress size={20} /> : undefined}
          >
            {uploadingAvatar ? 'Uploading...' : 'Upload'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete Account Dialog */}
      <Dialog open={showDeleteDialog} onClose={() => setShowDeleteDialog(false)}>
        <DialogTitle>Delete Account</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="error">
            This action cannot be undone. All your data will be permanently deleted.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowDeleteDialog(false)}>Cancel</Button>
          <Button variant="contained" color="error">
            Delete Account
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default ProfilePage; 