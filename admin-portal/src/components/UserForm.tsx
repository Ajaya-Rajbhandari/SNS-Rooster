import React, { useState, useEffect } from 'react';
import {
  Box,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Typography,
  Alert,
  CircularProgress,
  FormHelperText,
  Chip
} from '@mui/material';
import companyService, { Company } from '../services/companyService';

interface User {
  _id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: 'super_admin' | 'admin' | 'employee';
  companyId?: {
    _id: string;
    name: string;
    domain: string;
  };
  department?: string;
  position?: string;
  isActive: boolean;
  createdAt: string;
  lastLogin?: string;
}

interface UserFormProps {
  user?: User | null;
  onSubmit: (userData: any) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

interface FormData {
  firstName: string;
  lastName: string;
  email: string;
  companyId: string;
  role: 'employee' | 'admin' | 'super_admin';
  department: string;
  position: string;
  password: string;
  generatePassword: boolean;
}

interface FormErrors {
  firstName?: string;
  lastName?: string;
  email?: string;
  companyId?: string;
  role?: string;
  password?: string;
}

const UserForm: React.FC<UserFormProps> = ({ user, onSubmit, onCancel, loading = false }) => {
  const [formData, setFormData] = useState<FormData>({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    email: user?.email || '',
    companyId: user?.companyId?._id || '',
    role: user?.role || 'employee',
    department: user?.department || '',
    position: user?.position || '',
    password: '',
    generatePassword: true
  });

  const [errors, setErrors] = useState<FormErrors>({});
  const [companies, setCompanies] = useState<Company[]>([]);
  const [companiesLoading, setCompaniesLoading] = useState(false);
  const [generatedPassword, setGeneratedPassword] = useState<string>('');

  const isEditMode = !!user;

  useEffect(() => {
    fetchCompanies();
  }, []);

  const fetchCompanies = async () => {
    setCompaniesLoading(true);
    try {
      const companiesData = await companyService.getCompanies();
      setCompanies(companiesData);
    } catch (error) {
      console.error('Error fetching companies:', error);
    } finally {
      setCompaniesLoading(false);
    }
  };

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.firstName.trim()) {
      newErrors.firstName = 'First name is required';
    }

    if (!formData.lastName.trim()) {
      newErrors.lastName = 'Last name is required';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (formData.role !== 'super_admin' && !formData.companyId) {
      newErrors.companyId = 'Company is required for non-super admin users';
    }

    if (!formData.generatePassword && !formData.password.trim()) {
      newErrors.password = 'Password is required when not auto-generating';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    const submitData = {
      firstName: formData.firstName.trim(),
      lastName: formData.lastName.trim(),
      email: formData.email.trim().toLowerCase(),
      role: formData.role,
      department: formData.department.trim() || undefined,
      position: formData.position.trim() || undefined,
      ...(formData.role !== 'super_admin' && formData.companyId && { companyId: formData.companyId }),
      ...(formData.generatePassword ? {} : { password: formData.password })
    };

    await onSubmit(submitData);
  };

  const handleInputChange = (field: keyof FormData, value: any) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));

    // Clear error when user starts typing
    if (errors[field as keyof FormErrors]) {
      setErrors(prev => ({
        ...prev,
        [field]: undefined
      }));
    }
  };

  const generateRandomPassword = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    let password = '';
    for (let i = 0; i < 12; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    setGeneratedPassword(password);
    setFormData(prev => ({ ...prev, password: password, generatePassword: false }));
  };

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
      <Typography variant="h6" gutterBottom>
        {isEditMode ? 'Edit User' : 'Add New User'}
      </Typography>

      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 3 }}>
        {/* First Name */}
        <Box>
          <TextField
            fullWidth
            label="First Name"
            value={formData.firstName}
            onChange={(e) => handleInputChange('firstName', e.target.value)}
            error={!!errors.firstName}
            helperText={errors.firstName}
            disabled={loading}
            required
          />
        </Box>

        {/* Last Name */}
        <Box>
          <TextField
            fullWidth
            label="Last Name"
            value={formData.lastName}
            onChange={(e) => handleInputChange('lastName', e.target.value)}
            error={!!errors.lastName}
            helperText={errors.lastName}
            disabled={loading}
            required
          />
        </Box>

        {/* Email */}
        <Box sx={{ gridColumn: '1 / -1' }}>
          <TextField
            fullWidth
            label="Email"
            type="email"
            value={formData.email}
            onChange={(e) => handleInputChange('email', e.target.value)}
            error={!!errors.email}
            helperText={errors.email}
            disabled={loading || isEditMode}
            required
          />
        </Box>

        {/* Role */}
        <Box>
          <FormControl fullWidth error={!!errors.role} disabled={loading}>
            <InputLabel>Role</InputLabel>
            <Select
              value={formData.role}
              onChange={(e) => handleInputChange('role', e.target.value)}
              label="Role"
            >
              <MenuItem value="employee">
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip label="EMPLOYEE" size="small" sx={{ backgroundColor: '#388e3c', color: 'white' }} />
                  <Typography>Employee</Typography>
                </Box>
              </MenuItem>
              <MenuItem value="admin">
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip label="ADMIN" size="small" sx={{ backgroundColor: '#1976d2', color: 'white' }} />
                  <Typography>Admin</Typography>
                </Box>
              </MenuItem>
              <MenuItem value="super_admin">
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip label="SUPER ADMIN" size="small" sx={{ backgroundColor: '#d32f2f', color: 'white' }} />
                  <Typography>Super Admin</Typography>
                </Box>
              </MenuItem>
            </Select>
            {errors.role && <FormHelperText>{errors.role}</FormHelperText>}
          </FormControl>
        </Box>

        {/* Company */}
        <Box>
          <FormControl fullWidth error={!!errors.companyId} disabled={loading || formData.role === 'super_admin'}>
            <InputLabel>Company</InputLabel>
            <Select
              value={formData.companyId}
              onChange={(e) => handleInputChange('companyId', e.target.value)}
              label="Company"
            >
              {companiesLoading ? (
                <MenuItem disabled>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <CircularProgress size={16} />
                    <Typography>Loading companies...</Typography>
                  </Box>
                </MenuItem>
              ) : (
                companies.map((company) => (
                  <MenuItem key={company._id} value={company._id}>
                    <Box>
                      <Typography variant="body2">{company.name}</Typography>
                      <Typography variant="caption" color="textSecondary">
                        {company.domain}
                      </Typography>
                    </Box>
                  </MenuItem>
                ))
              )}
            </Select>
            {errors.companyId && <FormHelperText>{errors.companyId}</FormHelperText>}
            {formData.role === 'super_admin' && (
              <FormHelperText>Super admins are not assigned to specific companies</FormHelperText>
            )}
          </FormControl>
        </Box>

        {/* Department */}
        <Box>
          <TextField
            fullWidth
            label="Department"
            value={formData.department}
            onChange={(e) => handleInputChange('department', e.target.value)}
            disabled={loading}
          />
        </Box>

        {/* Position */}
        <Box>
          <TextField
            fullWidth
            label="Position"
            value={formData.position}
            onChange={(e) => handleInputChange('position', e.target.value)}
            disabled={loading}
          />
        </Box>

        {/* Password Section */}
        <Box sx={{ gridColumn: '1 / -1' }}>
          <Box sx={{ border: '1px solid #e0e0e0', borderRadius: 1, p: 2 }}>
            <Typography variant="subtitle2" gutterBottom>
              Password Settings
            </Typography>
            
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
              <Button
                variant={formData.generatePassword ? "contained" : "outlined"}
                size="small"
                onClick={() => handleInputChange('generatePassword', true)}
                disabled={loading}
              >
                Auto-generate Password
              </Button>
              <Button
                variant={!formData.generatePassword ? "contained" : "outlined"}
                size="small"
                onClick={() => handleInputChange('generatePassword', false)}
                disabled={loading}
              >
                Set Custom Password
              </Button>
              {!formData.generatePassword && (
                <Button
                  variant="outlined"
                  size="small"
                  onClick={generateRandomPassword}
                  disabled={loading}
                >
                  Generate Random
                </Button>
              )}
            </Box>

            {!formData.generatePassword && (
              <TextField
                fullWidth
                label="Password"
                type="password"
                value={formData.password}
                onChange={(e) => handleInputChange('password', e.target.value)}
                error={!!errors.password}
                helperText={errors.password || "Enter a strong password (minimum 8 characters)"}
                disabled={loading}
                required
              />
            )}

            {formData.generatePassword && (
              <Alert severity="info" sx={{ mt: 1 }}>
                A secure password will be automatically generated and displayed after user creation.
              </Alert>
            )}
          </Box>
        </Box>
      </Box>

      {/* Action Buttons */}
      <Box sx={{ display: 'flex', gap: 2, mt: 3, justifyContent: 'flex-end' }}>
        <Button
          variant="outlined"
          onClick={onCancel}
          disabled={loading}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          variant="contained"
          disabled={loading}
          startIcon={loading ? <CircularProgress size={16} /> : undefined}
        >
          {loading ? 'Saving...' : (isEditMode ? 'Update User' : 'Create User')}
        </Button>
      </Box>
    </Box>
  );
};

export default UserForm; 