import React, { useState, useEffect } from 'react';
import {
  Typography,
  Button,
  Paper,
  Box,
  TextField,
  Alert,
  CircularProgress,
  Chip,
  Card,
  CardContent,
  IconButton,
  Tooltip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem
} from '@mui/material';

import {
  DataGrid,
  GridColDef,
  GridActionsCellItem,
  GridToolbar,
  GridRowSelectionModel,
} from '@mui/x-data-grid';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  GroupAdd as GroupAddIcon,
  Visibility as ViewIcon,
  Person as PersonIcon,
  Email as EmailIcon,
  Business as BusinessIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';
import BulkEmployeeOperations from '../components/BulkEmployeeOperations';

interface Employee {
  _id: string;
  firstName?: string;
  lastName?: string;
  name?: string; // Alternative field name
  email: string;
  position?: string;
  jobTitle?: string; // Alternative field name
  title?: string; // Alternative field name
  department?: string;
  dept?: string; // Alternative field name
  employeeType?: string;
  type?: string; // Alternative field name
  employeeSubType?: string; // Alternative field name
  employeeId?: string;
  hireDate?: string;
  hourlyRate?: number;
  monthlySalary?: number;
  isActive?: boolean;
  createdAt: string;
  updatedAt: string;
  // Additional fields that might be present
  userId?: string;
  companyId?: string;
  performanceLevel?: string;
  skills?: string[];
  certifications?: any[];
}

const EmployeeManagementPage: React.FC = () => {
  const [employees, setEmployees] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedEmployees, setSelectedEmployees] = useState<GridRowSelectionModel>({ type: 'include', ids: new Set() });
  const [bulkOperationsOpen, setBulkOperationsOpen] = useState(false);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [addDialogOpen, setAddDialogOpen] = useState(false);
  const [selectedEmployee, setSelectedEmployee] = useState<any | null>(null);
  const [editingEmployee, setEditingEmployee] = useState<any>({});
  const [newEmployee, setNewEmployee] = useState<any>({});
  const [companies, setCompanies] = useState<any[]>([]);
  const [selectedCompanyId, setSelectedCompanyId] = useState<string>('');
  const [showInactive, setShowInactive] = useState(false); // Add this state
  const [allEmployees, setAllEmployees] = useState<any[]>([]); // For stats calculation

  useEffect(() => {
    fetchCompanies();
  }, []);

  useEffect(() => {
    if (selectedCompanyId) {
      fetchEmployees();
    }
  }, [selectedCompanyId, showInactive]);

  const fetchCompanies = async () => {
    try {
      // Use super admin endpoint for companies
      const response = await apiService.get<any>('/api/super-admin/companies');
      const companies = response.companies || [];
      setCompanies(companies);
      // Auto-select first company if available
      if (companies.length > 0) {
        setSelectedCompanyId(companies[0]._id);
      }
    } catch (err: any) {
      console.error('Error fetching companies:', err);
      setError('Failed to fetch companies');
    }
  };

  const fetchEmployees = async () => {
    setLoading(true);
    setError('');
    try {
      // Use selected company ID or fallback to localStorage
      const companyId = selectedCompanyId || localStorage.getItem('companyId');
             const user = localStorage.getItem('user');
      
      if (!companyId) {
        setError('Please select a company to view employees');
        setLoading(false);
        return;
      }
      
      // Use super admin endpoint for employees with showInactive parameter
      const response = await apiService.get<any[]>(`/api/super-admin/employees/${companyId}?showInactive=${showInactive}`);
      setEmployees(response);
      
      // Also fetch all employees for stats calculation
      const allEmployeesResponse = await apiService.get<any[]>(`/api/super-admin/employees/${companyId}?showInactive=true`);
      setAllEmployees(allEmployeesResponse);
         } catch (err: any) {
       console.error('Error fetching employees:', err);
       setError(err.response?.data?.message || 'Failed to fetch employees');
     } finally {
      setLoading(false);
    }
  };

  const handleViewEmployee = (employee: any) => {
    setSelectedEmployee(employee);
    setViewDialogOpen(true);
  };

  const handleEditEmployee = (employee: any) => {
    setEditingEmployee({
      firstName: employee.firstName || '',
      lastName: employee.lastName || '',
      email: employee.email || '',
      position: employee.position || '',
      department: employee.department || '',
      employeeType: employee.employeeType || 'Permanent',
      employeeId: employee.employeeId || '',
      hourlyRate: employee.hourlyRate || 0,
      monthlySalary: employee.monthlySalary || 0,
      isActive: employee.isActive !== false,
      _id: employee._id
    });
    setEditDialogOpen(true);
  };

  const handleSaveEmployee = async () => {
    try {
      await apiService.put(`/api/super-admin/employees/${editingEmployee._id}`, editingEmployee);
      setSuccessMessage('Employee updated successfully');
      setEditDialogOpen(false);
      fetchEmployees();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update employee');
    }
  };

  const handleAddEmployee = () => {
    // Ensure we have a company selected
    if (!selectedCompanyId) {
      setError('Please select a company first');
      return;
    }
    
    setNewEmployee({
      firstName: '',
      lastName: '',
      email: '',
      position: '',
      department: '',
      employeeType: 'Permanent',
      employeeId: '',
      hourlyRate: 0,
      monthlySalary: 0,
      isActive: true
    });
    setAddDialogOpen(true);
  };

  const handleSaveNewEmployee = async () => {
    try {
      console.log('DEBUG: Adding employee with data:', newEmployee);
      console.log('DEBUG: Company ID:', selectedCompanyId);
      
      const response = await apiService.post(`/api/super-admin/employees/${selectedCompanyId}`, newEmployee);
      console.log('DEBUG: Add employee response:', response);
      
      setSuccessMessage('Employee added successfully');
      setAddDialogOpen(false);
      fetchEmployees();
    } catch (err: any) {
      console.error('DEBUG: Add employee error:', err);
      setError(err.response?.data?.message || 'Failed to add employee');
    }
  };

  const handleDeleteEmployee = async (employee: any) => {
    const firstName = employee.firstName || employee.name || 'Unknown';
    const lastName = employee.lastName || '';
    if (!window.confirm(`Are you sure you want to delete ${firstName} ${lastName}?`)) {
      return;
    }

    try {
      await apiService.delete(`/api/super-admin/employees/${employee._id}`);
      setSuccessMessage('Employee deleted successfully');
      fetchEmployees();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete employee');
    }
  };

  const handleBulkOperationsSuccess = () => {
    setBulkOperationsOpen(false);
    setSuccessMessage('Bulk operation completed successfully');
    fetchEmployees();
  };

  const filteredEmployees = employees.filter(employee =>
    `${employee.firstName} ${employee.lastName} ${employee.email} ${employee.position || ''} ${employee.department || ''}`
      .toLowerCase()
      .includes(searchTerm.toLowerCase())
  );



  const columns: GridColDef<any>[] = [
    {
      field: 'name',
      headerName: 'Name',
      flex: 1,
      renderCell: (params: any) => {
        const firstName = params.row.firstName || '';
        const lastName = params.row.lastName || '';
        const fullName = `${firstName} ${lastName}`.trim();
        return (
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <PersonIcon sx={{ color: 'action.active' }} />
            <Typography>{fullName || 'No Name'}</Typography>
          </Box>
        );
      },
    },
    {
      field: 'email',
      headerName: 'Email',
      flex: 1,
      renderCell: (params: any) => (
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <EmailIcon sx={{ color: 'action.active' }} />
          <Typography>{params.value || 'No Email'}</Typography>
        </Box>
      ),
    },
    {
      field: 'position',
      headerName: 'Position',
      flex: 1,
      renderCell: (params: any) => {
        const position = params.row.position || '-';
        return <Typography>{position}</Typography>;
      },
    },
    {
      field: 'department',
      headerName: 'Department',
      flex: 1,
      renderCell: (params: any) => {
        const department = params.row.department || '-';
        return <Typography>{department}</Typography>;
      },
    },
    {
      field: 'employeeType',
      headerName: 'Type',
      flex: 0.8,
      renderCell: (params: any) => {
        const type = params.row.employeeType || '-';
        return <Typography>{type}</Typography>;
      },
    },
    {
      field: 'isActive',
      headerName: 'Status',
      flex: 0.8,
      renderCell: (params: any) => {
        if (!params || !params.row) return <Chip label="Unknown" size="small" />;
        const isActive = params.row.isActive !== false; // Default to true if not explicitly false
        return (
          <Chip
            label={isActive ? 'Active' : 'Inactive'}
            color={isActive ? 'success' : 'default'}
            size="small"
          />
        );
      },
    },
    {
      field: 'actions',
      headerName: 'Actions',
      type: 'actions',
      flex: 1,
      getActions: (params: any) => {
        if (!params || !params.row) return [];
        return [
          <GridActionsCellItem
            key="view"
            icon={<ViewIcon />}
            label="View"
            onClick={() => handleViewEmployee(params.row)}
          />,
          <GridActionsCellItem
            key="edit"
            icon={<EditIcon />}
            label="Edit"
            onClick={() => handleEditEmployee(params.row)}
          />,
          <GridActionsCellItem
            key="delete"
            icon={<DeleteIcon />}
            label="Delete"
            onClick={() => handleDeleteEmployee(params.row)}
          />,
        ];
      },
    },
  ];

  // Calculate stats based on all employees (not just filtered ones)
  const stats = {
    total: allEmployees.length,
    active: allEmployees.filter(emp => emp.isActive !== false).length,
    inactive: allEmployees.filter(emp => emp.isActive === false).length,
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Employee Management
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
                     <Button
             variant="outlined"
             startIcon={<AddIcon />}
             onClick={handleAddEmployee}
           >
             Add Employee
           </Button>
          <Button
            variant="contained"
            startIcon={<GroupAddIcon />}
            onClick={() => setBulkOperationsOpen(true)}
          >
            Bulk Operations
          </Button>
        </Box>
      </Box>

      {/* Stats Cards */}
      <Box sx={{ display: 'flex', gap: 3, mb: 3, flexWrap: 'wrap' }}>
        <Card sx={{ flex: '1 1 300px', minWidth: 0 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <PersonIcon sx={{ fontSize: 40, color: 'primary.main' }} />
              <Box>
                <Typography variant="h4" component="div">
                  {stats.total}
                </Typography>
                <Typography color="text.secondary">
                  Total Employees
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
        <Card sx={{ flex: '1 1 300px', minWidth: 0 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <PersonIcon sx={{ fontSize: 40, color: 'success.main' }} />
              <Box>
                <Typography variant="h4" component="div">
                  {stats.active}
                </Typography>
                <Typography color="text.secondary">
                  Active Employees
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
        <Card sx={{ flex: '1 1 300px', minWidth: 0 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <PersonIcon sx={{ fontSize: 40, color: 'warning.main' }} />
              <Box>
                <Typography variant="h4" component="div">
                  {stats.inactive}
                </Typography>
                <Typography color="text.secondary">
                  Inactive Employees
                </Typography>
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* Messages */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
          {error}
        </Alert>
      )}

      {successMessage && (
        <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccessMessage('')}>
          {successMessage}
        </Alert>
      )}

             {/* Company Selector and Search */}
       <Paper sx={{ p: 2, mb: 2 }}>
         <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
           <FormControl sx={{ minWidth: 200 }}>
             <InputLabel>Select Company</InputLabel>
             <Select
               value={selectedCompanyId}
               onChange={(e) => setSelectedCompanyId(e.target.value)}
               label="Select Company"
             >
               {companies.map((company) => (
                 <MenuItem key={company._id} value={company._id}>
                   {company.name}
                 </MenuItem>
               ))}
             </Select>
           </FormControl>
           <TextField
             sx={{ flex: 1, minWidth: 200 }}
             label="Search employees..."
             value={searchTerm}
             onChange={(e) => setSearchTerm(e.target.value)}
             InputProps={{
               startAdornment: <BusinessIcon sx={{ mr: 1, color: 'action.active' }} />,
             }}
           />
           <FormControl sx={{ minWidth: 150 }}>
             <InputLabel>Status Filter</InputLabel>
             <Select
               value={showInactive ? 'all' : 'active'}
               onChange={(e) => setShowInactive(e.target.value === 'all')}
               label="Status Filter"
             >
               <MenuItem value="active">Active Only</MenuItem>
               <MenuItem value="all">All Employees</MenuItem>
             </Select>
           </FormControl>
         </Box>
       </Paper>

             {/* Employee Data Grid */}
       <Paper sx={{ height: 600, width: '100%' }}>
         <DataGrid
           key={`employees-${selectedCompanyId}-${employees.length}`}
           rows={filteredEmployees}
           columns={columns}
           loading={loading}
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
           pageSizeOptions={[10, 25, 50, 100]}
           initialState={{
             pagination: {
               paginationModel: { page: 0, pageSize: 25 },
             },
           }}
           rowSelectionModel={selectedEmployees}
           onRowSelectionModelChange={setSelectedEmployees}
           disableRowSelectionOnClick
         />
       </Paper>

             {/* Bulk Operations Dialog */}
       <BulkEmployeeOperations
         open={bulkOperationsOpen}
         onClose={() => setBulkOperationsOpen(false)}
         onSuccess={handleBulkOperationsSuccess}
         employees={employees}
         companyId={selectedCompanyId}
       />

             {/* View Employee Dialog */}
       <Dialog open={viewDialogOpen} onClose={() => setViewDialogOpen(false)} maxWidth="md" fullWidth>
         <DialogTitle>
           Employee Details
         </DialogTitle>
                  <DialogContent>
            {selectedEmployee && (
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2 }}>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Name</Typography>
                  <Typography variant="body1">{`${selectedEmployee.firstName} ${selectedEmployee.lastName}`}</Typography>
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Email</Typography>
                  <Typography variant="body1">{selectedEmployee.email}</Typography>
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Position</Typography>
                  <Typography variant="body1">{selectedEmployee.position || '-'}</Typography>
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Department</Typography>
                  <Typography variant="body1">{selectedEmployee.department || '-'}</Typography>
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Employee Type</Typography>
                  <Typography variant="body1">{selectedEmployee.employeeType || '-'}</Typography>
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Employee ID</Typography>
                  <Typography variant="body1">{selectedEmployee.employeeId || '-'}</Typography>
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Status</Typography>
                  <Chip
                    label={selectedEmployee.isActive ? 'Active' : 'Inactive'}
                    color={selectedEmployee.isActive ? 'success' : 'default'}
                    size="small"
                  />
                </Box>
                <Box sx={{ flex: '1 1 300px', minWidth: 0 }}>
                  <Typography variant="subtitle2" color="text.secondary">Created</Typography>
                  <Typography variant="body1">
                    {new Date(selectedEmployee.createdAt).toLocaleDateString()}
                  </Typography>
                </Box>
              </Box>
            )}
          </DialogContent>
         <DialogActions>
           <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
         </DialogActions>
       </Dialog>

       {/* Edit Employee Dialog */}
       <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="md" fullWidth>
         <DialogTitle>
           Edit Employee
         </DialogTitle>
         <DialogContent>
           <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mt: 1 }}>
             <TextField
               label="First Name"
               value={editingEmployee.firstName || ''}
               onChange={(e) => setEditingEmployee({...editingEmployee, firstName: e.target.value})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <TextField
               label="Last Name"
               value={editingEmployee.lastName || ''}
               onChange={(e) => setEditingEmployee({...editingEmployee, lastName: e.target.value})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <TextField
               label="Email"
               value={editingEmployee.email || ''}
               onChange={(e) => setEditingEmployee({...editingEmployee, email: e.target.value})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <TextField
               label="Position"
               value={editingEmployee.position || ''}
               onChange={(e) => setEditingEmployee({...editingEmployee, position: e.target.value})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <TextField
               label="Department"
               value={editingEmployee.department || ''}
               onChange={(e) => setEditingEmployee({...editingEmployee, department: e.target.value})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <FormControl fullWidth sx={{ flex: '1 1 200px' }}>
               <InputLabel>Employee Type</InputLabel>
               <Select
                 value={editingEmployee.employeeType || 'Permanent'}
                 onChange={(e) => setEditingEmployee({...editingEmployee, employeeType: e.target.value})}
                 label="Employee Type"
               >
                 <MenuItem value="Permanent">Permanent</MenuItem>
                 <MenuItem value="Temporary">Temporary</MenuItem>
               </Select>
             </FormControl>
             <TextField
               label="Employee ID"
               value={editingEmployee.employeeId || ''}
               onChange={(e) => setEditingEmployee({...editingEmployee, employeeId: e.target.value})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <TextField
               label="Hourly Rate"
               type="number"
               value={editingEmployee.hourlyRate || 0}
               onChange={(e) => setEditingEmployee({...editingEmployee, hourlyRate: parseFloat(e.target.value) || 0})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <TextField
               label="Monthly Salary"
               type="number"
               value={editingEmployee.monthlySalary || 0}
               onChange={(e) => setEditingEmployee({...editingEmployee, monthlySalary: parseFloat(e.target.value) || 0})}
               fullWidth
               sx={{ flex: '1 1 200px' }}
             />
             <FormControl fullWidth sx={{ flex: '1 1 200px' }}>
               <InputLabel>Status</InputLabel>
               <Select
                 value={editingEmployee.isActive ? 'active' : 'inactive'}
                 onChange={(e) => setEditingEmployee({...editingEmployee, isActive: e.target.value === 'active'})}
                 label="Status"
               >
                 <MenuItem value="active">Active</MenuItem>
                 <MenuItem value="inactive">Inactive</MenuItem>
               </Select>
             </FormControl>
           </Box>
         </DialogContent>
         <DialogActions>
           <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
           <Button onClick={handleSaveEmployee} variant="contained">Save Changes</Button>
                   </DialogActions>
        </Dialog>

        {/* Add Employee Dialog */}
        <Dialog open={addDialogOpen} onClose={() => setAddDialogOpen(false)} maxWidth="md" fullWidth>
          <DialogTitle>
            Add New Employee
          </DialogTitle>
          <DialogContent>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mt: 1 }}>
              <FormControl fullWidth sx={{ flex: '1 1 200px' }}>
                <InputLabel>Company *</InputLabel>
                <Select
                  value={selectedCompanyId}
                  onChange={(e) => setSelectedCompanyId(e.target.value)}
                  label="Company *"
                  required
                >
                  {companies.map((company) => (
                    <MenuItem key={company._id} value={company._id}>
                      {company.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              <TextField
                label="First Name *"
                value={newEmployee.firstName || ''}
                onChange={(e) => setNewEmployee({...newEmployee, firstName: e.target.value})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
                required
              />
              <TextField
                label="Last Name *"
                value={newEmployee.lastName || ''}
                onChange={(e) => setNewEmployee({...newEmployee, lastName: e.target.value})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
                required
              />
              <TextField
                label="Email *"
                value={newEmployee.email || ''}
                onChange={(e) => setNewEmployee({...newEmployee, email: e.target.value})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
                required
              />
              <TextField
                label="Position"
                value={newEmployee.position || ''}
                onChange={(e) => setNewEmployee({...newEmployee, position: e.target.value})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
              />
              <TextField
                label="Department"
                value={newEmployee.department || ''}
                onChange={(e) => setNewEmployee({...newEmployee, department: e.target.value})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
              />
              <FormControl fullWidth sx={{ flex: '1 1 200px' }}>
                <InputLabel>Employee Type</InputLabel>
                <Select
                  value={newEmployee.employeeType || 'Permanent'}
                  onChange={(e) => setNewEmployee({...newEmployee, employeeType: e.target.value})}
                  label="Employee Type"
                >
                  <MenuItem value="Permanent">Permanent</MenuItem>
                  <MenuItem value="Temporary">Temporary</MenuItem>
                </Select>
              </FormControl>
              <TextField
                label="Employee ID"
                value={newEmployee.employeeId || ''}
                onChange={(e) => setNewEmployee({...newEmployee, employeeId: e.target.value})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
              />
              <TextField
                label="Hourly Rate"
                type="number"
                value={newEmployee.hourlyRate || 0}
                onChange={(e) => setNewEmployee({...newEmployee, hourlyRate: parseFloat(e.target.value) || 0})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
              />
              <TextField
                label="Monthly Salary"
                type="number"
                value={newEmployee.monthlySalary || 0}
                onChange={(e) => setNewEmployee({...newEmployee, monthlySalary: parseFloat(e.target.value) || 0})}
                fullWidth
                sx={{ flex: '1 1 200px' }}
              />
              <FormControl fullWidth sx={{ flex: '1 1 200px' }}>
                <InputLabel>Status</InputLabel>
                <Select
                  value={newEmployee.isActive ? 'active' : 'inactive'}
                  onChange={(e) => setNewEmployee({...newEmployee, isActive: e.target.value === 'active'})}
                  label="Status"
                >
                  <MenuItem value="active">Active</MenuItem>
                  <MenuItem value="inactive">Inactive</MenuItem>
                </Select>
              </FormControl>
            </Box>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setAddDialogOpen(false)}>Cancel</Button>
                         <Button 
               onClick={handleSaveNewEmployee} 
               variant="contained"
               disabled={!selectedCompanyId || !newEmployee.firstName || !newEmployee.lastName || !newEmployee.email}
             >
               Add Employee
             </Button>
          </DialogActions>
        </Dialog>
     </Box>
   );
 };

export default EmployeeManagementPage; 