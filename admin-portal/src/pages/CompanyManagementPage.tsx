import React, { useState, useEffect } from 'react';
import {
  Typography,
  Button,
  Paper,
  Box,
  TextField,
  Alert,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Divider,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Card,
  CardContent,
  Checkbox,
  FormControlLabel
} from '@mui/material';

import {
  DataGrid,
  GridColDef,
  GridActionsCellItem,
  GridToolbar,
} from '@mui/x-data-grid';
import {
  Add as AddIcon,
  Visibility as ViewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  SwapHoriz as ChangePlanIcon,
  Build as BuildIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';
import CreateCompanyForm from '../components/CreateCompanyForm';

interface Company {
  _id: string;
  name: string;
  domain: string;
  subdomain: string;
  status: 'active' | 'inactive' | 'suspended' | 'trial' | 'cancelled' | 'expired';
  subscriptionPlan?: {
    _id?: string;
    name: string;
    price?: {
      monthly?: number;
      yearly?: number;
    };
    features?: {
      maxEmployees?: number;
      maxDepartments?: number;
      analytics?: boolean;
      advancedReporting?: boolean;
      customBranding?: boolean;
      apiAccess?: boolean;
      prioritySupport?: boolean;
      dataRetention?: number;
      backupFrequency?: string;
    };
  };
  limits?: {
    maxEmployees: number;
    maxStorageGB: number;
  };
  employeeCount?: number; // Current employee count
  createdAt: string;
  updatedAt: string;
  contactPhone?: string;
  address?: {
    street: string;
    city: string;
    state: string;
    postalCode: string;
    country: string;
  };
  adminEmail?: string;
}

const CompanyManagementPage: React.FC = () => {
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [creatingCompany, setCreatingCompany] = useState(false);
  const [selectedCompany, setSelectedCompany] = useState<Company | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingCompany, setEditingCompany] = useState(false);
  const [changePlanDialogOpen, setChangePlanDialogOpen] = useState(false);
  const [availablePlans, setAvailablePlans] = useState<any[]>([]);
  const [selectedPlanId, setSelectedPlanId] = useState<string>('');
  const [bulkDeleteDialogOpen, setBulkDeleteDialogOpen] = useState(false);
  const [bulkDeleteLoading, setBulkDeleteLoading] = useState(false);
  const [changingPlan, setChangingPlan] = useState(false);
  
  // Custom plan state
  const [isCustomPlan, setIsCustomPlan] = useState(false);
  const [customFeatures, setCustomFeatures] = useState({
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
  });
  const [customLimits, setCustomLimits] = useState({
    maxEmployees: 10,
    maxStorageGB: 5,
    maxApiCallsPerDay: 1000,
    maxLocations: 1
  });

  const fetchCompanies = async () => {
    try {
      setLoading(true);
      const response = await apiService.get<any>('/api/super-admin/companies');
      const companiesData = response.companies || [];
      
      // Add computed fields for DataGrid
      const processedCompanies = companiesData.map((company: any) => {
        // Add computed fields for DataGrid
        company.planName = company.subscriptionPlan?.name || 'No Plan';
        
        // Fix employee limit display
        const maxEmployees = company.limits?.maxEmployees || company.subscriptionPlan?.features?.maxEmployees || 0;
        company.employeeLimit = maxEmployees > 0 ? `${maxEmployees} employees` : 'N/A';
        
        // Fix current employees display
        const currentEmployees = company.employeeCount || 0;
        company.currentEmployees = maxEmployees > 0 ? `${currentEmployees} / ${maxEmployees}` : `${currentEmployees}`;
        
        company.planPrice = company.subscriptionPlan?.price?.monthly ? 
          `$${company.subscriptionPlan.price.monthly}/month` : 'N/A';
        
        // Compute plan features
        if (company.subscriptionPlan?.features) {
          const features = company.subscriptionPlan.features;
          const activeFeatures = [];
          
          if (features.analytics) activeFeatures.push('Analytics');
          if (features.advancedReporting) activeFeatures.push('Reports');
          if (features.customBranding) activeFeatures.push('Branding');
          if (features.apiAccess) activeFeatures.push('API');
          if (features.prioritySupport) activeFeatures.push('Support');
          
          if (activeFeatures.length === 0) {
            company.planFeatures = 'No features';
          } else if (activeFeatures.length <= 2) {
            company.planFeatures = activeFeatures.join(', ');
          } else {
            company.planFeatures = `${activeFeatures.slice(0, 2).join(', ')} +${activeFeatures.length - 2}`;
          }
        } else {
          company.planFeatures = 'No features';
        }
        
        // Compute current employees display
        const count = company.employeeCount || 0;
        const maxEmployeesForDisplay = company.limits?.maxEmployees || company.subscriptionPlan?.features?.maxEmployees || 0;
        
        if (maxEmployeesForDisplay > 0) {
          company.currentEmployeesDisplay = `${count} / ${maxEmployeesForDisplay}`;
        } else {
          company.currentEmployeesDisplay = `${count}`;
        }
        
        return company;
      });
      
      setCompanies(processedCompanies);
    } catch (err) {
      console.error('Error fetching companies:', err);
      setError('Failed to load companies');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCompanies();
    fetchAvailablePlans();
  }, []);

  const fetchAvailablePlans = async () => {
    try {
      const response = await apiService.get<any>('/api/super-admin/subscription-plans');
      setAvailablePlans(response.plans || []);
    } catch (err) {
      console.error('Error fetching subscription plans:', err);
    }
  };

  const filteredCompanies = companies.filter(company =>
    company.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    company.domain.toLowerCase().includes(searchTerm.toLowerCase()) ||
    company.subdomain.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const columns: GridColDef[] = [
    {
      field: 'name',
      headerName: 'Company Name',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'domain',
      headerName: 'Domain',
      flex: 1,
      minWidth: 150,
    },
    {
      field: 'subdomain',
      headerName: 'Subdomain',
      flex: 1,
      minWidth: 150,
    },
    {
      field: 'status',
      headerName: 'Status',
      flex: 1,
      minWidth: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={
            params.value === 'active' ? 'success' :
            params.value === 'trial' ? 'warning' :
            params.value === 'cancelled' ? 'error' :
            params.value === 'suspended' ? 'error' :
            params.value === 'expired' ? 'error' :
            params.value === 'inactive' ? 'default' : 'default'
          }
          size="small"
        />
      ),
    },
    {
      field: 'planName',
      headerName: 'Plan',
      flex: 1,
      minWidth: 120,
    },
    {
      field: 'employeeLimit',
      headerName: 'Employee Limit',
      flex: 1,
      minWidth: 120,
    },
    {
      field: 'currentEmployeesDisplay',
      headerName: 'Current Employees',
      flex: 1,
      minWidth: 120,
      renderCell: (params) => {
        const count = params.row.employeeCount || 0;
        const maxEmployees = params.row.subscriptionPlan?.features?.maxEmployees || 0;
        
        if (count > maxEmployees * 0.9) {
          return (
            <Box sx={{ color: 'warning.main', fontWeight: 'bold' }}>
              {params.value}
            </Box>
          );
        }
        return params.value;
      },
    },
    {
      field: 'planFeatures',
      headerName: 'Plan Features',
      flex: 1,
      minWidth: 150,
    },
    {
      field: 'planPrice',
      headerName: 'Plan Price',
      flex: 1,
      minWidth: 120,
    },
    {
      field: 'createdAt',
      headerName: 'Created',
      flex: 1,
      minWidth: 120,
      renderCell: (params) => {
        const createdAt = params.value;
        if (!createdAt) return 'N/A';
        try {
          return new Date(createdAt).toLocaleDateString();
        } catch (error) {
          console.error('Error parsing createdAt:', createdAt, error);
          return 'N/A';
        }
      },
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
          onClick={() => handleViewCompany(params.row)}
        />,
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit"
          onClick={() => handleEditCompany(params.row)}
        />,
        <GridActionsCellItem
          icon={<ChangePlanIcon />}
          label="Change Plan"
          onClick={() => handleChangePlan(params.row)}
        />,
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete"
          onClick={() => handleDeleteCompany(params.row)}
        />,
      ],
    },
  ];

  const handleViewCompany = (company: Company) => {
    setSelectedCompany(company);
    setViewDialogOpen(true);
  };

  const handleEditCompany = (company: Company) => {
    setSelectedCompany(company);
    setEditDialogOpen(true);
  };

  const handleChangePlan = (company: Company) => {
    setSelectedCompany(company);
    setSelectedPlanId('');
    setIsCustomPlan(false);
    setChangePlanDialogOpen(true);
  };

  const handleDeleteCompany = async (company: Company) => {
    if (window.confirm(`Are you sure you want to PERMANENTLY delete ${company.name}? This action cannot be undone.`)) {
      try {
        console.log('Hard deleting company:', company._id);
        const response = await apiService.delete(`/api/super-admin/companies/${company._id}/hard`);
        console.log('Hard delete response:', response);
        await fetchCompanies(); // Refresh the list
        setError(''); // Clear any previous errors
        setSuccessMessage(`Company ${company.name} permanently deleted`);
      } catch (err: any) {
        console.error('Error hard deleting company:', err);
        console.error('Error response:', err.response?.data);
        setError(err.response?.data?.message || err.response?.data?.error || 'Failed to delete company');
      }
    }
  };

  const handleBulkDeleteEmptyCompanies = async () => {
    setBulkDeleteLoading(true);
    setError('');
    try {
      // Find companies with no employees (including cancelled ones)
      const emptyCompanies = companies.filter(company => 
        (company.employeeCount === 0 || company.employeeCount === undefined) && 
        company.status !== 'expired'
      );

      if (emptyCompanies.length === 0) {
        setError('No companies found with zero employees');
        return;
      }

      // Hard delete each empty company
      const deletePromises = emptyCompanies.map(company =>
        apiService.delete(`/api/super-admin/companies/${company._id}/hard`)
      );

      await Promise.all(deletePromises);
      
      setSuccessMessage(`Successfully deleted ${emptyCompanies.length} companies with no employees`);
      
      // Refresh the company list
      await fetchCompanies();
      
      setBulkDeleteDialogOpen(false);
    } catch (err: any) {
      setError(`Failed to delete companies: ${err.response?.data?.error || err.message}`);
    } finally {
      setBulkDeleteLoading(false);
    }
  };

  const handleCreateCompany = () => {
    setCreateDialogOpen(true);
  };

  const handleSubmitCreateCompany = async (companyData: any) => {
    try {
      setCreatingCompany(true);
      
      // Transform the data to match backend expectations
      const companyPayload = {
        name: companyData.name,
        domain: companyData.domain,
        subdomain: companyData.subdomain,
        adminEmail: companyData.adminEmail,
        adminPassword: companyData.adminPassword,
        adminFirstName: companyData.adminFirstName,
        adminLastName: companyData.adminLastName,
        subscriptionPlanId: companyData.subscriptionPlanId,
        contactPhone: companyData.contactPhone,
        address: companyData.address,
        notes: companyData.notes
      };
      
      console.log('Creating company with payload:', companyPayload);
      
      const response = await apiService.post('/api/super-admin/companies', companyPayload);
      console.log('Company created successfully:', response);
      
      await fetchCompanies(); // Refresh the list
      setCreateDialogOpen(false);
      setError(''); // Clear any previous errors
    } catch (err: any) {
      console.error('Error creating company:', err);
      console.error('Error response data:', err.response?.data);
      console.error('Error status:', err.response?.status);
      console.error('Error headers:', err.response?.headers);
      setError(err.response?.data?.message || err.response?.data?.error || 'Failed to create company');
    } finally {
      setCreatingCompany(false);
    }
  };

  const handleSubmitEditCompany = async (companyData: any) => {
    if (!selectedCompany) return;
    
    try {
      setEditingCompany(true);
              await apiService.put(`/api/super-admin/companies/${selectedCompany._id}`, companyData);
      await fetchCompanies(); // Refresh the list
      setEditDialogOpen(false);
      setSelectedCompany(null);
      setError(''); // Clear any previous errors
    } catch (err: any) {
      console.error('Error updating company:', err);
      setError(err.response?.data?.message || 'Failed to update company');
    } finally {
      setEditingCompany(false);
    }
  };

  const handleSubmitChangePlan = async () => {
    if (!selectedCompany || (!selectedPlanId && !isCustomPlan)) return;

    try {
      setChangingPlan(true);
      
      const planData = {
        companyId: selectedCompany._id,
        isCustomPlan: isCustomPlan,
        subscriptionPlanId: isCustomPlan ? undefined : selectedPlanId,
        customFeatures: isCustomPlan ? customFeatures : undefined,
        customLimits: isCustomPlan ? customLimits : undefined
      };

      await apiService.put(`/api/super-admin/companies/${selectedCompany._id}/subscription-plan`, planData);
      
      await fetchCompanies();
      setChangePlanDialogOpen(false);
      setSelectedPlanId('');
      setIsCustomPlan(false);
      setError('');
    } catch (err: any) {
      console.error('Error changing plan:', err);
      setError(err.response?.data?.message || 'Failed to change plan');
    } finally {
      setChangingPlan(false);
    }
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, height: '100%' }}>
        {/* Header */}
        <Paper sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexWrap: 'wrap', gap: 1 }}>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <Button
                variant="outlined"
                color="error"
                size="small"
                onClick={() => setBulkDeleteDialogOpen(true)}
              >
                Hard Delete Empty Companies
              </Button>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                size="small"
                onClick={handleCreateCompany}
              >
                Create Company
              </Button>
            </Box>
            
            <TextField
              variant="outlined"
              placeholder="Search companies..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              size="small"
              sx={{ minWidth: 250 }}
            />
          </Box>
        </Paper>

        {/* Error Alert */}
        {error && (
          <Alert severity="error" onClose={() => setError('')} sx={{ mb: 1 }}>
            {error}
          </Alert>
        )}

        {/* Success Alert */}
        {successMessage && (
          <Alert severity="success" onClose={() => setSuccessMessage('')} sx={{ mb: 1 }}>
            {successMessage}
          </Alert>
        )}

        {/* Data Grid */}
        <Paper sx={{ flex: 1, minHeight: 0 }}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
              <CircularProgress />
            </Box>
          ) : (
            <DataGrid
              rows={filteredCompanies}
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
            />
          )}
        </Paper>

      {/* Create Company Dialog */}
      <Dialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Create New Company</DialogTitle>
        <DialogContent>
          <CreateCompanyForm
            onSubmit={handleSubmitCreateCompany}
            onCancel={() => setCreateDialogOpen(false)}
            loading={creatingCompany}
          />
        </DialogContent>
      </Dialog>

      {/* View Company Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Company Details</DialogTitle>
        <DialogContent>
          {selectedCompany && (
            <Box sx={{ mt: 2 }}>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
                <Box sx={{ flex: '1 1 300px' }}>
                  <Typography variant="h6" gutterBottom>Basic Information</Typography>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Company Name</Typography>
                    <Typography variant="body1">{selectedCompany.name}</Typography>
                  </Box>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Domain</Typography>
                    <Typography variant="body1">{selectedCompany.domain}</Typography>
                  </Box>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Subdomain</Typography>
                    <Typography variant="body1">{selectedCompany.subdomain}</Typography>
                  </Box>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Status</Typography>
                    <Chip
                      label={selectedCompany.status}
                      color={
                        selectedCompany.status === 'active' ? 'success' :
                        selectedCompany.status === 'trial' ? 'warning' :
                        selectedCompany.status === 'cancelled' ? 'error' :
                        selectedCompany.status === 'suspended' ? 'error' : 'default'
                      }
                      size="small"
                    />
                  </Box>
                </Box>
                <Box sx={{ flex: '1 1 300px' }}>
                  <Typography variant="h6" gutterBottom>Contact Information</Typography>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Admin Email</Typography>
                    <Typography variant="body1">{selectedCompany.adminEmail || 'N/A'}</Typography>
                  </Box>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Contact Phone</Typography>
                    <Typography variant="body1">{selectedCompany.contactPhone || 'N/A'}</Typography>
                  </Box>
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" color="text.secondary">Subscription Plan</Typography>
                    <Typography variant="body1">{selectedCompany.subscriptionPlan?.name || 'N/A'}</Typography>
                  </Box>
                </Box>
              </Box>
              {selectedCompany.address && (
                <Box sx={{ mt: 3 }}>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="h6" gutterBottom>Address</Typography>
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                    <Box sx={{ flex: '1 1 300px' }}>
                      <Typography variant="subtitle2" color="text.secondary">Street</Typography>
                      <Typography variant="body1">{selectedCompany.address?.street || 'N/A'}</Typography>
                    </Box>
                    <Box sx={{ flex: '1 1 300px' }}>
                      <Typography variant="subtitle2" color="text.secondary">City</Typography>
                      <Typography variant="body1">{selectedCompany.address?.city || 'N/A'}</Typography>
                    </Box>
                    <Box sx={{ flex: '1 1 300px' }}>
                      <Typography variant="subtitle2" color="text.secondary">State/Province</Typography>
                      <Typography variant="body1">{selectedCompany.address?.state || 'N/A'}</Typography>
                    </Box>
                    <Box sx={{ flex: '1 1 300px' }}>
                      <Typography variant="subtitle2" color="text.secondary">Postal Code</Typography>
                      <Typography variant="body1">{selectedCompany.address?.postalCode || 'N/A'}</Typography>
                    </Box>
                    <Box sx={{ flex: '1 1 300px' }}>
                      <Typography variant="subtitle2" color="text.secondary">Country</Typography>
                      <Typography variant="body1">{selectedCompany.address?.country || 'N/A'}</Typography>
                    </Box>
                  </Box>
                </Box>
              )}
              <Box sx={{ mt: 3 }}>
                <Divider sx={{ my: 2 }} />
                <Typography variant="h6" gutterBottom>Timestamps</Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                  <Box sx={{ flex: '1 1 300px' }}>
                    <Typography variant="subtitle2" color="text.secondary">Created</Typography>
                    <Typography variant="body1">
                      {new Date(selectedCompany.createdAt).toLocaleString()}
                    </Typography>
                  </Box>
                  <Box sx={{ flex: '1 1 300px' }}>
                    <Typography variant="subtitle2" color="text.secondary">Last Updated</Typography>
                    <Typography variant="body1">
                      {new Date(selectedCompany.updatedAt).toLocaleString()}
                    </Typography>
                  </Box>
                </Box>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Edit Company Dialog */}
      <Dialog
        open={editDialogOpen}
        onClose={() => setEditDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Edit Company</DialogTitle>
        <DialogContent>
          {selectedCompany && (
            <Box sx={{ mt: 2 }}>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
                <Box sx={{ flex: '1 1 300px' }}>
                  <TextField
                    fullWidth
                    label="Company Name"
                    defaultValue={selectedCompany.name}
                    margin="normal"
                  />
                </Box>
                <Box sx={{ flex: '1 1 300px' }}>
                  <TextField
                    fullWidth
                    label="Domain"
                    defaultValue={selectedCompany.domain}
                    margin="normal"
                  />
                </Box>
                <Box sx={{ flex: '1 1 300px' }}>
                  <TextField
                    fullWidth
                    label="Subdomain"
                    defaultValue={selectedCompany.subdomain}
                    margin="normal"
                  />
                </Box>
                <Box sx={{ flex: '1 1 300px' }}>
                  <TextField
                    fullWidth
                    label="Contact Phone"
                    defaultValue={selectedCompany.contactPhone || ''}
                    margin="normal"
                  />
                </Box>
              </Box>
              <Box sx={{ mt: 3 }}>
                <Typography variant="h6" gutterBottom>Address</Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                  <Box sx={{ flex: '1 1 100%' }}>
                    <TextField
                      fullWidth
                      label="Street Address"
                      defaultValue={selectedCompany.address?.street || ''}
                      margin="normal"
                    />
                  </Box>
                  <Box sx={{ flex: '1 1 300px' }}>
                    <TextField
                      fullWidth
                      label="City"
                      defaultValue={selectedCompany.address?.city || ''}
                      margin="normal"
                    />
                  </Box>
                  <Box sx={{ flex: '1 1 300px' }}>
                    <TextField
                      fullWidth
                      label="State/Province"
                      defaultValue={selectedCompany.address?.state || ''}
                      margin="normal"
                    />
                  </Box>
                  <Box sx={{ flex: '1 1 300px' }}>
                    <TextField
                      fullWidth
                      label="Postal Code"
                      defaultValue={selectedCompany.address?.postalCode || ''}
                      margin="normal"
                    />
                  </Box>
                  <Box sx={{ flex: '1 1 300px' }}>
                    <TextField
                      fullWidth
                      label="Country"
                      defaultValue={selectedCompany.address?.country || ''}
                      margin="normal"
                    />
                  </Box>
                </Box>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={() => handleSubmitEditCompany({})}
            variant="contained"
            disabled={editingCompany}
          >
            {editingCompany ? 'Updating...' : 'Update Company'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Change Plan Dialog */}
      <Dialog
        open={changePlanDialogOpen}
        onClose={() => setChangePlanDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Change Subscription Plan</DialogTitle>
        <DialogContent>
          {selectedCompany && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="body1" gutterBottom>
                Change subscription plan for <strong>{selectedCompany.name}</strong>
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                Current plan: {selectedCompany.subscriptionPlan?.name || 'No Plan'}
              </Typography>
              
              <FormControl fullWidth margin="normal">
                <InputLabel>Select New Plan</InputLabel>
                <Select
                  value={selectedPlanId}
                  onChange={(e) => {
                    const value = e.target.value;
                    setSelectedPlanId(value);
                    setIsCustomPlan(value === 'custom');
                  }}
                  label="Select New Plan"
                >
                  <MenuItem value="custom">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <BuildIcon color="primary" />
                      <Box>
                        <Typography variant="body1" fontWeight={500}>
                          Custom Plan
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          Create a custom plan with specific features
                        </Typography>
                      </Box>
                    </Box>
                  </MenuItem>
                  <Divider />
                  {availablePlans.map((plan) => (
                    <MenuItem key={plan._id} value={plan._id}>
                      <Box>
                        <Typography variant="body1" fontWeight={500}>
                          {plan.name}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          ${plan.price?.monthly}/month - {plan.features?.maxEmployees} employees
                        </Typography>
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>

              {/* Custom Plan Configuration */}
              {isCustomPlan && (
                <Box sx={{ mt: 3 }}>
                  <Card variant="outlined">
                    <CardContent>
                      <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <BuildIcon color="primary" />
                        Custom Plan Configuration
                      </Typography>
                      
                      {/* Premium Features */}
                      <Typography variant="subtitle1" gutterBottom sx={{ mt: 2 }}>
                        Premium Features (Optional)
                      </Typography>
                      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 1 }}>
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={customFeatures.analytics}
                              onChange={(e) => setCustomFeatures(prev => ({ ...prev, analytics: e.target.checked }))}
                            />
                          }
                          label="Analytics & Reports"
                        />
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={customFeatures.advancedReporting}
                              onChange={(e) => setCustomFeatures(prev => ({ ...prev, advancedReporting: e.target.checked }))}
                            />
                          }
                          label="Advanced Reporting"
                        />
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={customFeatures.customBranding}
                              onChange={(e) => setCustomFeatures(prev => ({ ...prev, customBranding: e.target.checked }))}
                            />
                          }
                          label="Custom Branding"
                        />
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={customFeatures.apiAccess}
                              onChange={(e) => setCustomFeatures(prev => ({ ...prev, apiAccess: e.target.checked }))}
                            />
                          }
                          label="API Access"
                        />
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={customFeatures.multiLocation}
                              onChange={(e) => setCustomFeatures(prev => ({ ...prev, multiLocation: e.target.checked }))}
                            />
                          }
                          label="Multi Location"
                        />
                        <FormControlLabel
                          control={
                            <Checkbox
                              checked={customFeatures.expenseManagement}
                              onChange={(e) => setCustomFeatures(prev => ({ ...prev, expenseManagement: e.target.checked }))}
                            />
                          }
                          label="Expense Management"
                        />
                      </Box>

                      {/* Usage Limits */}
                      <Typography variant="subtitle1" gutterBottom sx={{ mt: 3 }}>
                        Usage Limits
                      </Typography>
                      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 2 }}>
                        <TextField
                          fullWidth
                          label="Max Employees"
                          type="number"
                          value={customLimits.maxEmployees}
                          onChange={(e) => setCustomLimits(prev => ({ ...prev, maxEmployees: parseInt(e.target.value) || 10 }))}
                          inputProps={{ min: 1, max: 1000 }}
                        />
                        <TextField
                          fullWidth
                          label="Max Storage (GB)"
                          type="number"
                          value={customLimits.maxStorageGB}
                          onChange={(e) => setCustomLimits(prev => ({ ...prev, maxStorageGB: parseInt(e.target.value) || 5 }))}
                          inputProps={{ min: 1, max: 1000 }}
                        />
                        <TextField
                          fullWidth
                          label="Max API Calls/Day"
                          type="number"
                          value={customLimits.maxApiCallsPerDay}
                          onChange={(e) => setCustomLimits(prev => ({ ...prev, maxApiCallsPerDay: parseInt(e.target.value) || 1000 }))}
                          inputProps={{ min: 0, max: 100000 }}
                        />
                        <TextField
                          fullWidth
                          label="Max Locations"
                          type="number"
                          value={customLimits.maxLocations}
                          onChange={(e) => setCustomLimits(prev => ({ ...prev, maxLocations: parseInt(e.target.value) || 1 }))}
                          inputProps={{ min: 1, max: 100 }}
                        />
                      </Box>

                      {/* Feature Summary */}
                      <Box sx={{ mt: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                        <Typography variant="subtitle2" gutterBottom>
                          Selected Features:
                        </Typography>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                          {Object.entries(customFeatures).map(([key, value]) => {
                            if (value) {
                              return (
                                <Chip
                                  key={key}
                                  label={key.charAt(0).toUpperCase() + key.slice(1).replace(/([A-Z])/g, ' $1')}
                                  size="small"
                                  color="primary"
                                  variant="outlined"
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

              {/* Predefined Plan Features */}
              {selectedPlanId && !isCustomPlan && (
                <Box sx={{ mt: 2 }}>
                  <Typography variant="subtitle2" gutterBottom>
                    Plan Features:
                  </Typography>
                  {availablePlans.find(p => p._id === selectedPlanId)?.features && (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                      {Object.entries(availablePlans.find(p => p._id === selectedPlanId)?.features || {}).map(([key, value]) => {
                        if (typeof value === 'boolean' && value) {
                          return (
                            <Chip
                              key={key}
                              label={key.charAt(0).toUpperCase() + key.slice(1)}
                              size="small"
                              color="primary"
                              variant="outlined"
                            />
                          );
                        }
                        return null;
                      })}
                    </Box>
                  )}
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setChangePlanDialogOpen(false)}>Cancel</Button>
          <Button 
            variant="contained" 
            onClick={handleSubmitChangePlan}
            disabled={!selectedPlanId || changingPlan}
          >
            {changingPlan ? <CircularProgress size={20} /> : 'Change Plan'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Bulk Delete Empty Companies Dialog */}
      <Dialog
        open={bulkDeleteDialogOpen}
        onClose={() => setBulkDeleteDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Permanently Delete Companies with No Employees</DialogTitle>
        <DialogContent>
          <Typography variant="body1" sx={{ mb: 2 }}>
            Are you sure you want to PERMANENTLY delete all companies that have zero employees?
          </Typography>
          <Typography variant="body2" color="textSecondary">
            This action will permanently remove companies from the database. 
            This action cannot be undone. Expired companies will be excluded from this operation.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setBulkDeleteDialogOpen(false)}
            disabled={bulkDeleteLoading}
          >
            Cancel
          </Button>
          <Button 
            onClick={handleBulkDeleteEmptyCompanies}
            variant="contained"
            color="error"
            disabled={bulkDeleteLoading}
          >
            {bulkDeleteLoading ? 'Deleting...' : 'Delete Empty Companies'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default CompanyManagementPage; 