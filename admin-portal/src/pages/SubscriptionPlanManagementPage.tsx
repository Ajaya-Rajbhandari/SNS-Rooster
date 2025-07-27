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
  IconButton,
  Tooltip,
  Switch,
  FormControlLabel,
  Divider,
  Grid,
  Card,
  CardContent,
  CardActions
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Search as SearchIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  Warning as WarningIcon,
  Star as StarIcon,
  Business as BusinessIcon,
  People as PeopleIcon,
  Storage as StorageIcon,
  Speed as SpeedIcon,
  Security as SecurityIcon,
  Support as SupportIcon,
  Backup as BackupIcon
} from '@mui/icons-material';
import { DataGrid, GridColDef, GridValueGetter, GridActionsCellItem, GridToolbar } from '@mui/x-data-grid';
import apiService from '../services/apiService';
import cachedApiService from '../services/cachedApiService';

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
    analytics: boolean;
    advancedReporting: boolean;
    customBranding: boolean;
    apiAccess: boolean;
    prioritySupport: boolean;
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
    analytics: false,
    advancedReporting: false,
    customBranding: false,
    apiAccess: false,
    prioritySupport: false,
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

  const resetForm = () => {
    setFormData({
      name: '',
      description: '',
      monthlyPrice: '',
      yearlyPrice: '',
      maxEmployees: '',
      maxDepartments: '',
      analytics: false,
      advancedReporting: false,
      customBranding: false,
      apiAccess: false,
      prioritySupport: false,
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
      analytics: plan.features.analytics,
      advancedReporting: plan.features.advancedReporting,
      customBranding: plan.features.customBranding,
      apiAccess: plan.features.apiAccess,
      prioritySupport: plan.features.prioritySupport,
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
          analytics: formData.analytics,
          advancedReporting: formData.advancedReporting,
          customBranding: formData.customBranding,
          apiAccess: formData.apiAccess,
          prioritySupport: formData.prioritySupport,
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
          analytics: formData.analytics,
          advancedReporting: formData.advancedReporting,
          customBranding: formData.customBranding,
          apiAccess: formData.apiAccess,
          prioritySupport: formData.prioritySupport,
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
                <Box>
                  <Typography variant="h6" gutterBottom>Features</Typography>
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                    <Chip 
                      label="Analytics" 
                      color={plan?.features?.analytics ? 'success' : 'default'} 
                      size="small" 
                    />
                    <Chip 
                      label="Advanced Reporting" 
                      color={plan?.features?.advancedReporting ? 'success' : 'default'} 
                      size="small" 
                    />
                    <Chip 
                      label="Custom Branding" 
                      color={plan?.features?.customBranding ? 'success' : 'default'} 
                      size="small" 
                    />
                    <Chip 
                      label="API Access" 
                      color={plan?.features?.apiAccess ? 'success' : 'default'} 
                      size="small" 
                    />
                    <Chip 
                      label="Priority Support" 
                      color={plan?.features?.prioritySupport ? 'success' : 'default'} 
                      size="small" 
                    />
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
                  <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                    <Box>
                      <FormControlLabel
                        control={
                          <Switch
                            checked={formData.analytics}
                            onChange={(e) => setFormData({ ...formData, analytics: e.target.checked })}
                          />
                        }
                        label="Analytics"
                      />
                      <FormControlLabel
                        control={
                          <Switch
                            checked={formData.advancedReporting}
                            onChange={(e) => setFormData({ ...formData, advancedReporting: e.target.checked })}
                          />
                        }
                        label="Advanced Reporting"
                      />
                      <FormControlLabel
                        control={
                          <Switch
                            checked={formData.customBranding}
                            onChange={(e) => setFormData({ ...formData, customBranding: e.target.checked })}
                          />
                        }
                        label="Custom Branding"
                      />
                    </Box>
                    <Box>
                      <FormControlLabel
                        control={
                          <Switch
                            checked={formData.apiAccess}
                            onChange={(e) => setFormData({ ...formData, apiAccess: e.target.checked })}
                          />
                        }
                        label="API Access"
                      />
                      <FormControlLabel
                        control={
                          <Switch
                            checked={formData.prioritySupport}
                            onChange={(e) => setFormData({ ...formData, prioritySupport: e.target.checked })}
                          />
                        }
                        label="Priority Support"
                      />
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