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
  Card,
  CardContent
} from '@mui/material';


import {
  DataGrid,
  GridColDef,
  GridToolbar,
} from '@mui/x-data-grid';
import {
  RestoreFromTrash as RestoreIcon,
  Visibility as ViewIcon,
  Business as BusinessIcon,
  Delete as DeleteIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

interface ArchivedCompany {
  _id: string;
  name: string;
  domain: string;
  subdomain: string;
  status: string;
  adminEmail: string;
  employeeCount: number;
  archivedAt: string;
  archivedBy: {
    firstName: string;
    lastName: string;
    email: string;
  };
  archiveReason: string;
  subscriptionPlan?: {
    name: string;
  };
  createdAt: string;
}

const ArchivedCompaniesPage: React.FC = () => {
  const [companies, setCompanies] = useState<ArchivedCompany[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCompany, setSelectedCompany] = useState<ArchivedCompany | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [restoreLoading, setRestoreLoading] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [restoreDialogOpen, setRestoreDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [companyToAction, setCompanyToAction] = useState<ArchivedCompany | null>(null);

  useEffect(() => {
    fetchArchivedCompanies();
  }, []);

  const fetchArchivedCompanies = async () => {
    try {
      setLoading(true);
      const response = await apiService.get<any>('/api/super-admin/companies/archived');
      const companiesData = response.companies || [];
      
      // Add computed fields for DataGrid
      const processedCompanies = companiesData.map((company: any) => ({
        ...company,
        id: company._id,
        archivedByDisplay: company.archivedBy ? `${company.archivedBy.firstName} ${company.archivedBy.lastName}` : 'Unknown',
        archivedDate: new Date(company.archivedAt).toLocaleDateString(),
        planName: company.subscriptionPlan?.name || 'No Plan'
      }));
      
      setCompanies(processedCompanies);
    } catch (err: any) {
      console.error('Error fetching archived companies:', err);
      setError(err.response?.data?.error || 'Failed to fetch archived companies');
    } finally {
      setLoading(false);
    }
  };

  const handleViewCompany = (company: ArchivedCompany) => {
    setSelectedCompany(company);
    setViewDialogOpen(true);
  };

  const handleRestoreCompany = (company: ArchivedCompany) => {
    setCompanyToAction(company);
    setRestoreDialogOpen(true);
  };

  const handleDeleteCompany = (company: ArchivedCompany) => {
    setCompanyToAction(company);
    setDeleteDialogOpen(true);
  };

  const confirmRestore = async () => {
    if (!companyToAction) return;
    
    setRestoreLoading(true);
    try {
      await apiService.put(`/api/super-admin/companies/${companyToAction._id}/restore`);
      setSuccessMessage(`Successfully restored ${companyToAction.name}`);
      setRestoreDialogOpen(false);
      setCompanyToAction(null);
      await fetchArchivedCompanies(); // Refresh the list
    } catch (err: any) {
      setError(`Failed to restore company: ${err.response?.data?.error || err.message}`);
    } finally {
      setRestoreLoading(false);
    }
  };

  const confirmDelete = async () => {
    if (!companyToAction) return;
    
    setDeleteLoading(true);
    try {
      await apiService.delete(`/api/super-admin/companies/${companyToAction._id}/hard-delete`);
      setSuccessMessage(`Successfully deleted ${companyToAction.name}`);
      setDeleteDialogOpen(false);
      setCompanyToAction(null);
      await fetchArchivedCompanies(); // Refresh the list
    } catch (err: any) {
      setError(`Failed to delete company: ${err.response?.data?.error || err.message}`);
    } finally {
      setDeleteLoading(false);
    }
  };

  const filteredCompanies = companies.filter(company =>
    company.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    company.domain.toLowerCase().includes(searchTerm.toLowerCase()) ||
    company.adminEmail.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const columns: GridColDef[] = [
    {
      field: 'name',
      headerName: 'Company Name',
      flex: 1.8,
      minWidth: 280,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <BusinessIcon color="action" fontSize="small" />
          <Typography variant="body2" fontWeight="medium" noWrap>
            {params.value}
          </Typography>
        </Box>
      )
    },
    {
      field: 'domain',
      headerName: 'Domain',
      flex: 1.2,
      minWidth: 160,
      renderCell: (params) => (
        <Typography variant="body2" noWrap>
          {params.value}
        </Typography>
      )
    },
    {
      field: 'adminEmail',
      headerName: 'Admin Email',
      flex: 1.5,
      minWidth: 200,
      renderCell: (params) => (
        <Typography variant="body2" noWrap>
          {params.value}
        </Typography>
      )
    },
    {
      field: 'employeeCount',
      headerName: 'Employees',
      width: 120,
      renderCell: (params) => (
        <Chip 
          label={params.value} 
          size="small" 
          color="primary" 
          variant="outlined"
        />
      )
    },
    {
      field: 'planName',
      headerName: 'Plan',
      width: 90
    },
    {
      field: 'archivedDate',
      headerName: 'Archived Date',
      width: 130
    },
    {
      field: 'archivedByDisplay',
      headerName: 'Archived By',
      width: 130
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 320,
      sortable: false,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', gap: 1, flexDirection: 'row', flexWrap: 'nowrap' }}>
          <Button
            size="small"
            startIcon={<ViewIcon />}
            onClick={() => handleViewCompany(params.row)}
            variant="outlined"
            sx={{ 
              minWidth: 'fit-content',
              px: 1.5,
              py: 0.5,
              fontSize: '0.75rem'
            }}
          >
            View
          </Button>
          <Button
            size="small"
            startIcon={<RestoreIcon />}
            onClick={() => handleRestoreCompany(params.row)}
            variant="outlined"
            color="primary"
            sx={{ 
              minWidth: 'fit-content',
              px: 1.5,
              py: 0.5,
              fontSize: '0.75rem'
            }}
          >
            Restore
          </Button>
          <Button
            size="small"
            startIcon={<DeleteIcon />}
            onClick={() => handleDeleteCompany(params.row)}
            variant="outlined"
            color="error"
            sx={{ 
              minWidth: 'fit-content',
              px: 1.5,
              py: 0.5,
              fontSize: '0.75rem'
            }}
          >
            Delete
          </Button>
        </Box>
      )
    }
  ];

  if (loading && companies.length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ 
      display: 'flex', 
      flexDirection: 'column', 
      gap: 2, 
      height: '100vh',
      maxWidth: '100%',
      overflow: 'hidden',
      p: 2
    }}>
      {/* Header */}
      <Paper sx={{ p: 2.5, mb: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="h5" fontWeight="bold" sx={{ mb: 0.5 }}>
              Archived Companies
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Manage and restore archived company data
            </Typography>
          </Box>
          
          <TextField
            variant="outlined"
            placeholder="Search archived companies..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            size="small"
            sx={{ minWidth: 280 }}
            InputProps={{
              startAdornment: (
                <Box sx={{ mr: 1, color: 'text.secondary' }}>
                  🔍
                </Box>
              ),
            }}
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

      {/* Summary Card */}
      <Paper sx={{ p: 1.5, mb: 2, backgroundColor: '#f8f9fa' }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 2 }}>
          <Box>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
              Total Archived Companies
            </Typography>
            <Typography variant="h5" fontWeight="bold" color="primary">
              {companies.length}
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1.5 }}>
            <Chip 
              label={`${companies.filter(c => c.employeeCount > 0).length} with employees`}
              color="info"
              variant="outlined"
              size="small"
            />
            <Chip 
              label={`${companies.filter(c => c.employeeCount === 0).length} empty`}
              color="warning"
              variant="outlined"
              size="small"
            />
          </Box>
        </Box>
      </Paper>

      {/* Data Grid */}
      <Paper sx={{ flex: 1, minHeight: 0, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 400 }}>
            <CircularProgress />
          </Box>
        ) : (
          <DataGrid
            rows={filteredCompanies}
            columns={columns}
            initialState={{
              pagination: {
                paginationModel: { page: 0, pageSize: 15 },
              },
            }}
            pageSizeOptions={[10, 15, 25, 50]}
            disableRowSelectionOnClick
            getRowId={(row) => row._id}
            slots={{
              toolbar: GridToolbar,
            }}
            slotProps={{
              toolbar: {
                showQuickFilter: false, // We have our own search
              },
            }}
            sx={{
              flex: 1,
              '& .MuiDataGrid-cell': {
                borderBottom: '1px solid #f0f0f0',
                padding: '8px 16px',
              },
              '& .MuiDataGrid-columnHeaders': {
                backgroundColor: '#f8f9fa',
                borderBottom: '2px solid #e0e0e0',
                '& .MuiDataGrid-columnHeader': {
                  padding: '12px 16px',
                }
              },
              '& .MuiDataGrid-row:hover': {
                backgroundColor: '#f5f5f5',
              },
              '& .MuiDataGrid-virtualScroller': {
                backgroundColor: '#ffffff',
              },
            }}
          />
        )}
      </Paper>

      {/* View Company Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Archived Company Details</DialogTitle>
        <DialogContent>
          {selectedCompany && (
            <Box sx={{ mt: 2 }}>
              <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
                <Box sx={{ flex: 1, minWidth: 300 }}>
                  <Card>
                    <CardContent>
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
                        <Typography variant="subtitle2" color="text.secondary">Admin Email</Typography>
                        <Typography variant="body1">{selectedCompany.adminEmail}</Typography>
                      </Box>
                    </CardContent>
                  </Card>
                </Box>
                
                <Box sx={{ flex: 1, minWidth: 300 }}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>Archive Information</Typography>
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" color="text.secondary">Archived Date</Typography>
                        <Typography variant="body1">
                          {new Date(selectedCompany.archivedAt).toLocaleString()}
                        </Typography>
                      </Box>
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" color="text.secondary">Archived By</Typography>
                        <Typography variant="body1">
                          {selectedCompany.archivedBy ? 
                            `${selectedCompany.archivedBy.firstName} ${selectedCompany.archivedBy.lastName}` : 
                            'Unknown'
                          }
                        </Typography>
                      </Box>
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" color="text.secondary">Archive Reason</Typography>
                        <Typography variant="body1">{selectedCompany.archiveReason}</Typography>
                      </Box>
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="subtitle2" color="text.secondary">Employee Count</Typography>
                        <Chip 
                          label={selectedCompany.employeeCount} 
                          size="small" 
                          color="primary" 
                          variant="outlined"
                        />
                      </Box>
                    </CardContent>
                  </Card>
                </Box>
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Restore Confirmation Dialog */}
      <Dialog
        open={restoreDialogOpen}
        onClose={() => setRestoreDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Restore Company</DialogTitle>
        <DialogContent>
          <Typography variant="body1" sx={{ mb: 2 }}>
            Are you sure you want to restore "{companyToAction?.name}"?
          </Typography>
          <Typography variant="body2" color="textSecondary">
            This will restore the company to active status and make it available for use again.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setRestoreDialogOpen(false)}
            disabled={restoreLoading}
          >
            Cancel
          </Button>
          <Button 
            onClick={confirmRestore}
            variant="contained"
            color="primary"
            disabled={restoreLoading}
          >
            {restoreLoading ? 'Restoring...' : 'Restore Company'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Hard Delete Confirmation Dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Permanently Delete Company</DialogTitle>
        <DialogContent>
          <Typography variant="body1" sx={{ mb: 2 }}>
            Are you sure you want to PERMANENTLY delete "{companyToAction?.name}"?
          </Typography>
          <Typography variant="body2" color="textSecondary">
            This action will permanently remove the company from the database. 
            This action cannot be undone. All associated data will be lost.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setDeleteDialogOpen(false)}
            disabled={deleteLoading}
          >
            Cancel
          </Button>
          <Button 
            onClick={confirmDelete}
            variant="contained"
            color="error"
            disabled={deleteLoading}
          >
            {deleteLoading ? 'Deleting...' : 'Permanently Delete'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default ArchivedCompaniesPage; 