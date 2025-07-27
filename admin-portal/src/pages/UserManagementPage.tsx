import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Button,
  Paper,
  Box,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  CircularProgress,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton
} from '@mui/material';
import { 
  Add as AddIcon, 
  Edit as EditIcon, 
  Delete as DeleteIcon, 
  LockReset as ResetIcon,
  LockOpen as UnlockIcon,
  ExpandMore as ExpandMoreIcon,
  Business as BusinessIcon,
  People as PeopleIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';
// import { unlockUser } from '../api/superAdminUnlockUser';
import Layout from '../components/Layout';
import UserForm from '../components/UserForm';
import { testBackendConnection } from '../utils/testConnection';

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

interface CompanyGroup {
  company: {
    _id: string;
    name: string;
    domain: string;
  };
  users: User[];
  employeeCount: number;
  adminCount: number;
}

interface UsersResponse {
  users: User[];
  totalPages: number;
  currentPage: number;
  total: number;
}

const UserManagementPage: React.FC = () => {
  // const [unlockLoading, setUnlockLoading] = useState(false);
  const [users, setUsers] = useState<User[]>([]);
  const [companies, setCompanies] = useState<any[]>([]);
  const [companyGroups, setCompanyGroups] = useState<CompanyGroup[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [expandedCompanies, setExpandedCompanies] = useState<string[]>([]);
  const [formLoading, setFormLoading] = useState(false);
  const [successMessage, setSuccessMessage] = useState('');
  const [passwordDialog, setPasswordDialog] = useState<{ open: boolean; password: string; userEmail: string }>({
    open: false,
    password: '',
    userEmail: ''
  });
  const [bulkTransferDialog, setBulkTransferDialog] = useState<{ open: boolean; fromCompany: string; toCompany: string }>({
    open: false,
    fromCompany: '',
    toCompany: ''
  });
  const [bulkTransferLoading, setBulkTransferLoading] = useState(false);

  useEffect(() => {
    fetchUsers();
    fetchCompanies();
  }, []);

  useEffect(() => {
    groupUsersByCompany();
  }, [users, companies]);

  const fetchCompanies = async () => {
    try {
      console.log('Fetching companies...');
      const data = await apiService.get<any>('/api/super-admin/companies?limit=1000');
      console.log('Companies response:', data);
      setCompanies(data.companies || []);
    } catch (err: any) {
      console.error('Error fetching companies:', err);
      console.error('Error response:', err.response?.data);
    }
  };

  const fetchUsers = async () => {
    setLoading(true);
    setError('');
    try {
      console.log('Fetching users...');
      // Fetch all users without pagination for user management view
      const data = await apiService.get<UsersResponse>('/api/super-admin/users?limit=1000');
      console.log('Users response:', data);
      setUsers(data.users || []);
    } catch (err: any) {
      console.error('Error fetching users:', err);
      console.error('Error response:', err.response?.data);
      setError(`Failed to fetch users: ${err.response?.data?.error || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const groupUsersByCompany = () => {
    const groups: { [key: string]: CompanyGroup } = {};
    
    // First, add all companies (even those without users)
    companies.forEach(company => {
      if (company.status !== 'cancelled' && company.status !== 'expired') {
        groups[company._id] = {
          company: {
            _id: company._id,
            name: company.name,
            domain: company.domain
          },
          users: [],
          employeeCount: 0,
          adminCount: 0
        };
      }
    });
    
    // Group users by company (excluding super admin users)
    users.forEach(user => {
      // Skip super admin users - they should not be managed through this interface
      if (user.role === 'super_admin') {
        return;
      }
      
      const companyId = user.companyId?._id || 'no-company';
      const companyName = user.companyId?.name || 'No Company';
      const companyDomain = user.companyId?.domain || 'N/A';
      
      if (!groups[companyId]) {
        groups[companyId] = {
          company: {
            _id: companyId,
            name: companyName,
            domain: companyDomain
          },
          users: [],
          employeeCount: 0,
          adminCount: 0
        };
      }
      
      groups[companyId].users.push(user);
      
      if (user.role === 'employee') {
        groups[companyId].employeeCount++;
      } else if (user.role === 'admin') {
        groups[companyId].adminCount++;
      }
    });
    
    // Convert to array and sort by company name
    const sortedGroups = Object.values(groups).sort((a, b) => 
      a.company.name.localeCompare(b.company.name)
    );
    
    setCompanyGroups(sortedGroups);
    
    // Auto-expand companies with users
    const companiesToExpand = sortedGroups
      .filter(group => group.users.length > 0)
      .map(group => group.company._id);
    setExpandedCompanies(companiesToExpand);
  };

  const handleCompanyToggle = (companyId: string) => {
    setExpandedCompanies(prev => 
      prev.includes(companyId) 
        ? prev.filter(id => id !== companyId)
        : [...prev, companyId]
    );
  };

  const handleEdit = (user: User) => {
    setSelectedUser(user);
    setOpenDialog(true);
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('Delete this user?')) return;
    setLoading(true);
    try {
      await apiService.delete(`/api/super-admin/users/${id}`);
      fetchUsers();
    } catch {
      setError('Delete failed');
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (user: User) => {
    if (!window.confirm(`Reset password for ${user.firstName} ${user.lastName}?`)) return;
    setLoading(true);
    try {
      const response = await apiService.post(`/api/super-admin/users/${user._id}/reset-password`) as any;
      const newPassword = response.newPassword;
      
      setPasswordDialog({
        open: true,
        password: newPassword,
        userEmail: user.email
      });
    } catch (err: any) {
      setError(`Password reset failed: ${err.response?.data?.error || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleUnlockUser = async (user: User) => {
    if (!window.confirm(`Unlock account for ${user.firstName} ${user.lastName}?`)) return;
    setLoading(true);
    try {
      await apiService.post(`/api/super-admin/users/${user._id}/unlock`);
      setSuccessMessage(`User account unlocked successfully!`);
      
      // Refresh the user list
      await fetchUsers();
      
      // Clear success message after a delay
      setTimeout(() => {
        setSuccessMessage('');
      }, 3000);
    } catch (err: any) {
      setError(`Failed to unlock user: ${err.response?.data?.error || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (userData: any) => {
    setFormLoading(true);
    setError('');
    setSuccessMessage('');
    
    try {
      const response = await apiService.post('/api/super-admin/users', userData) as any;
      
      if (response.generatedPassword) {
        setSuccessMessage(`User created successfully! Generated password: ${response.generatedPassword}`);
      } else {
        setSuccessMessage('User created successfully!');
      }
      
      // Refresh the user list
      await fetchUsers();
      
      // Close the dialog after a short delay
      setTimeout(() => {
        setOpenDialog(false);
        setSelectedUser(null);
        setSuccessMessage('');
      }, 2000);
      
    } catch (err: any) {
      console.error('Error creating user:', err);
      setError(`Failed to create user: ${err.response?.data?.error || err.message}`);
    } finally {
      setFormLoading(false);
    }
  };

  const handleUpdateUser = async (userData: any) => {
    if (!selectedUser) return;
    
    setFormLoading(true);
    setError('');
    setSuccessMessage('');
    
    try {
      await apiService.put(`/api/super-admin/users/${selectedUser._id}`, userData);
      setSuccessMessage('User updated successfully!');
      
      // Refresh the user list
      await fetchUsers();
      
      // Close the dialog after a short delay
      setTimeout(() => {
        setOpenDialog(false);
        setSelectedUser(null);
        setSuccessMessage('');
      }, 2000);
      
    } catch (err: any) {
      console.error('Error updating user:', err);
      setError(`Failed to update user: ${err.response?.data?.error || err.message}`);
    } finally {
      setFormLoading(false);
    }
  };

  const handleFormSubmit = async (userData: any) => {
    if (selectedUser) {
      await handleUpdateUser(userData);
    } else {
      await handleCreateUser(userData);
    }
  };

  const handleFormCancel = () => {
    setOpenDialog(false);
    setSelectedUser(null);
    setError('');
    setSuccessMessage('');
  };

  const handleBulkTransfer = async (fromCompanyId: string, toCompanyId: string) => {
    setBulkTransferLoading(true);
    setError('');
    try {
      // Get all users from the source company
      const sourceCompanyUsers = users.filter(user => 
        user.companyId?._id === fromCompanyId && user.role !== 'super_admin'
      );

      if (sourceCompanyUsers.length === 0) {
        setError('No users found in the source company');
        return;
      }

      // Transfer each user to the target company
      const transferPromises = sourceCompanyUsers.map(user =>
        apiService.put(`/api/super-admin/users/${user._id}`, {
          companyId: toCompanyId
        })
      );

      await Promise.all(transferPromises);
      
      setSuccessMessage(`Successfully transferred ${sourceCompanyUsers.length} users from ${sourceCompanyUsers[0]?.companyId?.name || 'Default Company'} to SNS Tech Services`);
      
      // Refresh the user list
      await fetchUsers();
      
      setBulkTransferDialog({ open: false, fromCompany: '', toCompany: '' });
    } catch (err: any) {
      setError(`Failed to transfer users: ${err.response?.data?.error || err.message}`);
    } finally {
      setBulkTransferLoading(false);
    }
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'super_admin': return '#d32f2f';
      case 'admin': return '#1976d2';
      case 'employee': return '#388e3c';
      default: return '#757575';
    }
  };

  const getStatusColor = (isActive: boolean) => {
    return isActive ? '#4caf50' : '#f44336';
  };

  if (loading && users.length === 0) {
    return (
      <Layout>
        <Container maxWidth="lg">
          <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
            <CircularProgress />
          </Box>
        </Container>
      </Layout>
    );
  }

  return (
    <Layout>
      <Container maxWidth="lg">
        <Box my={4}>
          <Typography variant="h4" gutterBottom>Company User Management</Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
            Manage users across all companies. Super admin users are not shown in this interface.
          </Typography>
          <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
            <Button 
              variant="contained" 
              startIcon={<AddIcon />} 
              onClick={() => { setSelectedUser(null); setOpenDialog(true); }}
            >
              Add User
            </Button>
            <Button
              variant="outlined"
              onClick={async () => {
                console.log('Testing backend connection...');
                const result = await testBackendConnection();
                console.log('Test result:', result);
                if (result.success && result.data) {
                  alert(`✅ Test passed! Found ${result.data.usersCount} users`);
                } else {
                  alert(`❌ Test failed: ${result.message}`);
                }
              }}
            >
              Test Connection
            </Button>
            <Button
              variant="outlined"
              color="secondary"
              onClick={() => {
                const defaultCompany = companyGroups.find(group => 
                  group.company.name.toLowerCase().includes('default')
                );
                const snsCompany = companyGroups.find(group => 
                  group.company.name.toLowerCase().includes('sns tech')
                );
                
                if (defaultCompany && snsCompany) {
                  setBulkTransferDialog({
                    open: true,
                    fromCompany: defaultCompany.company._id,
                    toCompany: snsCompany.company._id
                  });
                } else {
                  setError('Default Company or SNS Tech Services not found');
                }
              }}
            >
              Move Default Company Users to SNS Tech
            </Button>
          </Box>
        </Box>
        
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        {successMessage && <Alert severity="success" sx={{ mb: 2 }}>{successMessage}</Alert>}
        
        {companyGroups.length === 0 ? (
          <Paper sx={{ p: 4, textAlign: 'center' }}>
            <Typography variant="h6" color="textSecondary" gutterBottom>
              No users found
            </Typography>
            <Typography variant="body2" color="textSecondary">
              {error ? 'Error loading users' : 'No users available'}
            </Typography>
          </Paper>
        ) : (
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {companyGroups.map((group) => (
              <Paper key={group.company._id} sx={{ overflow: 'hidden' }}>
                <Accordion 
                  expanded={expandedCompanies.includes(group.company._id)}
                  onChange={() => handleCompanyToggle(group.company._id)}
                  sx={{ 
                    '&:before': { display: 'none' },
                    boxShadow: 'none',
                    border: '1px solid #e0e0e0'
                  }}
                >
                  <AccordionSummary
                    expandIcon={<ExpandMoreIcon />}
                    sx={{
                      backgroundColor: '#f5f5f5',
                      '&:hover': { backgroundColor: '#eeeeee' }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flex: 1 }}>
                      <BusinessIcon color="primary" />
                      <Box sx={{ flex: 1 }}>
                        <Typography variant="h6" fontWeight="bold">
                          {group.company.name}
                        </Typography>
                        <Typography variant="body2" color="textSecondary">
                          {group.company.domain}
                        </Typography>
                      </Box>
                      <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                        <Chip 
                          icon={<PeopleIcon />} 
                          label={`${group.users.length} Users`} 
                          size="small" 
                          color="primary" 
                          variant="outlined"
                        />
                        <Chip 
                          label={`${group.adminCount} Admins`} 
                          size="small" 
                          color="info" 
                          variant="outlined"
                        />
                        <Chip 
                          label={`${group.employeeCount} Employees`} 
                          size="small" 
                          color="success" 
                          variant="outlined"
                        />
                      </Box>
                    </Box>
                  </AccordionSummary>
                  
                  <AccordionDetails sx={{ p: 0 }}>
                    <TableContainer>
                      <Table>
                        <TableHead>
                          <TableRow sx={{ backgroundColor: '#fafafa' }}>
                            <TableCell><strong>Full Name</strong></TableCell>
                            <TableCell><strong>Email</strong></TableCell>
                            <TableCell><strong>Role</strong></TableCell>
                            <TableCell><strong>Status</strong></TableCell>
                            <TableCell><strong>Created</strong></TableCell>
                            <TableCell><strong>Actions</strong></TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {group.users.map((user) => (
                            <TableRow key={user._id} hover>
                              <TableCell>
                                <Box>
                                  <Typography variant="body2" fontWeight="medium">
                                    {`${user.firstName || ''} ${user.lastName || ''}`.trim()}
                                  </Typography>
                                  {user.position && (
                                    <Typography variant="caption" color="textSecondary">
                                      {user.position}
                                    </Typography>
                                  )}
                                </Box>
                              </TableCell>
                              <TableCell>
                                <Box>
                                  <Typography variant="body2">
                                    {user.email}
                                  </Typography>
                                  {user.department && (
                                    <Typography variant="caption" color="textSecondary">
                                      {user.department}
                                    </Typography>
                                  )}
                                </Box>
                              </TableCell>
                              <TableCell>
                                <Chip
                                  label={user.role ? user.role.replace('_', ' ').toUpperCase() : ''}
                                  size="small"
                                  sx={{
                                    backgroundColor: getRoleColor(user.role),
                                    color: 'white',
                                    fontWeight: 'medium'
                                  }}
                                />
                              </TableCell>
                              <TableCell>
                                <Chip
                                  label={user.isActive ? 'Active' : 'Inactive'}
                                  size="small"
                                  sx={{
                                    backgroundColor: getStatusColor(user.isActive),
                                    color: 'white',
                                    fontWeight: 'medium'
                                  }}
                                />
                              </TableCell>
                              <TableCell>
                                {user.createdAt ? (
                                  <Typography variant="body2">
                                    {new Date(user.createdAt).toLocaleDateString()}
                                  </Typography>
                                ) : (
                                  <Typography variant="body2" color="textSecondary">
                                    N/A
                                  </Typography>
                                )}
                              </TableCell>
                              <TableCell>
                                <Box sx={{ display: 'flex', gap: 1 }}>
                                  <IconButton
                                    size="small"
                                    onClick={() => handleEdit(user)}
                                    disabled={user.role === 'super_admin'}
                                  >
                                    <EditIcon fontSize="small" />
                                  </IconButton>
                                  <IconButton
                                    size="small"
                                    onClick={() => handleDelete(user._id)}
                                    disabled={user.role === 'super_admin'}
                                  >
                                    <DeleteIcon fontSize="small" />
                                  </IconButton>
                                  <IconButton
                                    size="small"
                                    onClick={() => handleResetPassword(user)}
                                  >
                                    <ResetIcon fontSize="small" />
                                  </IconButton>
                                  <IconButton
                                    size="small"
                                    onClick={() => handleUnlockUser(user)}
                                    disabled={user.isActive}
                                  >
                                    <UnlockIcon fontSize="small" />
                                  </IconButton>
                                </Box>
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </AccordionDetails>
                </Accordion>
              </Paper>
            ))}
          </Box>
        )}

        <Dialog 
          open={openDialog} 
          onClose={handleFormCancel}
          maxWidth="md"
          fullWidth
        >
          <DialogTitle>
            {selectedUser ? 'Edit User' : 'Add New User'}
          </DialogTitle>
          <DialogContent>
            <UserForm
              user={selectedUser}
              onSubmit={handleFormSubmit}
              onCancel={handleFormCancel}
              loading={formLoading}
            />
          </DialogContent>
        </Dialog>

        <Dialog
          open={passwordDialog.open}
          onClose={() => setPasswordDialog({ ...passwordDialog, open: false })}
          maxWidth="sm"
          fullWidth
        >
          <DialogTitle>New Password for {passwordDialog.userEmail}</DialogTitle>
          <DialogContent>
            <Typography variant="body1">
              Your new password is: <strong>{passwordDialog.password}</strong>
            </Typography>
            <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
              Please immediately change this password in the user's profile.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setPasswordDialog({ ...passwordDialog, open: false })}>Close</Button>
          </DialogActions>
        </Dialog>

        {/* Bulk Transfer Dialog */}
        <Dialog
          open={bulkTransferDialog.open}
          onClose={() => setBulkTransferDialog({ ...bulkTransferDialog, open: false })}
          maxWidth="sm"
          fullWidth
        >
          <DialogTitle>Bulk Transfer Users</DialogTitle>
          <DialogContent>
            <Typography variant="body1" sx={{ mb: 2 }}>
              Are you sure you want to move all users from <strong>Default Company</strong> to <strong>SNS Tech Services</strong>?
            </Typography>
            <Typography variant="body2" color="textSecondary">
              This action will transfer all users (admins and employees) from Default Company to SNS Tech Services. 
              This action cannot be undone.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button 
              onClick={() => setBulkTransferDialog({ ...bulkTransferDialog, open: false })}
              disabled={bulkTransferLoading}
            >
              Cancel
            </Button>
            <Button 
              onClick={() => handleBulkTransfer(bulkTransferDialog.fromCompany, bulkTransferDialog.toCompany)}
              variant="contained"
              color="secondary"
              disabled={bulkTransferLoading}
            >
              {bulkTransferLoading ? 'Transferring...' : 'Confirm Transfer'}
            </Button>
          </DialogActions>
        </Dialog>
      </Container>
    </Layout>
  );
};

export default UserManagementPage;
