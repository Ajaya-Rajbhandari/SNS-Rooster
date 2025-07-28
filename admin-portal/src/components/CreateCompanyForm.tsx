import React, { useState, useEffect } from 'react';
import {
  Box,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Typography,
  CircularProgress,
  Divider,
  Checkbox,
  FormControlLabel,
  Card,
  CardContent,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  Build as BuildIcon,
  CheckCircle as CheckCircleIcon
} from '@mui/icons-material';
import axios from 'axios';
import { useAuth } from '../contexts/AuthContext';
import API_CONFIG from '../config/api';

interface SubscriptionPlan {
  _id: string;
  name: string;
  description: string;
  price: {
    monthly: number;
    yearly: number;
  };
}

interface CreateCompanyFormProps {
  onSubmit: (companyData: any) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
  validationErrors?: any[];
}

const CreateCompanyForm: React.FC<CreateCompanyFormProps> = ({
  onSubmit,
  onCancel,
  loading = false,
  validationErrors = []
}) => {

  const { isAuthenticated, token } = useAuth();
  const [formData, setFormData] = useState({
    // Company Details
    name: '',
    domain: '',
    subdomain: '',
    contactPhone: '',
    address: {
      street: '',
      city: '',
      state: '',
      postalCode: '',
      country: ''
    },
    notes: '',
    
    // Admin User Details
    adminEmail: '',
    adminPassword: '',
    adminFirstName: '',
    adminLastName: '',
    
    // Subscription
    subscriptionPlanId: '',
    isCustomPlan: false,
    
    // Custom Plan Features
    customFeatures: {
      attendance: true,
      payroll: true,
      leaveManagement: true,
      analytics: false,
      documentManagement: true,
      notifications: true,
      customBranding: false,
      apiAccess: false,
      multiLocation: false,
      advancedReporting: false,
      timeTracking: true,
      expenseManagement: false,
      performanceReviews: false,
      trainingManagement: false
    },
    
    // Custom Plan Limits
    customLimits: {
      maxEmployees: 10,
      maxStorageGB: 5,
      maxApiCallsPerDay: 1000,
      maxLocations: 1
    }
  });

  const [subscriptionPlans, setSubscriptionPlans] = useState<SubscriptionPlan[]>([]);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loadingPlans, setLoadingPlans] = useState(true);

  // Fetch subscription plans
  useEffect(() => {
    const fetchSubscriptionPlans = async () => {
      try {
        // Get token from localStorage
        const token = localStorage.getItem('authToken');
        
        if (!token) {
          setSubscriptionPlans([]);
          setLoadingPlans(false);
          return;
        }
        
        const response = await axios.get(`${API_CONFIG.BASE_URL}/api/super-admin/subscription-plans`, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
        const plans = response.data.plans || [];
        setSubscriptionPlans(plans);
      } catch (error: any) {
        if (error.response?.status === 401) {
          setSubscriptionPlans([]);
        }
      } finally {
        setLoadingPlans(false);
      }
    };

    // Only fetch if authenticated
    if (isAuthenticated && token) {
      // Add a small delay to ensure authentication state is updated
      const timer = setTimeout(() => {
        fetchSubscriptionPlans();
      }, 100);

      return () => clearTimeout(timer);
    } else {
      setLoadingPlans(false);
    }
  }, [isAuthenticated, token]);

  const handleInputChange = (field: string, value: string) => {
    
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
    
    // Clear error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: ''
      }));
    }
  };

  const handleAddressChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      address: {
        ...prev.address,
        [field]: value
      }
    }));
  };

  const handleCustomFeatureChange = (feature: string, checked: boolean) => {
    setFormData(prev => ({
      ...prev,
      customFeatures: {
        ...prev.customFeatures,
        [feature]: checked
      }
    }));
  };

  const handleCustomLimitChange = (limit: string, value: number) => {
    setFormData(prev => ({
      ...prev,
      customLimits: {
        ...prev.customLimits,
        [limit]: value
      }
    }));
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    // Required fields validation
    if (!formData.name.trim()) newErrors.name = 'Company name is required';
    if (!formData.domain.trim()) newErrors.domain = 'Domain is required';
    if (!formData.subdomain.trim()) newErrors.subdomain = 'Subdomain is required';
    if (!formData.adminEmail.trim()) newErrors.adminEmail = 'Admin email is required';
    if (!formData.adminPassword.trim()) newErrors.adminPassword = 'Admin password is required';
    if (!formData.adminFirstName.trim()) newErrors.adminFirstName = 'Admin first name is required';
    if (!formData.adminLastName.trim()) newErrors.adminLastName = 'Admin last name is required';
    if (!formData.subscriptionPlanId) newErrors.subscriptionPlanId = 'Subscription plan is required';

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (formData.adminEmail && !emailRegex.test(formData.adminEmail)) {
      newErrors.adminEmail = 'Invalid email format';
    }

    // Password validation
    if (formData.adminPassword && formData.adminPassword.length < 6) {
      newErrors.adminPassword = 'Password must be at least 6 characters';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Function to get field-specific validation error
  const getFieldError = (fieldName: string) => {
    const error = validationErrors.find((err: any) => {
      // Check different possible field name properties
      const fieldMatch = err.path === fieldName || 
                        err.field === fieldName || 
                        err.param === fieldName ||
                        err.key === fieldName;
      
      return fieldMatch;
    });
    
    if (error) {
      return error.message || error.msg || error.error || 'Invalid value';
    }
    
    return '';
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    try {
      // Prepare submission data
      const submissionData = {
        ...formData,
        // Handle custom plan
        isCustomPlan: formData.subscriptionPlanId === 'custom',
        customFeatures: formData.subscriptionPlanId === 'custom' ? formData.customFeatures : undefined,
        customLimits: formData.subscriptionPlanId === 'custom' ? formData.customLimits : undefined,
        // Clear subscriptionPlanId if it's custom
        subscriptionPlanId: formData.subscriptionPlanId === 'custom' ? undefined : formData.subscriptionPlanId
      };

      await onSubmit(submissionData);
    } catch (error) {
      console.error('Error creating company:', error);
    }
  };

  return (
    <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
      <Typography variant="h6" gutterBottom>
        Company Information
      </Typography>
      
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Company Name"
          value={formData.name}
          onChange={(e) => handleInputChange('name', e.target.value)}
          error={!!errors.name || !!getFieldError('name')}
          helperText={errors.name || getFieldError('name')}
          required
        />
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Domain"
          value={formData.domain}
          onChange={(e) => handleInputChange('domain', e.target.value)}
          error={!!errors.domain || !!getFieldError('domain')}
          helperText={errors.domain || getFieldError('domain')}
          required
        />
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Subdomain"
          value={formData.subdomain}
          onChange={(e) => handleInputChange('subdomain', e.target.value)}
          error={!!errors.subdomain || !!getFieldError('subdomain')}
          helperText={errors.subdomain || getFieldError('subdomain')}
          required
        />
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Contact Phone"
          value={formData.contactPhone}
          onChange={(e) => handleInputChange('contactPhone', e.target.value)}
          error={!!getFieldError('contactPhone')}
          helperText={getFieldError('contactPhone')}
        />
      </Box>

      <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>
        Address Information
      </Typography>
      
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <TextField
          fullWidth
          label="Street Address"
          value={formData.address.street}
          onChange={(e) => handleAddressChange('street', e.target.value)}
          error={!!getFieldError('address.street')}
          helperText={getFieldError('address.street')}
        />
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
          <TextField
            sx={{ flex: '1 1 300px' }}
            label="City"
            value={formData.address.city}
            onChange={(e) => handleAddressChange('city', e.target.value)}
            error={!!getFieldError('address.city')}
            helperText={getFieldError('address.city')}
          />
          <TextField
            sx={{ flex: '1 1 300px' }}
            label="State/Province"
            value={formData.address.state}
            onChange={(e) => handleAddressChange('state', e.target.value)}
            error={!!getFieldError('address.state')}
            helperText={getFieldError('address.state')}
          />
        </Box>
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
          <TextField
            sx={{ flex: '1 1 300px' }}
            label="Postal Code"
            value={formData.address.postalCode}
            onChange={(e) => handleAddressChange('postalCode', e.target.value)}
            error={!!getFieldError('address.postalCode')}
            helperText={getFieldError('address.postalCode')}
          />
          <TextField
            sx={{ flex: '1 1 300px' }}
            label="Country"
            value={formData.address.country}
            onChange={(e) => handleAddressChange('country', e.target.value)}
            error={!!getFieldError('address.country')}
            helperText={getFieldError('address.country')}
          />
        </Box>
      </Box>

      <Divider sx={{ my: 3 }} />

      <Typography variant="h6" gutterBottom>
        Admin User Information
      </Typography>
      
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Admin Email"
          type="email"
          value={formData.adminEmail}
          onChange={(e) => handleInputChange('adminEmail', e.target.value)}
          error={!!errors.adminEmail || !!getFieldError('adminEmail')}
          helperText={errors.adminEmail || getFieldError('adminEmail')}
          required
        />
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Admin Password"
          type="password"
          value={formData.adminPassword}
          onChange={(e) => handleInputChange('adminPassword', e.target.value)}
          error={!!errors.adminPassword || !!getFieldError('adminPassword')}
          helperText={errors.adminPassword || getFieldError('adminPassword')}
          required
        />
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Admin First Name"
          value={formData.adminFirstName}
          onChange={(e) => handleInputChange('adminFirstName', e.target.value)}
          error={!!errors.adminFirstName || !!getFieldError('adminFirstName')}
          helperText={errors.adminFirstName || getFieldError('adminFirstName')}
          required
        />
        <TextField
          sx={{ flex: '1 1 300px' }}
          label="Admin Last Name"
          value={formData.adminLastName}
          onChange={(e) => handleInputChange('adminLastName', e.target.value)}
          error={!!errors.adminLastName || !!getFieldError('adminLastName')}
          helperText={errors.adminLastName || getFieldError('adminLastName')}
          required
        />
      </Box>

      <Divider sx={{ my: 3 }} />

      <Typography variant="h6" gutterBottom>
        Subscription Plan
      </Typography>
      
      <FormControl fullWidth error={!!errors.subscriptionPlanId}>
        <InputLabel>Subscription Plan</InputLabel>
        <Select
          value={formData.subscriptionPlanId}
          onChange={(e) => handleInputChange('subscriptionPlanId', e.target.value)}
          label="Subscription Plan"
          disabled={loadingPlans}
        >
          {loadingPlans ? (
            <MenuItem disabled>Loading plans...</MenuItem>
          ) : subscriptionPlans.length === 0 ? (
            <MenuItem disabled>No plans available</MenuItem>
          ) : [
            <MenuItem key="custom" value="custom">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <BuildIcon color="primary" />
                <Box>
                  <Typography variant="body1" fontWeight={500}>
                    Custom Plan
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Create a custom plan with specific features
                  </Typography>
                </Box>
              </Box>
            </MenuItem>,
            <Divider key="divider" />,
            ...subscriptionPlans.map((plan) => (
              <MenuItem key={plan._id} value={plan._id}>
                {plan.name} - ${plan.price.monthly}/month
              </MenuItem>
            ))
          ]}
        </Select>
        {errors.subscriptionPlanId && (
          <Typography variant="caption" color="error">
            {errors.subscriptionPlanId}
          </Typography>
        )}
        {!loadingPlans && subscriptionPlans.length === 0 && (
          <Typography variant="caption" color="warning.main">
            No subscription plans found. Please login as super admin or check the console for errors.
          </Typography>
        )}
      </FormControl>

      {/* Custom Plan Feature Selection */}
      {formData.subscriptionPlanId === 'custom' && (
        <Box sx={{ mt: 3 }}>
          <Card variant="outlined">
            <CardContent>
              <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <BuildIcon color="primary" />
                Custom Plan Configuration
              </Typography>
              
              {/* Feature Categories */}
              <Accordion defaultExpanded>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Typography variant="subtitle1" fontWeight={500}>
                    Core Features (Always Enabled)
                  </Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 2 }}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.attendance}
                          disabled
                          icon={<CheckCircleIcon color="success" />}
                        />
                      }
                      label="Attendance Tracking"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.payroll}
                          disabled
                          icon={<CheckCircleIcon color="success" />}
                        />
                      }
                      label="Payroll Management"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.leaveManagement}
                          disabled
                          icon={<CheckCircleIcon color="success" />}
                        />
                      }
                      label="Leave Management"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.documentManagement}
                          disabled
                          icon={<CheckCircleIcon color="success" />}
                        />
                      }
                      label="Document Management"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.notifications}
                          disabled
                          icon={<CheckCircleIcon color="success" />}
                        />
                      }
                      label="Notifications"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.timeTracking}
                          disabled
                          icon={<CheckCircleIcon color="success" />}
                        />
                      }
                      label="Time Tracking"
                    />
                  </Box>
                </AccordionDetails>
              </Accordion>

              <Accordion>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Typography variant="subtitle1" fontWeight={500}>
                    Premium Features (Optional)
                  </Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 2 }}>
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.analytics}
                          onChange={(e) => handleCustomFeatureChange('analytics', e.target.checked)}
                        />
                      }
                      label="Analytics & Reports"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.advancedReporting}
                          onChange={(e) => handleCustomFeatureChange('advancedReporting', e.target.checked)}
                        />
                      }
                      label="Advanced Reporting"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.customBranding}
                          onChange={(e) => handleCustomFeatureChange('customBranding', e.target.checked)}
                        />
                      }
                      label="Custom Branding"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.apiAccess}
                          onChange={(e) => handleCustomFeatureChange('apiAccess', e.target.checked)}
                        />
                      }
                      label="API Access"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.multiLocation}
                          onChange={(e) => handleCustomFeatureChange('multiLocation', e.target.checked)}
                        />
                      }
                      label="Multi Location"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.expenseManagement}
                          onChange={(e) => handleCustomFeatureChange('expenseManagement', e.target.checked)}
                        />
                      }
                      label="Expense Management"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.performanceReviews}
                          onChange={(e) => handleCustomFeatureChange('performanceReviews', e.target.checked)}
                        />
                      }
                      label="Performance Reviews"
                    />
                    <FormControlLabel
                      control={
                        <Checkbox
                          checked={formData.customFeatures.trainingManagement}
                          onChange={(e) => handleCustomFeatureChange('trainingManagement', e.target.checked)}
                        />
                      }
                      label="Training Management"
                    />
                  </Box>
                </AccordionDetails>
              </Accordion>

              <Accordion>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Typography variant="subtitle1" fontWeight={500}>
                    Usage Limits
                  </Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 2 }}>
                    <TextField
                      fullWidth
                      label="Max Employees"
                      type="number"
                      value={formData.customLimits.maxEmployees}
                      onChange={(e) => handleCustomLimitChange('maxEmployees', parseInt(e.target.value) || 10)}
                      inputProps={{ min: 1, max: 1000 }}
                    />
                    <TextField
                      fullWidth
                      label="Max Storage (GB)"
                      type="number"
                      value={formData.customLimits.maxStorageGB}
                      onChange={(e) => handleCustomLimitChange('maxStorageGB', parseInt(e.target.value) || 5)}
                      inputProps={{ min: 1, max: 1000 }}
                    />
                    <TextField
                      fullWidth
                      label="Max API Calls/Day"
                      type="number"
                      value={formData.customLimits.maxApiCallsPerDay}
                      onChange={(e) => handleCustomLimitChange('maxApiCallsPerDay', parseInt(e.target.value) || 1000)}
                      inputProps={{ min: 0, max: 100000 }}
                    />
                    <TextField
                      fullWidth
                      label="Max Locations"
                      type="number"
                      value={formData.customLimits.maxLocations}
                      onChange={(e) => handleCustomLimitChange('maxLocations', parseInt(e.target.value) || 1)}
                      inputProps={{ min: 1, max: 100 }}
                    />
                  </Box>
                </AccordionDetails>
              </Accordion>

              {/* Feature Summary */}
              <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Selected Features:
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {Object.entries(formData.customFeatures).map(([key, value]) => {
                    if (value) {
                      return (
                        <Chip
                          key={key}
                          label={key.charAt(0).toUpperCase() + key.slice(1).replace(/([A-Z])/g, ' $1')}
                          size="small"
                          color="primary"
                          variant="outlined"
                          icon={<CheckCircleIcon />}
                        />
                      );
                    }
                    return null;
                  })}
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Box>
      )}

      <Box sx={{ mt: 3, display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
        <Button onClick={onCancel} disabled={loading}>
          Cancel
        </Button>
        <Button
          type="submit"
          variant="contained"
          disabled={loading || loadingPlans}
          startIcon={loading ? <CircularProgress size={20} /> : null}
        >
          {loading ? 'Creating...' : 'Create Company'}
        </Button>
      </Box>
    </Box>
  );
};

export default CreateCompanyForm; 