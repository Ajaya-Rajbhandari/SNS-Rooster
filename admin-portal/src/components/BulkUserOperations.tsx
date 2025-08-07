import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Tabs,
  Tab,
  Alert,
  CircularProgress,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Tooltip,
  Divider,
  Checkbox
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Download as DownloadIcon,
  Upload as UploadIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Close as CloseIcon,
  Clear as ClearIcon,
  FileUpload as FileUploadIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

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

interface BulkOperationResponse {
  message: string;
  results: {
    successful: Array<{
      email: string;
      userId?: string;
      error?: string;
    }>;
    failed: Array<{
      email: string;
      error: string;
    }>;
    total: number;
  };
}

interface BulkUserOperationsProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  users: User[];
  companies: any[];
  selectedCompanyId?: string;
}

const BulkUserOperations: React.FC<BulkUserOperationsProps> = ({
  open,
  onClose,
  onSuccess,
  users,
  companies,
  selectedCompanyId
}) => {
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [bulkUpdateData, setBulkUpdateData] = useState({
    role: '',
    department: '',
    position: '',
    isActive: ''
  });

  // Bulk Create State
  const [newUsers, setNewUsers] = useState<Array<{
    firstName: string;
    lastName: string;
    email: string;
    role: string;
    companyId: string;
    department: string;
    position: string;
    password: string;
    passwordRule?: string;
  }>>([]);
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [csvError, setCsvError] = useState<string>('');

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
    setError('');
    setSuccess('');
  };

  const handleUserSelection = (userId: string) => {
    setSelectedUsers(prev => 
      prev.includes(userId) 
        ? prev.filter(id => id !== userId)
        : [...prev, userId]
    );
  };

  const handleSelectAll = () => {
    if (selectedUsers.length === users.length) {
      setSelectedUsers([]);
    } else {
      setSelectedUsers(users.map(user => user._id));
    }
  };

  const handleClearSelection = () => {
    setSelectedUsers([]);
  };

  // Bulk Create Functions
  const addNewUserRow = () => {
    setNewUsers(prev => [...prev, {
      firstName: '',
      lastName: '',
      email: '',
      role: 'employee',
      companyId: selectedCompanyId || '',
      department: '',
      position: '',
      password: 'defaultPassword123',
      passwordRule: 'default'
    }]);
  };

  const updateNewUser = (index: number, field: string, value: string) => {
    setNewUsers(prev => prev.map((user, i) => 
      i === index ? { ...user, [field]: value } : user
    ));
  };

  const removeNewUser = (index: number) => {
    setNewUsers(prev => prev.filter((_, i) => i !== index));
  };

  // Password Generation Functions
  const generatePassword = (rule: string, userData: {
    firstName: string;
    lastName: string;
    email: string;
  }): string => {
    const { firstName, lastName, email } = userData;
    
    switch (rule.toLowerCase()) {
      case 'firstname+lastname':
        return `${firstName.toLowerCase()}+${lastName.toLowerCase()}`;
      case 'email+123':
        return `${email}+123`;
      case 'firstname123':
        return `${firstName.toLowerCase()}123`;
      case 'lastname123':
        return `${lastName.toLowerCase()}123`;
      case 'email':
        return email;
      case 'custom':
        return 'customPassword123'; // Will be overridden by custom password
      case 'default':
      default:
        return 'defaultPassword123';
    }
  };

  // CSV Import Functions
  const handleCsvFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      if (file.type !== 'text/csv' && !file.name.endsWith('.csv')) {
        setCsvError('Please select a valid CSV file');
        return;
      }
      setCsvFile(file);
      setCsvError('');
      parseCsvFile(file);
    }
  };

  const parseCsvFile = (file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const csv = e.target?.result as string;
        const lines = csv.split('\n');
        const headers = lines[0].split(',').map(h => h.trim().toLowerCase());
        
        // Validate headers
        const requiredHeaders = ['firstname', 'lastname', 'email', 'role', 'companyid', 'department', 'position'];
        const missingHeaders = requiredHeaders.filter(h => !headers.includes(h));
        
        if (missingHeaders.length > 0) {
          setCsvError(`Missing required headers: ${missingHeaders.join(', ')}`);
          return;
        }

        const parsedUsers: Array<{
          firstName: string;
          lastName: string;
          email: string;
          role: string;
          companyId: string;
          department: string;
          position: string;
          password: string;
          passwordRule?: string;
        }> = [];

        for (let i = 1; i < lines.length; i++) {
          const line = lines[i].trim();
          if (!line) continue;
          
          const values = line.split(',').map(v => v.trim());
          if (values.length < 7) continue;

          const firstName = values[headers.indexOf('firstname')] || '';
          const lastName = values[headers.indexOf('lastname')] || '';
          const email = values[headers.indexOf('email')] || '';
          const passwordRule = values[headers.indexOf('passwordrule')] || 'default';

          const user = {
            firstName,
            lastName,
            email,
            role: values[headers.indexOf('role')] || 'employee',
            companyId: values[headers.indexOf('companyid')] || selectedCompanyId || '',
            department: values[headers.indexOf('department')] || '',
            position: values[headers.indexOf('position')] || '',
            password: generatePassword(passwordRule, { firstName, lastName, email }),
            passwordRule
          };

          // Validate required fields
          if (user.firstName && user.lastName && user.email) {
            parsedUsers.push(user);
          }
        }

        if (parsedUsers.length === 0) {
          setCsvError('No valid users found in CSV file');
          return;
        }

        setNewUsers(parsedUsers);
        setSuccess(`Successfully imported ${parsedUsers.length} users from CSV`);
      } catch (error) {
        setCsvError('Error parsing CSV file');
        console.error('CSV parsing error:', error);
      }
    };
    reader.readAsText(file);
  };

  const clearCsvImport = () => {
    setCsvFile(null);
    setCsvError('');
    setNewUsers([]);
  };

  const handleBulkCreate = async () => {
    if (newUsers.length === 0) {
      setError('Please add at least one user');
      return;
    }

    const validUsers = newUsers.filter(user => 
      user.firstName && user.lastName && user.email && user.companyId
    );

    if (validUsers.length === 0) {
      setError('Please fill in required fields (First Name, Last Name, Email, Company)');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response: BulkOperationResponse = await apiService.post('/api/super-admin/users/bulk-create', {
        users: validUsers
      });

      setSuccess(`Successfully created ${response.results.successful.length} users`);
      setNewUsers([]);
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to create users');
    } finally {
      setLoading(false);
    }
  };

  // Bulk Update Functions
  const handleBulkUpdate = async () => {
    if (selectedUsers.length === 0) {
      setError('Please select users to update');
      return;
    }

    const updates = selectedUsers.map(userId => ({
      userId,
      ...(bulkUpdateData.role && { role: bulkUpdateData.role }),
      ...(bulkUpdateData.department && { department: bulkUpdateData.department }),
      ...(bulkUpdateData.position && { position: bulkUpdateData.position }),
      ...(bulkUpdateData.isActive !== '' && { isActive: bulkUpdateData.isActive === 'true' })
    })).filter(update => Object.keys(update).length > 1); // More than just userId

    if (updates.length === 0) {
      setError('Please provide at least one field to update');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response: BulkOperationResponse = await apiService.put('/api/super-admin/users/bulk-update', {
        updates
      });

      setSuccess(`Successfully updated ${response.results.successful.length} users`);
      setSelectedUsers([]);
      setBulkUpdateData({
        role: '',
        department: '',
        position: '',
        isActive: ''
      });
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update users');
    } finally {
      setLoading(false);
    }
  };

  // Bulk Delete Functions
  const handleBulkDelete = async () => {
    if (selectedUsers.length === 0) {
      setError('Please select users to delete');
      return;
    }

    if (!window.confirm(`Are you sure you want to delete ${selectedUsers.length} users? This action cannot be undone.`)) {
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response: BulkOperationResponse = await apiService.delete('/api/super-admin/users/bulk-delete', {
        data: { userIds: selectedUsers }
      });

      setSuccess(`Successfully deleted ${response.results.successful.length} users`);
      setSelectedUsers([]);
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete users');
    } finally {
      setLoading(false);
    }
  };

  const downloadTemplate = () => {
    const template = [
      'FirstName,LastName,Email,Role,CompanyId,Department,Position,PasswordRule',
      'John,Doe,john.doe@example.com,employee,company_id_here,IT,Developer,firstName+lastName',
      'Jane,Smith,jane.smith@example.com,admin,company_id_here,HR,Manager,email+123',
      'Bob,Wilson,bob@company.com,employee,company_id_here,Sales,Manager,default',
      'Alice,Johnson,alice@company.com,employee,company_id_here,Marketing,Coordinator,firstname123'
    ].join('\n');

    const blob = new Blob([template], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'user_import_template.csv';
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return '#1976d2';
      case 'employee': return '#388e3c';
      default: return '#757575';
    }
  };

  const getStatusColor = (isActive: boolean) => {
    return isActive ? '#4caf50' : '#f44336';
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Typography variant="h6">Bulk User Operations</Typography>
          <IconButton onClick={onClose}>
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2 }}>
          <Tabs value={tabValue} onChange={handleTabChange}>
            <Tab label="Bulk Create" />
            <Tab label="Bulk Update" />
            <Tab label="Bulk Delete" />
          </Tabs>
        </Box>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

        {/* Bulk Create Tab */}
        {tabValue === 0 && (
          <Box>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="h6">Create Multiple Users</Typography>
              <Box>
                <Button
                  startIcon={<DownloadIcon />}
                  onClick={downloadTemplate}
                  sx={{ mr: 1 }}
                >
                  Download Template
                </Button>
                <Button
                  startIcon={<FileUploadIcon />}
                  component="label"
                  sx={{ mr: 1 }}
                >
                  Import CSV
                  <input
                    type="file"
                    accept=".csv"
                    onChange={handleCsvFileChange}
                    style={{ display: 'none' }}
                  />
                </Button>
                <Button
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={addNewUserRow}
                >
                  Add User
                </Button>
              </Box>
            </Box>

                         {/* CSV Import Section */}
             {csvFile && (
               <Alert severity="info" sx={{ mb: 2 }}>
                 <Box display="flex" justifyContent="space-between" alignItems="center">
                   <Typography>
                     CSV File: {csvFile.name} ({newUsers.length} users imported)
                   </Typography>
                   <Button size="small" onClick={clearCsvImport}>
                     Clear
                   </Button>
                 </Box>
               </Alert>
             )}

             {/* Password Rules Help */}
             <Alert severity="info" sx={{ mb: 2 }}>
               <Typography variant="subtitle2" gutterBottom>
                 Password Generation Rules:
               </Typography>
               <Box component="ul" sx={{ mt: 1, mb: 0, pl: 2 }}>
                 <li><strong>firstName+lastName:</strong> john+doe</li>
                 <li><strong>email+123:</strong> john.doe@company.com+123</li>
                 <li><strong>firstName123:</strong> john123</li>
                 <li><strong>lastName123:</strong> doe123</li>
                 <li><strong>email:</strong> john.doe@company.com</li>
                 <li><strong>default:</strong> defaultPassword123</li>
               </Box>
             </Alert>

            {csvError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {csvError}
              </Alert>
            )}

            {newUsers.length > 0 && (
              <TableContainer component={Paper} sx={{ mb: 2 }}>
                <Table>
                                     <TableHead>
                     <TableRow>
                       <TableCell>First Name *</TableCell>
                       <TableCell>Last Name *</TableCell>
                       <TableCell>Email *</TableCell>
                       <TableCell>Role</TableCell>
                       <TableCell>Company *</TableCell>
                       <TableCell>Department</TableCell>
                       <TableCell>Position</TableCell>
                       <TableCell>Password Rule</TableCell>
                       <TableCell>Generated Password</TableCell>
                       <TableCell>Actions</TableCell>
                     </TableRow>
                   </TableHead>
                  <TableBody>
                    {newUsers.map((user, index) => (
                      <TableRow key={index}>
                        <TableCell>
                          <TextField
                            size="small"
                            value={user.firstName}
                            onChange={(e) => updateNewUser(index, 'firstName', e.target.value)}
                            placeholder="First Name"
                          />
                        </TableCell>
                        <TableCell>
                          <TextField
                            size="small"
                            value={user.lastName}
                            onChange={(e) => updateNewUser(index, 'lastName', e.target.value)}
                            placeholder="Last Name"
                          />
                        </TableCell>
                        <TableCell>
                          <TextField
                            size="small"
                            value={user.email}
                            onChange={(e) => updateNewUser(index, 'email', e.target.value)}
                            placeholder="Email"
                          />
                        </TableCell>
                        <TableCell>
                          <FormControl size="small" sx={{ minWidth: 120 }}>
                            <Select
                              value={user.role}
                              onChange={(e) => updateNewUser(index, 'role', e.target.value)}
                            >
                              <MenuItem value="employee">Employee</MenuItem>
                              <MenuItem value="admin">Admin</MenuItem>
                            </Select>
                          </FormControl>
                        </TableCell>
                        <TableCell>
                          <FormControl size="small" sx={{ minWidth: 150 }}>
                            <Select
                              value={user.companyId}
                              onChange={(e) => updateNewUser(index, 'companyId', e.target.value)}
                            >
                              {companies.map((company) => (
                                <MenuItem key={company._id} value={company._id}>
                                  {company.name}
                                </MenuItem>
                              ))}
                            </Select>
                          </FormControl>
                        </TableCell>
                        <TableCell>
                          <TextField
                            size="small"
                            value={user.department}
                            onChange={(e) => updateNewUser(index, 'department', e.target.value)}
                            placeholder="Department"
                          />
                        </TableCell>
                                                 <TableCell>
                           <TextField
                             size="small"
                             value={user.position}
                             onChange={(e) => updateNewUser(index, 'position', e.target.value)}
                             placeholder="Position"
                           />
                         </TableCell>
                         <TableCell>
                           <FormControl size="small" sx={{ minWidth: 120 }}>
                             <Select
                               value={user.passwordRule || 'default'}
                               onChange={(e) => {
                                 const newRule = e.target.value;
                                 const newPassword = generatePassword(newRule, {
                                   firstName: user.firstName,
                                   lastName: user.lastName,
                                   email: user.email
                                 });
                                 updateNewUser(index, 'passwordRule', newRule);
                                 updateNewUser(index, 'password', newPassword);
                               }}
                             >
                               <MenuItem value="firstName+lastName">firstName+lastName</MenuItem>
                               <MenuItem value="email+123">email+123</MenuItem>
                               <MenuItem value="firstName123">firstName123</MenuItem>
                               <MenuItem value="lastName123">lastName123</MenuItem>
                               <MenuItem value="email">email</MenuItem>
                               <MenuItem value="default">default</MenuItem>
                             </Select>
                           </FormControl>
                         </TableCell>
                         <TableCell>
                           <TextField
                             size="small"
                             value={user.password}
                             onChange={(e) => updateNewUser(index, 'password', e.target.value)}
                             placeholder="Password"
                             type="text"
                             sx={{ minWidth: 150 }}
                           />
                         </TableCell>
                         <TableCell>
                           <IconButton
                             size="small"
                             onClick={() => removeNewUser(index)}
                             color="error"
                           >
                             <DeleteIcon />
                           </IconButton>
                         </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}

            <Box display="flex" justifyContent="flex-end" gap={1}>
              <Button onClick={onClose}>Cancel</Button>
              <Button
                variant="contained"
                onClick={handleBulkCreate}
                disabled={loading || newUsers.length === 0}
                startIcon={loading ? <CircularProgress size={20} /> : <AddIcon />}
              >
                {loading ? 'Creating...' : 'Create Users'}
              </Button>
            </Box>
          </Box>
        )}

        {/* Bulk Update Tab */}
        {tabValue === 1 && (
          <Box>
            <Typography variant="h6" gutterBottom>Update Selected Users</Typography>
            
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="body2">
                {selectedUsers.length} user(s) selected
              </Typography>
              <Button
                startIcon={<ClearIcon />}
                onClick={handleClearSelection}
                disabled={selectedUsers.length === 0}
              >
                Clear Selection
              </Button>
            </Box>

            <Box sx={{ mb: 3 }}>
              <Typography variant="subtitle1" gutterBottom>Update Fields:</Typography>
              <Box display="flex" gap={2} flexWrap="wrap">
                <FormControl sx={{ minWidth: 120 }}>
                  <InputLabel>Role</InputLabel>
                  <Select
                    value={bulkUpdateData.role}
                    onChange={(e) => setBulkUpdateData(prev => ({ ...prev, role: e.target.value }))}
                    label="Role"
                  >
                    <MenuItem value="">No Change</MenuItem>
                    <MenuItem value="admin">Admin</MenuItem>
                    <MenuItem value="employee">Employee</MenuItem>
                  </Select>
                </FormControl>
                
                <TextField
                  label="Department"
                  value={bulkUpdateData.department}
                  onChange={(e) => setBulkUpdateData(prev => ({ ...prev, department: e.target.value }))}
                  placeholder="Leave empty for no change"
                />
                
                <TextField
                  label="Position"
                  value={bulkUpdateData.position}
                  onChange={(e) => setBulkUpdateData(prev => ({ ...prev, position: e.target.value }))}
                  placeholder="Leave empty for no change"
                />
                
                <FormControl sx={{ minWidth: 120 }}>
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={bulkUpdateData.isActive}
                    onChange={(e) => setBulkUpdateData(prev => ({ ...prev, isActive: e.target.value }))}
                    label="Status"
                  >
                    <MenuItem value="">No Change</MenuItem>
                    <MenuItem value="true">Active</MenuItem>
                    <MenuItem value="false">Inactive</MenuItem>
                  </Select>
                </FormControl>
              </Box>
            </Box>

            <Box display="flex" justifyContent="flex-end" gap={1}>
              <Button onClick={onClose}>Cancel</Button>
              <Button
                variant="contained"
                onClick={handleBulkUpdate}
                disabled={loading || selectedUsers.length === 0}
                startIcon={loading ? <CircularProgress size={20} /> : <EditIcon />}
              >
                {loading ? 'Updating...' : 'Update Users'}
              </Button>
            </Box>
          </Box>
        )}

        {/* Bulk Delete Tab */}
        {tabValue === 2 && (
          <Box>
            <Typography variant="h6" gutterBottom>Delete Selected Users</Typography>
            
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="body2">
                {selectedUsers.length} user(s) selected
              </Typography>
              <Button
                startIcon={<ClearIcon />}
                onClick={handleClearSelection}
                disabled={selectedUsers.length === 0}
              >
                Clear Selection
              </Button>
            </Box>

            {selectedUsers.length > 0 && (
              <TableContainer component={Paper} sx={{ mb: 2 }}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell padding="checkbox">
                        <Checkbox
                          checked={selectedUsers.length === users.length}
                          indeterminate={selectedUsers.length > 0 && selectedUsers.length < users.length}
                          onChange={handleSelectAll}
                        />
                      </TableCell>
                      <TableCell>Name</TableCell>
                      <TableCell>Email</TableCell>
                      <TableCell>Role</TableCell>
                      <TableCell>Company</TableCell>
                      <TableCell>Status</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {users.map((user) => (
                      <TableRow key={user._id}>
                        <TableCell padding="checkbox">
                          <Checkbox
                            checked={selectedUsers.includes(user._id)}
                            onChange={() => handleUserSelection(user._id)}
                          />
                        </TableCell>
                        <TableCell>
                          {user.firstName} {user.lastName}
                        </TableCell>
                        <TableCell>{user.email}</TableCell>
                        <TableCell>
                          <Chip
                            label={user.role}
                            size="small"
                            sx={{
                              backgroundColor: getRoleColor(user.role),
                              color: 'white'
                            }}
                          />
                        </TableCell>
                        <TableCell>
                          {user.companyId?.name || 'No Company'}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={user.isActive ? 'Active' : 'Inactive'}
                            size="small"
                            sx={{
                              backgroundColor: getStatusColor(user.isActive),
                              color: 'white'
                            }}
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}

            <Box display="flex" justifyContent="flex-end" gap={1}>
              <Button onClick={onClose}>Cancel</Button>
              <Button
                variant="contained"
                color="error"
                onClick={handleBulkDelete}
                disabled={loading || selectedUsers.length === 0}
                startIcon={loading ? <CircularProgress size={20} /> : <DeleteIcon />}
              >
                {loading ? 'Deleting...' : 'Delete Users'}
              </Button>
            </Box>
          </Box>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default BulkUserOperations; 