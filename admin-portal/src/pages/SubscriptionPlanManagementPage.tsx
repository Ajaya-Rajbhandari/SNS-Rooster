import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Button,
  TextField,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Tooltip,
  Switch,
  FormControlLabel
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridActionsCellItem, GridToolbar } from '@mui/x-data-grid';
import apiService from '../services/apiService';

interface SubscriptionPlan {
  _id: string;
  name: string;
  description?: string;
  price: {
    monthly: number;
    yearly: number;
  };
  features: {
    maxEmployees: number;
    maxDepartments: number;
    // Core HR Features
    attendance: boolean;
    payroll: boolean;
    leaveManagement: boolean;
    timesheet: boolean;
    notifications: boolean;
    timeTracking: boolean;
    // Analytics & Reporting
    analytics: boolean;
    advancedReporting: boolean;
    dataExport: boolean;
    // Enterprise Features
    customBranding: boolean;
    apiAccess: boolean;
    prioritySupport: boolean;
    multiLocationSupport: boolean;
    expenseManagement: boolean;
    performanceReviews: boolean;
    trainingManagement: boolean;
    documentManagement: boolean;
    // Employee Features
    events: boolean;
    profile: boolean;
    companyInfo: boolean;
    // Admin Features
    employeeManagement: boolean;
    timesheetApprovals: boolean;
    attendanceManagement: boolean;
    breakManagement: boolean;
    breakTypes: boolean;
    userManagement: boolean;
    settings: boolean;
    companySettings: boolean;
    featureManagement: boolean;
    helpSupport: boolean;
    // Location Management Features
    locationManagement: boolean;
    locationSettings: boolean;
    locationNotifications: boolean;
    locationGeofencing: boolean;
    locationCapacity: boolean;
    locationBasedAttendance: boolean;
    // System Settings
    dataRetention: number;
    backupFrequency: 'daily' | 'weekly' | 'monthly';
  };
  isActive: boolean;
  isDefault: boolean;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
}

const SubscriptionPlanManagementPage: React.FC = () => {
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);
  const [creatingPlan, setCreatingPlan] = useState(false);
  const [editingPlan, setEditingPlan] = useState(false);

  // Form state
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    monthlyPrice: '',
    yearlyPrice: '',
    maxEmployees: '',
    maxDepartments: '',
    // Core HR Features
    attendance: true,
    payroll: false,
    leaveManagement: true,
    timesheet: true,
    notifications: true,
    timeTracking: true,
    // Analytics & Reporting
    analytics: false,
    advancedReporting: false,
    dataExport: false,
    // Enterprise Features
    customBranding: false,
    apiAccess: false,
    prioritySupport: false,
    multiLocationSupport: false,
    expenseManagement: false,
    performanceReviews: false,
    trainingManagement: false,
    documentManagement: false,
    // Employee Features
    events: false,
    profile: true,
    companyInfo: true,
    // Admin Features
    employeeManagement: true,
    timesheetApprovals: true,
    attendanceManagement: true,
    breakManagement: true,
    breakTypes: true,
    userManagement: true,
    settings: true,
    companySettings: true,
    featureManagement: false,
    helpSupport: true,
    // Location Management Features
    locationManagement: false,
    locationSettings: false,
    locationNotifications: false,
    locationGeofencing: false,
    locationCapacity: false,
    locationBasedAttendance: false,
    // System Settings
    dataRetention: '365',
    backupFrequency: 'weekly' as 'daily' | 'weekly' | 'monthly',
    isActive: true,
    isDefault: false,
    sortOrder: '0'
  });

  const fetchPlans = async () => {
    try {
      setLoading(true);
      const response = await apiService.get<any>('/api/super-admin/subscription-plans');
      console.log('Subscription plans response:', response);
      
      // Log each plan's structure for debugging
      const plansData = response.plans || [];
      plansData.forEach((plan: any, index: number) => {
        console.log(`Plan ${index + 1} (${plan.name}):`, {
          id: plan._id,
          name: plan.name,
          price: plan.price,
          features: plan.features,
          isActive: plan.isActive,
          isDefault: plan.isDefault
        });
      });
      
      setPlans(plansData);
    } catch (err) {
      console.error('Error fetching subscription plans:', err);
      setError('Failed to load subscription plans');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPlans();
  }, []);

  // Handle feature dependencies
  const handleFeatureChange = (featureName: string, value: boolean) => {
    let newFormData = { ...formData, [featureName]: value };

    // Location Management Master Toggle Logic
    if (featureName === 'locationManagement') {
      if (!value) {
        // If Location Management is disabled, disable all location sub-features
        newFormData = {
          ...newFormData,
          locationSettings: false,
          locationNotifications: false,
          locationGeofencing: false,
          locationCapacity: false,
          locationBasedAttendance: false,
          multiLocationSupport: false
        };
      }
    }

    // Analytics Dependencies Logic
    if (featureName === 'analytics' && !value) {
      // If Analytics is disabled, disable Advanced Reporting
      newFormData = {
        ...newFormData,
        advancedReporting: false
      };
    }

    // Location sub-features require Location Management
    const locationSubFeatures = ['locationSettings', 'locationNotifications', 'locationGeofencing', 'locationCapacity', 'locationBasedAttendance'];
    if (locationSubFeatures.includes(featureName) && value && !formData.locationManagement) {
      // If enabling a location sub-feature, enable Location Management
      newFormData = {
        ...newFormData,
        locationManagement: true
      };
    }

    // Multi-Location Support requires Location Management
    if (featureName === 'multiLocationSupport' && value && !formData.locationManagement) {
      newFormData = {
        ...newFormData,
        locationManagement: true
      };
    }

    // Advanced Reporting requires Analytics
    if (featureName === 'advancedReporting' && value && !formData.analytics) {
      newFormData = {
        ...newFormData,
        analytics: true
      };
    }

    setFormData(newFormData);
  };

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      monthlyPrice: '',
      yearlyPrice: '',
      maxEmployees: '',
      maxDepartments: '',
          // Core HR Features
      attendance: true,
      payroll: false,
      leaveManagement: true,
      timesheet: true,
      notifications: true,
      timeTracking: true,
      // Analytics & Reporting
      analytics: false,
      advancedReporting: false,
      dataExport: false,
      // Enterprise Features
      customBranding: false,
      apiAccess: false,
      prioritySupport: false,
      multiLocationSupport: false,
      expenseManagement: false,
      performanceReviews: false,
      trainingManagement: false,
      documentManagement: false,
      // Employee Features
      events: false,
      profile: true,
      companyInfo: true,
      // Admin Features
      employeeManagement: true,
      timesheetApprovals: true,
      attendanceManagement: true,
      breakManagement: true,
      breakTypes: true,
      userManagement: true,
      settings: true,
      companySettings: true,
      featureManagement: false,
      helpSupport: true,
      // Location Management Features
      locationManagement: false,
      locationSettings: false,
      locationNotifications: false,
      locationGeofencing: false,
      locationCapacity: false,
      locationBasedAttendance: false,
      // System Settings
      dataRetention: '365',
      backupFrequency: 'weekly',
      isActive: true,
      isDefault: false,
      sortOrder: '0'
    });
  };

  const handleCreatePlan = () => {
    resetForm();
    setCreateDialogOpen(true);
  };

  const handleEditPlan = (plan: SubscriptionPlan) => {
    setSelectedPlan(plan);
    setFormData({
      name: plan.name,
      description: plan.description || '',
      monthlyPrice: plan.price.monthly.toString(),
      yearlyPrice: plan.price.yearly.toString(),
      maxEmployees: plan.features.maxEmployees.toString(),
      maxDepartments: plan.features.maxDepartments.toString(),
      // Core HR Features
      attendance: plan.features.attendance ?? true,
      payroll: plan.features.payroll ?? false,
      leaveManagement: plan.features.leaveManagement ?? true,
      timesheet: plan.features.timesheet ?? true,
      notifications: plan.features.notifications ?? true,
      timeTracking: plan.features.timeTracking ?? true,
      // Analytics & Reporting
      analytics: plan.features.analytics,
      advancedReporting: plan.features.advancedReporting,
      dataExport: plan.features.dataExport ?? false,
      // Enterprise Features
      customBranding: plan.features.customBranding,
      apiAccess: plan.features.apiAccess,
      prioritySupport: plan.features.prioritySupport,
      multiLocationSupport: plan.features.multiLocationSupport ?? false,
      expenseManagement: plan.features.expenseManagement ?? false,
      performanceReviews: plan.features.performanceReviews ?? false,
      trainingManagement: plan.features.trainingManagement ?? false,
      documentManagement: plan.features.documentManagement ?? false,
      // Employee Features
      events: plan.features.events ?? false,
      profile: plan.features.profile ?? true,
      companyInfo: plan.features.companyInfo ?? true,
      // Admin Features
      employeeManagement: plan.features.employeeManagement ?? true,
      timesheetApprovals: plan.features.timesheetApprovals ?? true,
      attendanceManagement: plan.features.attendanceManagement ?? true,
      breakManagement: plan.features.breakManagement ?? true,
      breakTypes: plan.features.breakTypes ?? true,
      userManagement: plan.features.userManagement ?? true,
      settings: plan.features.settings ?? true,
      companySettings: plan.features.companySettings ?? true,
      featureManagement: plan.features.featureManagement ?? false,
      helpSupport: plan.features.helpSupport ?? true,
      // Location Management Features
      locationManagement: plan.features.locationManagement ?? false,
      locationSettings: plan.features.locationSettings ?? false,
      locationNotifications: plan.features.locationNotifications ?? false,
      locationGeofencing: plan.features.locationGeofencing ?? false,
      locationCapacity: plan.features.locationCapacity ?? false,
      locationBasedAttendance: plan.features.locationBasedAttendance ?? false,
      // System Settings
      dataRetention: plan.features.dataRetention.toString(),
      backupFrequency: plan.features.backupFrequency,
      isActive: plan.isActive,
      isDefault: plan.isDefault,
      sortOrder: plan.sortOrder.toString()
    });
    setEditDialogOpen(true);
  };

  const handleViewPlan = (plan: SubscriptionPlan) => {
    setSelectedPlan(plan);
    setViewDialogOpen(true);
  };

  const handleDeletePlan = async (plan: SubscriptionPlan) => {
    if (window.confirm(`Are you sure you want to delete the "${plan.name}" plan?`)) {
      try {
        await apiService.delete(`/api/super-admin/subscription-plans/${plan._id}`);
        await fetchPlans();
        setError('');
      } catch (err: any) {
        console.error('Error deleting plan:', err);
        setError(err?.response?.data?.message || 'Failed to delete plan');
      }
    }
  };

  const handleSubmitCreatePlan = async () => {
    try {
      setCreatingPlan(true);
      const planData = {
        name: formData.name,
        description: formData.description,
        price: {
          monthly: parseFloat(formData.monthlyPrice),
          yearly: parseFloat(formData.yearlyPrice)
        },
        features: {
          maxEmployees: parseInt(formData.maxEmployees),
          maxDepartments: parseInt(formData.maxDepartments),
          // Core HR Features
          attendance: formData.attendance,
          payroll: formData.payroll,
          leaveManagement: formData.leaveManagement,
          timesheet: formData.timesheet,
          notifications: formData.notifications,
          timeTracking: formData.timeTracking,
          // Analytics & Reporting
          analytics: formData.analytics,
          advancedReporting: formData.advancedReporting,
          dataExport: formData.dataExport,
          // Enterprise Features
          customBranding: formData.customBranding,
          apiAccess: formData.apiAccess,
          prioritySupport: formData.prioritySupport,
          multiLocationSupport: formData.multiLocationSupport,
          expenseManagement: formData.expenseManagement,
          performanceReviews: formData.performanceReviews,
          trainingManagement: formData.trainingManagement,
          documentManagement: formData.documentManagement,
          // Employee Features
          events: formData.events,
          profile: formData.profile,
          companyInfo: formData.companyInfo,
          // Admin Features
          employeeManagement: formData.employeeManagement,
          timesheetApprovals: formData.timesheetApprovals,
          attendanceManagement: formData.attendanceManagement,
          breakManagement: formData.breakManagement,
          breakTypes: formData.breakTypes,
          userManagement: formData.userManagement,
          settings: formData.settings,
          companySettings: formData.companySettings,
          featureManagement: formData.featureManagement,
          helpSupport: formData.helpSupport,
          // Location Management Features
          locationManagement: formData.locationManagement,
          locationSettings: formData.locationSettings,
          locationNotifications: formData.locationNotifications,
          locationGeofencing: formData.locationGeofencing,
          locationCapacity: formData.locationCapacity,
          locationBasedAttendance: formData.locationBasedAttendance,
          // System Settings
          dataRetention: parseInt(formData.dataRetention),
          backupFrequency: formData.backupFrequency
        },
        isActive: formData.isActive,
        isDefault: formData.isDefault,
        sortOrder: parseInt(formData.sortOrder)
      };

      await apiService.post('/api/super-admin/subscription-plans', planData);
      await fetchPlans();
      setCreateDialogOpen(false);
      resetForm();
      setError('');
    } catch (err: any) {
      console.error('Error creating plan:', err);
      setError(err.response?.data?.message || 'Failed to create plan');
    } finally {
      setCreatingPlan(false);
    }
  };

  const handleSubmitEditPlan = async () => {
    if (!selectedPlan) return;
    
    try {
      setEditingPlan(true);
      const planData = {
        name: formData.name,
        description: formData.description,
        price: {
          monthly: parseFloat(formData.monthlyPrice),
          yearly: parseFloat(formData.yearlyPrice)
        },
        features: {
          maxEmployees: parseInt(formData.maxEmployees),
          maxDepartments: parseInt(formData.maxDepartments),
          // Core HR Features
          attendance: formData.attendance,
          payroll: formData.payroll,
          leaveManagement: formData.leaveManagement,
          timesheet: formData.timesheet,
          notifications: formData.notifications,
          timeTracking: formData.timeTracking,
          // Analytics & Reporting
          analytics: formData.analytics,
          advancedReporting: formData.advancedReporting,
          dataExport: formData.dataExport,
          // Enterprise Features
          customBranding: formData.customBranding,
          apiAccess: formData.apiAccess,
          prioritySupport: formData.prioritySupport,
          multiLocationSupport: formData.multiLocationSupport,
          expenseManagement: formData.expenseManagement,
          performanceReviews: formData.performanceReviews,
          trainingManagement: formData.trainingManagement,
          documentManagement: formData.documentManagement,
          // Employee Features
          events: formData.events,
          profile: formData.profile,
          companyInfo: formData.companyInfo,
          // Admin Features
          employeeManagement: formData.employeeManagement,
          timesheetApprovals: formData.timesheetApprovals,
          attendanceManagement: formData.attendanceManagement,
          breakManagement: formData.breakManagement,
          breakTypes: formData.breakTypes,
          userManagement: formData.userManagement,
          settings: formData.settings,
          companySettings: formData.companySettings,
          featureManagement: formData.featureManagement,
          helpSupport: formData.helpSupport,
          // Location Management Features
          locationManagement: formData.locationManagement,
          locationSettings: formData.locationSettings,
          locationNotifications: formData.locationNotifications,
          locationGeofencing: formData.locationGeofencing,
          locationCapacity: formData.locationCapacity,
          locationBasedAttendance: formData.locationBasedAttendance,
          // System Settings
          dataRetention: parseInt(formData.dataRetention),
          backupFrequency: formData.backupFrequency
        },
        isActive: formData.isActive,
        isDefault: formData.isDefault,
        sortOrder: parseInt(formData.sortOrder)
      };

      await apiService.put(`/api/super-admin/subscription-plans/${selectedPlan._id}`, planData);
      await fetchPlans();
      setEditDialogOpen(false);
      setSelectedPlan(null);
      resetForm();
      setError('');
    } catch (err: any) {
      console.error('Error updating plan:', err);
      setError(err.response?.data?.message || 'Failed to update plan');
    } finally {
      setEditingPlan(false);
    }
  };

  const columns: GridColDef[] = [
    {
      field: 'name',
      headerName: 'Plan Name',
      flex: 1,
      minWidth: 150,
    },
    {
      field: 'description',
      headerName: 'Description',
      flex: 1,
      minWidth: 300,
      renderCell: (params) => (
        <Typography variant="body2" color="textSecondary" component="div" sx={{ 
          wordBreak: 'break-word',
          lineHeight: 1.4,
          maxWidth: '100%'
        }}>
          {params.value || 'No description'}
        </Typography>
      ),
    },
    {
      field: 'monthlyPrice',
      headerName: 'Monthly Price',
      flex: 1,
      minWidth: 120,
      renderCell: (params: any) => {
        console.log('Monthly Price params:', params);
        if (!params || !params.row) return 'N/A';
        const price = params.row.price;
        console.log('Price object:', price);
        return price?.monthly ? `$${price.monthly}` : 'N/A';
      },
    },
    {
      field: 'yearlyPrice',
      headerName: 'Yearly Price',
      flex: 1,
      minWidth: 120,
      renderCell: (params: any) => {
        console.log('Yearly Price params:', params);
        if (!params || !params.row) return 'N/A';
        const price = params.row.price;
        console.log('Price object:', price);
        return price?.yearly ? `$${price.yearly}` : 'N/A';
      },
    },
    {
      field: 'maxEmployees',
      headerName: 'Max Employees',
      flex: 1,
      minWidth: 120,
      renderCell: (params: any) => {
        console.log('Max Employees params:', params);
        if (!params || !params.row) return 'N/A';
        const features = params.row.features;
        console.log('Features object:', features);
        return features?.maxEmployees || 'N/A';
      },
    },
    {
      field: 'keyFeatures',
      headerName: 'Key Features',
      flex: 1,
      minWidth: 200,
      renderCell: (params) => {
        if (!params || !params.row) return 'No features';
        const features = params.row.features;
        if (!features) return 'No features';
        
        const activeFeatures = [];
        if (features.analytics) activeFeatures.push('Analytics');
        if (features.advancedReporting) activeFeatures.push('Reports');
        if (features.customBranding) activeFeatures.push('Branding');
        if (features.apiAccess) activeFeatures.push('API');
        if (features.prioritySupport) activeFeatures.push('Support');
        
        if (activeFeatures.length === 0) return 'Basic';
        if (activeFeatures.length <= 2) return activeFeatures.join(', ');
        return `${activeFeatures.slice(0, 2).join(', ')} +${activeFeatures.length - 2}`;
      },
    },
    {
      field: 'isActive',
      headerName: 'Status',
      flex: 1,
      minWidth: 100,
      renderCell: (params) => (
        <Chip
          label={params.value ? 'Active' : 'Inactive'}
          color={params.value ? 'success' : 'default'}
          size="small"
        />
      ),
    },
    {
      field: 'isDefault',
      headerName: 'Default',
      flex: 1,
      minWidth: 100,
      renderCell: (params) => (
        params.value ? (
          <Chip
            label="Default"
            color="primary"
            size="small"
            icon={<CheckCircleIcon />}
          />
        ) : null
      ),
    },
    {
      field: 'actions',
      type: 'actions',
      headerName: 'Actions',
      flex: 1,
      minWidth: 150,
      getActions: (params) => [
        <GridActionsCellItem
          icon={<ViewIcon />}
          label="View"
          onClick={() => handleViewPlan(params.row)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit"
          onClick={() => handleEditPlan(params.row)}
        />,
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete"
          onClick={() => handleDeletePlan(params.row)}
          disabled={params.row.isDefault}
        />,
      ],
    },
  ];

  const renderPlanDialog = (isView: boolean = false) => {
    const plan = selectedPlan;
    if (!plan && isView) return null;

    return (
      <Dialog open={isView ? viewDialogOpen : (editDialogOpen || createDialogOpen)} maxWidth="md" fullWidth>
        <DialogTitle>
          {isView ? `View Plan: ${plan?.name}` : (editDialogOpen ? 'Edit Plan' : 'Create New Plan')}
        </DialogTitle>
        <DialogContent>
          {isView ? (
            <Box sx={{ mt: 2 }}>
              <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 3 }}>
                <Box>
                  <Typography variant="h6" gutterBottom>Basic Information</Typography>
                  <Typography><strong>Name:</strong> {plan?.name}</Typography>
                  <Typography><strong>Description:</strong> {plan?.description || 'No description'}</Typography>
                  <Typography><strong>Status:</strong> {plan?.isActive ? 'Active' : 'Inactive'}</Typography>
                  <Typography><strong>Default Plan:</strong> {plan?.isDefault ? 'Yes' : 'No'}</Typography>
                  <Typography><strong>Sort Order:</strong> {plan?.sortOrder}</Typography>
                </Box>
                <Box>
                  <Typography variant="h6" gutterBottom>Pricing</Typography>
                  <Typography><strong>Monthly:</strong> ${plan?.price?.monthly || 'N/A'}</Typography>
                  <Typography><strong>Yearly:</strong> ${plan?.price?.yearly || 'N/A'}</Typography>
                </Box>
                <Box>
                  <Typography variant="h6" gutterBottom>Limits</Typography>
                  <Typography><strong>Max Employees:</strong> {plan?.features?.maxEmployees || 'N/A'}</Typography>
                  <Typography><strong>Max Departments:</strong> {plan?.features?.maxDepartments || 'N/A'}</Typography>
                  <Typography><strong>Data Retention:</strong> {plan?.features?.dataRetention || 'N/A'} days</Typography>
                  <Typography><strong>Backup Frequency:</strong> {plan?.features?.backupFrequency || 'N/A'}</Typography>
                </Box>
                <Box sx={{ gridColumn: '1 / -1' }}>
                  <Typography variant="h6" gutterBottom>Features</Typography>
                  <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom>Core HR Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip label="Attendance" color={plan?.features?.attendance ? 'success' : 'default'} size="small" />
                        <Chip label="Payroll" color={plan?.features?.payroll ? 'success' : 'default'} size="small" />
                        <Chip label="Leave Management" color={plan?.features?.leaveManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Timesheet" color={plan?.features?.timesheet ? 'success' : 'default'} size="small" />
                        <Chip label="Notifications" color={plan?.features?.notifications ? 'success' : 'default'} size="small" />
                        <Chip label="Time Tracking" color={plan?.features?.timeTracking ? 'success' : 'default'} size="small" />
                        <Chip label="Employee Management" color={plan?.features?.employeeManagement ? 'success' : 'default'} size="small" />
                        <Chip label="User Management" color={plan?.features?.userManagement ? 'success' : 'default'} size="small" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom>Analytics & Reporting</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip label="Analytics" color={plan?.features?.analytics ? 'success' : 'default'} size="small" />
                        <Chip label="Advanced Reporting" color={plan?.features?.advancedReporting ? 'success' : 'default'} size="small" />
                        <Chip label="Data Export" color={plan?.features?.dataExport ? 'success' : 'default'} size="small" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom>Enterprise Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip label="Custom Branding" color={plan?.features?.customBranding ? 'success' : 'default'} size="small" />
                        <Chip label="API Access" color={plan?.features?.apiAccess ? 'success' : 'default'} size="small" />
                        <Chip label="Priority Support" color={plan?.features?.prioritySupport ? 'success' : 'default'} size="small" />
                        <Chip label="Multi-Location Support" color={plan?.features?.multiLocationSupport ? 'success' : 'default'} size="small" />
                        <Chip label="Expense Management" color={plan?.features?.expenseManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Performance Reviews" color={plan?.features?.performanceReviews ? 'success' : 'default'} size="small" />
                        <Chip label="Training Management" color={plan?.features?.trainingManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Document Management" color={plan?.features?.documentManagement ? 'success' : 'default'} size="small" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom>Employee Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip label="Events" color={plan?.features?.events ? 'success' : 'default'} size="small" />
                        <Chip label="Profile Management" color={plan?.features?.profile ? 'success' : 'default'} size="small" />
                        <Chip label="Company Information" color={plan?.features?.companyInfo ? 'success' : 'default'} size="small" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom>Admin Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip label="Timesheet Approvals" color={plan?.features?.timesheetApprovals ? 'success' : 'default'} size="small" />
                        <Chip label="Attendance Management" color={plan?.features?.attendanceManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Break Management" color={plan?.features?.breakManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Break Types" color={plan?.features?.breakTypes ? 'success' : 'default'} size="small" />
                        <Chip label="Settings" color={plan?.features?.settings ? 'success' : 'default'} size="small" />
                        <Chip label="Company Settings" color={plan?.features?.companySettings ? 'success' : 'default'} size="small" />
                        <Chip label="Feature Management" color={plan?.features?.featureManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Help & Support" color={plan?.features?.helpSupport ? 'success' : 'default'} size="small" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom>Location Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                        <Chip label="Location Management" color={plan?.features?.locationManagement ? 'success' : 'default'} size="small" />
                        <Chip label="Location Settings" color={plan?.features?.locationSettings ? 'success' : 'default'} size="small" />
                        <Chip label="Location Notifications" color={plan?.features?.locationNotifications ? 'success' : 'default'} size="small" />
                        <Chip label="Location Geofencing" color={plan?.features?.locationGeofencing ? 'success' : 'default'} size="small" />
                        <Chip label="Location Capacity" color={plan?.features?.locationCapacity ? 'success' : 'default'} size="small" />
                        <Chip label="Location-Based Attendance" color={plan?.features?.locationBasedAttendance ? 'success' : 'default'} size="small" />
                      </Box>
                    </Box>
                  </Box>
                </Box>
              </Box>
            </Box>
          ) : (
            <Box sx={{ mt: 2 }}>
              <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 3 }}>
                <Box>
                  <TextField
                    fullWidth
                    label="Plan Name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    margin="normal"
                    required
                  />
                  <TextField
                    fullWidth
                    label="Description"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    margin="normal"
                    multiline
                    rows={3}
                  />
                </Box>
                <Box>
                  <TextField
                    fullWidth
                    label="Monthly Price ($)"
                    type="number"
                    value={formData.monthlyPrice}
                    onChange={(e) => setFormData({ ...formData, monthlyPrice: e.target.value })}
                    margin="normal"
                    required
                  />
                  <TextField
                    fullWidth
                    label="Yearly Price ($)"
                    type="number"
                    value={formData.yearlyPrice}
                    onChange={(e) => setFormData({ ...formData, yearlyPrice: e.target.value })}
                    margin="normal"
                    required
                  />
                </Box>
                <Box>
                  <TextField
                    fullWidth
                    label="Max Employees"
                    type="number"
                    value={formData.maxEmployees}
                    onChange={(e) => setFormData({ ...formData, maxEmployees: e.target.value })}
                    margin="normal"
                    required
                  />
                  <TextField
                    fullWidth
                    label="Max Departments"
                    type="number"
                    value={formData.maxDepartments}
                    onChange={(e) => setFormData({ ...formData, maxDepartments: e.target.value })}
                    margin="normal"
                    required
                  />
                </Box>
                <Box>
                  <TextField
                    fullWidth
                    label="Data Retention (days)"
                    type="number"
                    value={formData.dataRetention}
                    onChange={(e) => setFormData({ ...formData, dataRetention: e.target.value })}
                    margin="normal"
                    required
                  />
                  <FormControl fullWidth margin="normal">
                    <InputLabel>Backup Frequency</InputLabel>
                    <Select
                      value={formData.backupFrequency}
                      onChange={(e) => setFormData({ ...formData, backupFrequency: e.target.value as any })}
                      label="Backup Frequency"
                    >
                      <MenuItem value="daily">Daily</MenuItem>
                      <MenuItem value="weekly">Weekly</MenuItem>
                      <MenuItem value="monthly">Monthly</MenuItem>
                    </Select>
                  </FormControl>
                </Box>
                <Box sx={{ gridColumn: '1 / -1' }}>
                  <Typography variant="h6" gutterBottom>Features</Typography>
                  <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 3 }}>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', color: 'primary.main' }}>Core HR Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                        <FormControlLabel control={<Switch checked={formData.attendance} onChange={(e) => setFormData({ ...formData, attendance: e.target.checked })} />} label="Attendance" />
                        <FormControlLabel control={<Switch checked={formData.payroll} onChange={(e) => setFormData({ ...formData, payroll: e.target.checked })} />} label="Payroll" />
                        <FormControlLabel control={<Switch checked={formData.leaveManagement} onChange={(e) => setFormData({ ...formData, leaveManagement: e.target.checked })} />} label="Leave Management" />
                        <FormControlLabel control={<Switch checked={formData.timesheet} onChange={(e) => setFormData({ ...formData, timesheet: e.target.checked })} />} label="Timesheet" />
                        <FormControlLabel control={<Switch checked={formData.notifications} onChange={(e) => setFormData({ ...formData, notifications: e.target.checked })} />} label="Notifications" />
                        <FormControlLabel control={<Switch checked={formData.timeTracking} onChange={(e) => setFormData({ ...formData, timeTracking: e.target.checked })} />} label="Time Tracking" />
                        <FormControlLabel control={<Switch checked={formData.employeeManagement} onChange={(e) => setFormData({ ...formData, employeeManagement: e.target.checked })} />} label="Employee Management" />
                        <FormControlLabel control={<Switch checked={formData.userManagement} onChange={(e) => setFormData({ ...formData, userManagement: e.target.checked })} />} label="User Management" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', color: 'primary.main' }}>Analytics & Reporting</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                        <FormControlLabel control={<Switch checked={formData.analytics} onChange={(e) => handleFeatureChange('analytics', e.target.checked)} />} label="Analytics" />
                        <FormControlLabel 
                          control={<Switch checked={formData.advancedReporting} disabled={!formData.analytics} onChange={(e) => handleFeatureChange('advancedReporting', e.target.checked)} />} 
                          label={
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Typography>Advanced Reporting</Typography>
                              {!formData.analytics && (
                                <Tooltip title="Requires Analytics to be enabled">
                                  <WarningIcon color="warning" fontSize="small" />
                                </Tooltip>
                              )}
                            </Box>
                          } 
                        />
                        <FormControlLabel 
                          control={<Switch checked={formData.dataExport} disabled={!formData.analytics} onChange={(e) => handleFeatureChange('dataExport', e.target.checked)} />} 
                          label={
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Typography>Data Export</Typography>
                              {!formData.analytics && (
                                <Tooltip title="Requires Analytics to be enabled">
                                  <WarningIcon color="warning" fontSize="small" />
                                </Tooltip>
                              )}
                            </Box>
                          } 
                        />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', color: 'primary.main' }}>Enterprise Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                        <FormControlLabel control={<Switch checked={formData.customBranding} onChange={(e) => setFormData({ ...formData, customBranding: e.target.checked })} />} label="Custom Branding" />
                        <FormControlLabel control={<Switch checked={formData.apiAccess} onChange={(e) => setFormData({ ...formData, apiAccess: e.target.checked })} />} label="API Access" />
                        <FormControlLabel control={<Switch checked={formData.prioritySupport} onChange={(e) => setFormData({ ...formData, prioritySupport: e.target.checked })} />} label="Priority Support" />
                        <FormControlLabel 
                          control={<Switch checked={formData.multiLocationSupport} onChange={(e) => handleFeatureChange('multiLocationSupport', e.target.checked)} />} 
                          label={
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Typography>Multi-Location Support</Typography>
                              {!formData.locationManagement && (
                                <Tooltip title="Will auto-enable Location Management">
                                  <WarningIcon color="warning" fontSize="small" />
                                </Tooltip>
                              )}
                            </Box>
                          } 
                        />
                        <FormControlLabel control={<Switch checked={formData.expenseManagement} onChange={(e) => setFormData({ ...formData, expenseManagement: e.target.checked })} />} label="Expense Management" />
                        <FormControlLabel control={<Switch checked={formData.performanceReviews} onChange={(e) => setFormData({ ...formData, performanceReviews: e.target.checked })} />} label="Performance Reviews" />
                        <FormControlLabel control={<Switch checked={formData.trainingManagement} onChange={(e) => setFormData({ ...formData, trainingManagement: e.target.checked })} />} label="Training Management" />
                        <FormControlLabel control={<Switch checked={formData.documentManagement} onChange={(e) => setFormData({ ...formData, documentManagement: e.target.checked })} />} label="Document Management" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', color: 'primary.main' }}>Employee Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                        <FormControlLabel control={<Switch checked={formData.events} onChange={(e) => setFormData({ ...formData, events: e.target.checked })} />} label="Events" />
                        <FormControlLabel control={<Switch checked={formData.profile} onChange={(e) => setFormData({ ...formData, profile: e.target.checked })} />} label="Profile Management" />
                        <FormControlLabel control={<Switch checked={formData.companyInfo} onChange={(e) => setFormData({ ...formData, companyInfo: e.target.checked })} />} label="Company Information" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', color: 'primary.main' }}>Admin Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                        <FormControlLabel control={<Switch checked={formData.timesheetApprovals} onChange={(e) => setFormData({ ...formData, timesheetApprovals: e.target.checked })} />} label="Timesheet Approvals" />
                        <FormControlLabel control={<Switch checked={formData.attendanceManagement} onChange={(e) => setFormData({ ...formData, attendanceManagement: e.target.checked })} />} label="Attendance Management" />
                        <FormControlLabel control={<Switch checked={formData.breakManagement} onChange={(e) => setFormData({ ...formData, breakManagement: e.target.checked })} />} label="Break Management" />
                        <FormControlLabel control={<Switch checked={formData.breakTypes} onChange={(e) => setFormData({ ...formData, breakTypes: e.target.checked })} />} label="Break Types" />
                        <FormControlLabel control={<Switch checked={formData.settings} onChange={(e) => setFormData({ ...formData, settings: e.target.checked })} />} label="Settings" />
                        <FormControlLabel control={<Switch checked={formData.companySettings} onChange={(e) => setFormData({ ...formData, companySettings: e.target.checked })} />} label="Company Settings" />
                        <FormControlLabel control={<Switch checked={formData.featureManagement} onChange={(e) => setFormData({ ...formData, featureManagement: e.target.checked })} />} label="Feature Management" />
                        <FormControlLabel control={<Switch checked={formData.helpSupport} onChange={(e) => setFormData({ ...formData, helpSupport: e.target.checked })} />} label="Help & Support" />
                      </Box>
                    </Box>
                    <Box>
                      <Typography variant="subtitle2" gutterBottom sx={{ fontWeight: 'bold', color: 'primary.main' }}>Location Features</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
                        <FormControlLabel 
                          control={<Switch checked={formData.locationManagement} onChange={(e) => handleFeatureChange('locationManagement', e.target.checked)} />} 
                          label={
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                              <Typography>Location Management</Typography>
                              <Tooltip title="Master toggle for all location features">
                                <WarningIcon color="warning" fontSize="small" />
                              </Tooltip>
                            </Box>
                          } 
                        />
                        <FormControlLabel 
                          control={<Switch checked={formData.locationSettings} disabled={!formData.locationManagement} onChange={(e) => handleFeatureChange('locationSettings', e.target.checked)} />} 
                          label="Location Settings" 
                        />
                        <FormControlLabel 
                          control={<Switch checked={formData.locationNotifications} disabled={!formData.locationManagement} onChange={(e) => handleFeatureChange('locationNotifications', e.target.checked)} />} 
                          label="Location Notifications" 
                        />
                        <FormControlLabel 
                          control={<Switch checked={formData.locationGeofencing} disabled={!formData.locationManagement} onChange={(e) => handleFeatureChange('locationGeofencing', e.target.checked)} />} 
                          label="Location Geofencing" 
                        />
                        <FormControlLabel 
                          control={<Switch checked={formData.locationCapacity} disabled={!formData.locationManagement} onChange={(e) => handleFeatureChange('locationCapacity', e.target.checked)} />} 
                          label="Location Capacity" 
                        />
                        <FormControlLabel 
                          control={<Switch checked={formData.locationBasedAttendance} disabled={!formData.locationManagement} onChange={(e) => handleFeatureChange('locationBasedAttendance', e.target.checked)} />} 
                          label="Location-Based Attendance" 
                        />
                      </Box>
                    </Box>
                  </Box>
                </Box>
                <Box>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.isActive}
                        onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                      />
                    }
                    label="Active"
                  />
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.isDefault}
                        onChange={(e) => setFormData({ ...formData, isDefault: e.target.checked })}
                      />
                    }
                    label="Default Plan"
                  />
                </Box>
                <Box>
                  <TextField
                    fullWidth
                    label="Sort Order"
                    type="number"
                    value={formData.sortOrder}
                    onChange={(e) => setFormData({ ...formData, sortOrder: e.target.value })}
                    margin="normal"
                    helperText="Lower numbers appear first"
                  />
                </Box>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            if (isView) {
              setViewDialogOpen(false);
            } else {
              setCreateDialogOpen(false);
              setEditDialogOpen(false);
              setSelectedPlan(null);
              resetForm();
            }
          }}>
            {isView ? 'Close' : 'Cancel'}
          </Button>
          {!isView && (
            <Button
              onClick={editDialogOpen ? handleSubmitEditPlan : handleSubmitCreatePlan}
              variant="contained"
              disabled={creatingPlan || editingPlan}
            >
              {creatingPlan || editingPlan ? (
                <CircularProgress size={20} />
              ) : (
                editDialogOpen ? 'Update Plan' : 'Create Plan'
              )}
            </Button>
          )}
        </DialogActions>
      </Dialog>
    );
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, height: '100%' }}>
      {/* Header */}
      <Paper sx={{ p: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Typography variant="h4" component="h1">
            Subscription Plan Management
          </Typography>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            size="small"
            onClick={handleCreatePlan}
          >
            Create Plan
          </Button>
        </Box>
        <Typography variant="body1" color="textSecondary">
          Manage subscription plans and their features. Companies can subscribe to these plans.
        </Typography>
      </Paper>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" onClose={() => setError('')} sx={{ mb: 1 }}>
          {error}
        </Alert>
      )}

      {/* Data Grid */}
      <Box sx={{ flex: 1, minHeight: 0 }}>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
            <CircularProgress />
          </Box>
        ) : (
          <DataGrid
            rows={plans}
            columns={columns}
            initialState={{
              pagination: {
                paginationModel: { page: 0, pageSize: 10 },
              },
            }}
            pageSizeOptions={[10, 25, 50]}
            checkboxSelection
            disableRowSelectionOnClick
            getRowId={(row) => row._id}
            slots={{
              toolbar: GridToolbar,
            }}
            slotProps={{
              toolbar: {
                showQuickFilter: true,
                quickFilterProps: { debounceMs: 500 },
              },
            }}
            sx={{
              '& .MuiDataGrid-cell': {
                borderBottom: '1px solid #e0e0e0',
              },
              '& .MuiDataGrid-columnHeaders': {
                backgroundColor: '#f5f5f5',
                borderBottom: '2px solid #e0e0e0',
              },
            }}
          />
        )}
      </Box>

      {/* Dialogs */}
      {renderPlanDialog(false)} {/* Create/Edit Dialog */}
      {renderPlanDialog(true)}  {/* View Dialog */}
    </Box>
  );
};

export default SubscriptionPlanManagementPage; 