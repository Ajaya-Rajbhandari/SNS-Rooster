import React, { useState, useEffect, useCallback } from 'react';
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
  IconButton,
  Checkbox,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Tooltip
} from '@mui/material';
import { 
  Add as AddIcon, 
  Edit as EditIcon, 
  Delete as DeleteIcon, 
  LockReset as ResetIcon,
  LockOpen as UnlockIcon,
  Lock as LockIcon,
  ExpandMore as ExpandMoreIcon,
  Business as BusinessIcon,
  People as PeopleIcon,
  MoreVert as MoreVertIcon,
  SelectAll as SelectAllIcon,
  Clear as ClearIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';
// import { unlockUser } from '../api/superAdminUnlockUser';
import UserForm from '../components/UserForm';
import BulkUserOperations from '../components/BulkUserOperations';

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
  const [selectedCompanyId, setSelectedCompanyId] = useState<string>('');
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
  
  // Multi-select state
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [bulkActionAnchorEl, setBulkActionAnchorEl] = useState<null | HTMLElement>(null);
  const [bulkActionLoading, setBulkActionLoading] = useState(false);
  const [bulkOperationsOpen, setBulkOperationsOpen] = useState(false);

  useEffect(() => {
    fetchUsers();
    fetchCompanies();
  }, []);

  const groupUsersByCompany = useCallback(() => {
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
    
    // Keep companies collapsed by default
    setExpandedCompanies([]);
  }, [users, companies]);

  useEffect(() => {
    groupUsersByCompany();
  }, [groupUsersByCompany]);

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

  const handleToggleUserStatus = async (user: User) => {
    const action = user.isActive ? 'deactivate' : 'activate';
    if (!window.confirm(`${action.charAt(0).toUpperCase() + action.slice(1)} account for ${user.firstName} ${user.lastName}?`)) return;
    
    setLoading(true);
    try {
      await apiService.put(`/api/super-admin/users/${user._id}`, {
        ...user,
        isActive: !user.isActive
      });
      setSuccessMessage(`User ${action}d successfully!`);
      
      // Refresh the user list
      await fetchUsers();
      
      // Clear success message after a delay
      setTimeout(() => {
        setSuccessMessage('');
      }, 3000);
    } catch (err: any) {
      setError(`Failed to ${action} user: ${err.response?.data?.error || err.message}`);
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

  // Multi-select helper functions
  const handleSelectUser = (userId: string) => {
    setSelectedUsers(prev => 
      prev.includes(userId) 
        ? prev.filter(id => id !== userId)
        : [...prev, userId]
    );
  };

  const handleSelectAllUsers = (companyUsers: User[]) => {
    const companyUserIds = companyUsers.map(user => user._id);
    setSelectedUsers(prev => {
      const allSelected = companyUserIds.every(id => prev.includes(id));
      if (allSelected) {
        return prev.filter(id => !companyUserIds.includes(id));
      } else {
        return Array.from(new Set([...prev, ...companyUserIds]));
      }
    });
  };

  const handleClearSelection = () => {
    setSelectedUsers([]);
  };

  const isUserSelected = (userId: string) => selectedUsers.includes(userId);

  const getSelectedUsers = () => {
    return users.filter(user => selectedUsers.includes(user._id));
  };

  const getSelectedUsersByCompany = (companyUsers: User[]) => {
    return companyUsers.filter(user => selectedUsers.includes(user._id));
  };

  const isAllSelected = (companyUsers: User[]) => {
    return companyUsers.length > 0 && companyUsers.every(user => selectedUsers.includes(user._id));
  };

  const isIndeterminate = (companyUsers: User[]) => {
    const selectedCount = companyUsers.filter(user => selectedUsers.includes(user._id)).length;
    return selectedCount > 0 && selectedCount < companyUsers.length;
  };

  // Bulk action functions
  const handleBulkAction = async (action: 'activate' | 'deactivate' | 'delete' | 'resetPassword') => {
    if (selectedUsers.length === 0) return;

    setBulkActionLoading(true);
    setBulkActionAnchorEl(null);

    try {
      const selectedUserObjects = getSelectedUsers();
      
      switch (action) {
        case 'activate':
          await Promise.all(selectedUserObjects.map(user => 
            apiService.patch(`/api/super-admin/users/${user._id}`, { isActive: true })
          ));
          setSuccessMessage(`Successfully activated ${selectedUsers.length} user(s)`);
          break;
        
        case 'deactivate':
          await Promise.all(selectedUserObjects.map(user => 
            apiService.patch(`/api/super-admin/users/${user._id}`, { isActive: false })
          ));
          setSuccessMessage(`Successfully deactivated ${selectedUsers.length} user(s)`);
          break;
        
        case 'delete':
          const confirmed = window.confirm(`Are you sure you want to delete ${selectedUsers.length} user(s)? This action cannot be undone.`);
          if (confirmed) {
            await Promise.all(selectedUsers.map(id => 
              apiService.delete(`/api/super-admin/users/${id}`)
            ));
            setSuccessMessage(`Successfully deleted ${selectedUsers.length} user(s)`);
          }
          break;
        
        case 'resetPassword':
          const resetConfirmed = window.confirm(`Are you sure you want to reset passwords for ${selectedUsers.length} user(s)?`);
          if (resetConfirmed) {
            await Promise.all(selectedUserObjects.map(user => 
              apiService.post(`/api/super-admin/users/${user._id}/reset-password`)
            ));
            setSuccessMessage(`Successfully reset passwords for ${selectedUsers.length} user(s)`);
          }
          break;
      }
      
      setSelectedUsers([]);
      fetchUsers();
    } catch (error) {
      console.error('Bulk action error:', error);
      setError(`Failed to perform bulk action: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setBulkActionLoading(false);
    }
  };

  const handleBulkOperationsSuccess = () => {
    setBulkOperationsOpen(false);
    setSuccessMessage('Bulk operations completed successfully');
    fetchUsers();
  };

  if (loading && users.length === 0) {
    return (
      <Container maxWidth="lg">
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, height: '100%' }}>
      <Box sx={{ mb: 1 }}>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 1 }} component="div">
          Manage users across all companies. Super admin users are not shown in this interface.
        </Typography>
        <Box sx={{ display: 'flex', gap: 1, mb: 1, flexWrap: 'wrap', alignItems: 'center' }}>
          {selectedUsers.length > 0 && (
            <>
              <Typography variant="body2" color="textSecondary">
                {selectedUsers.length} user(s) selected
              </Typography>
              <Button
                variant="outlined"
                startIcon={<ClearIcon />}
                size="small"
                onClick={handleClearSelection}
              >
                Clear
              </Button>
              <Button
                variant="contained"
                startIcon={<MoreVertIcon />}
                size="small"
                onClick={(e) => setBulkActionAnchorEl(e.currentTarget)}
                disabled={bulkActionLoading}
              >
                Bulk Actions
              </Button>
              <Menu
                anchorEl={bulkActionAnchorEl}
                open={Boolean(bulkActionAnchorEl)}
                onClose={() => setBulkActionAnchorEl(null)}
              >
                <MenuItem onClick={() => handleBulkAction('activate')}>
                  <ListItemIcon>
                    <UnlockIcon fontSize="small" />
                  </ListItemIcon>
                  <ListItemText>Activate Selected</ListItemText>
                </MenuItem>
                <MenuItem onClick={() => handleBulkAction('deactivate')}>
                  <ListItemIcon>
                    <LockIcon fontSize="small" />
                  </ListItemIcon>
                  <ListItemText>Deactivate Selected</ListItemText>
                </MenuItem>
                <MenuItem onClick={() => handleBulkAction('resetPassword')}>
                  <ListItemIcon>
                    <ResetIcon fontSize="small" />
                  </ListItemIcon>
                  <ListItemText>Reset Passwords</ListItemText>
                </MenuItem>
                <MenuItem onClick={() => handleBulkAction('delete')}>
                  <ListItemIcon>
                    <DeleteIcon fontSize="small" />
                  </ListItemIcon>
                  <ListItemText>Delete Selected</ListItemText>
                </MenuItem>
              </Menu>
            </>
          )}
          <Button 
            variant="contained" 
            startIcon={<AddIcon />}
            size="small"
            onClick={() => { setSelectedUser(null); setOpenDialog(true); }}
          >
            Add User
          </Button>
          <Button 
            variant="contained" 
            startIcon={<PeopleIcon />}
            size="small"
            onClick={() => setBulkOperationsOpen(true)}
          >
            Bulk Operations
          </Button>
        </Box>
      </Box>
      
      {error && <Alert severity="error" sx={{ mb: 1 }}>{error}</Alert>}
      {successMessage && <Alert severity="success" sx={{ mb: 1 }}>{successMessage}</Alert>}
      
      {companyGroups.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" color="textSecondary" gutterBottom>
            No users found
          </Typography>
          <Typography variant="body2" color="textSecondary" component="div">
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
                      <Typography variant="body2" color="textSecondary" component="div">
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
                          <TableCell padding="checkbox">
                            <Checkbox
                              checked={isAllSelected(group.users)}
                              indeterminate={isIndeterminate(group.users)}
                              onChange={() => handleSelectAllUsers(group.users)}
                              disabled={group.users.length === 0}
                            />
                          </TableCell>
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
                          <TableRow 
                            key={user._id} 
                            hover
                            sx={{
                              backgroundColor: isUserSelected(user._id) ? 'rgba(25, 118, 210, 0.08)' : 'inherit',
                              '&:hover': {
                                backgroundColor: isUserSelected(user._id) 
                                  ? 'rgba(25, 118, 210, 0.12)' 
                                  : 'rgba(0, 0, 0, 0.04)'
                              }
                            }}
                          >
                            <TableCell padding="checkbox">
                              <Checkbox
                                checked={isUserSelected(user._id)}
                                onChange={() => handleSelectUser(user._id)}
                                disabled={user.role === 'super_admin'}
                              />
                            </TableCell>
                            <TableCell>
                              <Box>
                                <Typography variant="body2" fontWeight="medium" component="div">
                                  {`${user.firstName || ''} ${user.lastName || ''}`.trim()}
                                </Typography>
                                {user.position && (
                                  <Typography variant="caption" color="textSecondary" component="div">
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
                                  <Typography variant="caption" color="textSecondary" component="div">
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
                                <Typography variant="body2" component="div">
                                  {new Date(user.createdAt).toLocaleDateString()}
                                </Typography>
                              ) : (
                                <Typography variant="body2" color="textSecondary" component="div">
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
                                  onClick={() => handleToggleUserStatus(user)}
                                  title={user.isActive ? 'Deactivate User' : 'Activate User'}
                                >
                                  {user.isActive ? <LockIcon fontSize="small" /> : <UnlockIcon fontSize="small" />}
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
          <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }} component="div">
            Please immediately change this password in the user's profile.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPasswordDialog({ ...passwordDialog, open: false })}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Bulk Operations Dialog */}
      <BulkUserOperations
        open={bulkOperationsOpen}
        onClose={() => setBulkOperationsOpen(false)}
        onSuccess={handleBulkOperationsSuccess}
        users={users}
        companies={companies}
        selectedCompanyId={selectedCompanyId}
      />

    </Box>
  );
};

export default UserManagementPage;
