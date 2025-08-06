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
  Divider
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Download as DownloadIcon,
  Upload as UploadIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Close as CloseIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

interface Employee {
  _id: string;
  firstName: string;
  lastName: string;
  email: string;
  position?: string;
  department?: string;
  employeeType?: string;
  employeeId?: string;
  hireDate?: string;
  hourlyRate?: number;
  monthlySalary?: number;
}

interface BulkEmployeeOperationsProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  employees: Employee[];
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`bulk-tabpanel-${index}`}
      aria-labelledby={`bulk-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const BulkEmployeeOperations: React.FC<BulkEmployeeOperationsProps> = ({
  open,
  onClose,
  onSuccess,
  employees
}) => {
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [selectedEmployees, setSelectedEmployees] = useState<string[]>([]);
  const [bulkUpdateData, setBulkUpdateData] = useState({
    position: '',
    department: '',
    employeeType: '',
    hourlyRate: '',
    monthlySalary: ''
  });

  // Bulk Create State
  const [newEmployees, setNewEmployees] = useState<Array<{
    firstName: string;
    lastName: string;
    email: string;
    position: string;
    department: string;
    employeeType: string;
    employeeId: string;
    password: string;
  }>>([]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
    setError('');
    setSuccess('');
  };

  const handleEmployeeSelection = (employeeId: string) => {
    setSelectedEmployees(prev => 
      prev.includes(employeeId) 
        ? prev.filter(id => id !== employeeId)
        : [...prev, employeeId]
    );
  };

  const handleSelectAll = () => {
    if (selectedEmployees.length === employees.length) {
      setSelectedEmployees([]);
    } else {
      setSelectedEmployees(employees.map(emp => emp._id));
    }
  };

  // Bulk Create Functions
  const addNewEmployeeRow = () => {
    setNewEmployees(prev => [...prev, {
      firstName: '',
      lastName: '',
      email: '',
      position: '',
      department: '',
      employeeType: 'Full-time',
      employeeId: '',
      password: 'defaultPassword123'
    }]);
  };

  const updateNewEmployee = (index: number, field: string, value: string) => {
    setNewEmployees(prev => prev.map((emp, i) => 
      i === index ? { ...emp, [field]: value } : emp
    ));
  };

  const removeNewEmployee = (index: number) => {
    setNewEmployees(prev => prev.filter((_, i) => i !== index));
  };

  const handleBulkCreate = async () => {
    if (newEmployees.length === 0) {
      setError('Please add at least one employee');
      return;
    }

    const validEmployees = newEmployees.filter(emp => 
      emp.firstName && emp.lastName && emp.email
    );

    if (validEmployees.length === 0) {
      setError('Please fill in required fields (First Name, Last Name, Email)');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await apiService.post('/api/employees/bulk-create', {
        employees: validEmployees
      });

      setSuccess(`Successfully created ${response.results.successful.length} employees`);
      setNewEmployees([]);
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to create employees');
    } finally {
      setLoading(false);
    }
  };

  // Bulk Update Functions
  const handleBulkUpdate = async () => {
    if (selectedEmployees.length === 0) {
      setError('Please select employees to update');
      return;
    }

    const updates = selectedEmployees.map(employeeId => ({
      employeeId,
      updates: {
        ...(bulkUpdateData.position && { position: bulkUpdateData.position }),
        ...(bulkUpdateData.department && { department: bulkUpdateData.department }),
        ...(bulkUpdateData.employeeType && { employeeType: bulkUpdateData.employeeType }),
        ...(bulkUpdateData.hourlyRate && { hourlyRate: parseFloat(bulkUpdateData.hourlyRate) }),
        ...(bulkUpdateData.monthlySalary && { monthlySalary: parseFloat(bulkUpdateData.monthlySalary) })
      }
    })).filter(update => Object.keys(update.updates).length > 0);

    if (updates.length === 0) {
      setError('Please provide at least one field to update');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await apiService.put('/api/employees/bulk-update', {
        updates
      });

      setSuccess(`Successfully updated ${response.results.successful.length} employees`);
      setSelectedEmployees([]);
      setBulkUpdateData({
        position: '',
        department: '',
        employeeType: '',
        hourlyRate: '',
        monthlySalary: ''
      });
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update employees');
    } finally {
      setLoading(false);
    }
  };

  // Bulk Delete Functions
  const handleBulkDelete = async () => {
    if (selectedEmployees.length === 0) {
      setError('Please select employees to delete');
      return;
    }

    if (!window.confirm(`Are you sure you want to delete ${selectedEmployees.length} employees? This action cannot be undone.`)) {
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await apiService.delete('/api/employees/bulk-delete', {
        data: { employeeIds: selectedEmployees }
      });

      setSuccess(`Successfully deleted ${response.results.successful.length} employees`);
      setSelectedEmployees([]);
      onSuccess();
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete employees');
    } finally {
      setLoading(false);
    }
  };

  const downloadTemplate = () => {
    const template = [
      'firstName,lastName,email,position,department,employeeType,employeeId',
      'John,Doe,john.doe@example.com,Developer,IT,Full-time,EMP001',
      'Jane,Smith,jane.smith@example.com,Manager,HR,Full-time,EMP002'
    ].join('\n');

    const blob = new Blob([template], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'employee_template.csv';
    a.click();
    window.URL.revokeObjectURL(url);
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box display="flex" justifyContent="space-between" alignItems="center">
          <Typography variant="h6">Bulk Employee Operations</Typography>
          <IconButton onClick={onClose}>
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={tabValue} onChange={handleTabChange}>
            <Tab label="Bulk Create" />
            <Tab label="Bulk Update" />
            <Tab label="Bulk Delete" />
          </Tabs>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mt: 2 }}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mt: 2 }}>
            {success}
          </Alert>
        )}

        <TabPanel value={tabValue} index={0}>
          <Box>
            <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
              <Typography variant="h6">Add Multiple Employees</Typography>
              <Box>
                <Button
                  startIcon={<DownloadIcon />}
                  onClick={downloadTemplate}
                  sx={{ mr: 1 }}
                >
                  Download Template
                </Button>
                <Button
                  startIcon={<AddIcon />}
                  onClick={addNewEmployeeRow}
                  variant="contained"
                >
                  Add Row
                </Button>
              </Box>
            </Box>

            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>First Name *</TableCell>
                    <TableCell>Last Name *</TableCell>
                    <TableCell>Email *</TableCell>
                    <TableCell>Position</TableCell>
                    <TableCell>Department</TableCell>
                    <TableCell>Employee Type</TableCell>
                    <TableCell>Employee ID</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {newEmployees.map((employee, index) => (
                    <TableRow key={index}>
                      <TableCell>
                        <TextField
                          size="small"
                          value={employee.firstName}
                          onChange={(e) => updateNewEmployee(index, 'firstName', e.target.value)}
                          placeholder="First Name"
                        />
                      </TableCell>
                      <TableCell>
                        <TextField
                          size="small"
                          value={employee.lastName}
                          onChange={(e) => updateNewEmployee(index, 'lastName', e.target.value)}
                          placeholder="Last Name"
                        />
                      </TableCell>
                      <TableCell>
                        <TextField
                          size="small"
                          value={employee.email}
                          onChange={(e) => updateNewEmployee(index, 'email', e.target.value)}
                          placeholder="Email"
                          type="email"
                        />
                      </TableCell>
                      <TableCell>
                        <TextField
                          size="small"
                          value={employee.position}
                          onChange={(e) => updateNewEmployee(index, 'position', e.target.value)}
                          placeholder="Position"
                        />
                      </TableCell>
                      <TableCell>
                        <TextField
                          size="small"
                          value={employee.department}
                          onChange={(e) => updateNewEmployee(index, 'department', e.target.value)}
                          placeholder="Department"
                        />
                      </TableCell>
                      <TableCell>
                        <FormControl size="small" fullWidth>
                          <Select
                            value={employee.employeeType}
                            onChange={(e) => updateNewEmployee(index, 'employeeType', e.target.value)}
                          >
                            <MenuItem value="Full-time">Full-time</MenuItem>
                            <MenuItem value="Part-time">Part-time</MenuItem>
                            <MenuItem value="Contract">Contract</MenuItem>
                            <MenuItem value="Intern">Intern</MenuItem>
                          </Select>
                        </FormControl>
                      </TableCell>
                      <TableCell>
                        <TextField
                          size="small"
                          value={employee.employeeId}
                          onChange={(e) => updateNewEmployee(index, 'employeeId', e.target.value)}
                          placeholder="Employee ID"
                        />
                      </TableCell>
                      <TableCell>
                        <IconButton
                          onClick={() => removeNewEmployee(index)}
                          color="error"
                          size="small"
                        >
                          <DeleteIcon />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            {newEmployees.length === 0 && (
              <Box textAlign="center" py={4}>
                <Typography color="textSecondary">
                  Click "Add Row" to start adding employees
                </Typography>
              </Box>
            )}
          </Box>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Box>
            <Typography variant="h6" mb={2}>Update Multiple Employees</Typography>
            
            <Box mb={3}>
              <Typography variant="subtitle2" mb={1}>
                Select employees to update:
              </Typography>
              <Box display="flex" gap={1} mb={2}>
                <Button
                  size="small"
                  onClick={handleSelectAll}
                  variant="outlined"
                >
                  {selectedEmployees.length === employees.length ? 'Deselect All' : 'Select All'}
                </Button>
                <Chip 
                  label={`${selectedEmployees.length} selected`} 
                  color="primary" 
                  variant="outlined"
                />
              </Box>
            </Box>

            <Box display="grid" gridTemplateColumns="repeat(auto-fit, minmax(200px, 1fr))" gap={2} mb={3}>
              <TextField
                label="Position"
                value={bulkUpdateData.position}
                onChange={(e) => setBulkUpdateData(prev => ({ ...prev, position: e.target.value }))}
                placeholder="Leave empty to skip"
              />
              <TextField
                label="Department"
                value={bulkUpdateData.department}
                onChange={(e) => setBulkUpdateData(prev => ({ ...prev, department: e.target.value }))}
                placeholder="Leave empty to skip"
              />
              <FormControl>
                <InputLabel>Employee Type</InputLabel>
                <Select
                  value={bulkUpdateData.employeeType}
                  onChange={(e) => setBulkUpdateData(prev => ({ ...prev, employeeType: e.target.value }))}
                  label="Employee Type"
                >
                  <MenuItem value="">Leave unchanged</MenuItem>
                  <MenuItem value="Full-time">Full-time</MenuItem>
                  <MenuItem value="Part-time">Part-time</MenuItem>
                  <MenuItem value="Contract">Contract</MenuItem>
                  <MenuItem value="Intern">Intern</MenuItem>
                </Select>
              </FormControl>
              <TextField
                label="Hourly Rate"
                type="number"
                value={bulkUpdateData.hourlyRate}
                onChange={(e) => setBulkUpdateData(prev => ({ ...prev, hourlyRate: e.target.value }))}
                placeholder="Leave empty to skip"
              />
              <TextField
                label="Monthly Salary"
                type="number"
                value={bulkUpdateData.monthlySalary}
                onChange={(e) => setBulkUpdateData(prev => ({ ...prev, monthlySalary: e.target.value }))}
                placeholder="Leave empty to skip"
              />
            </Box>

            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell padding="checkbox">
                      <input
                        type="checkbox"
                        checked={selectedEmployees.length === employees.length}
                        onChange={handleSelectAll}
                      />
                    </TableCell>
                    <TableCell>Name</TableCell>
                    <TableCell>Email</TableCell>
                    <TableCell>Position</TableCell>
                    <TableCell>Department</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {employees.map((employee) => (
                    <TableRow key={employee._id}>
                      <TableCell padding="checkbox">
                        <input
                          type="checkbox"
                          checked={selectedEmployees.includes(employee._id)}
                          onChange={() => handleEmployeeSelection(employee._id)}
                        />
                      </TableCell>
                      <TableCell>{`${employee.firstName} ${employee.lastName}`}</TableCell>
                      <TableCell>{employee.email}</TableCell>
                      <TableCell>{employee.position || '-'}</TableCell>
                      <TableCell>{employee.department || '-'}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <Box>
            <Typography variant="h6" mb={2}>Delete Multiple Employees</Typography>
            
            <Alert severity="warning" sx={{ mb: 2 }}>
              <Typography variant="body2">
                This action will permanently delete the selected employees and deactivate their user accounts. 
                This action cannot be undone.
              </Typography>
            </Alert>

            <Box mb={3}>
              <Typography variant="subtitle2" mb={1}>
                Select employees to delete:
              </Typography>
              <Box display="flex" gap={1} mb={2}>
                <Button
                  size="small"
                  onClick={handleSelectAll}
                  variant="outlined"
                >
                  {selectedEmployees.length === employees.length ? 'Deselect All' : 'Select All'}
                </Button>
                <Chip 
                  label={`${selectedEmployees.length} selected`} 
                  color="error" 
                  variant="outlined"
                />
              </Box>
            </Box>

            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell padding="checkbox">
                      <input
                        type="checkbox"
                        checked={selectedEmployees.length === employees.length}
                        onChange={handleSelectAll}
                      />
                    </TableCell>
                    <TableCell>Name</TableCell>
                    <TableCell>Email</TableCell>
                    <TableCell>Position</TableCell>
                    <TableCell>Department</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {employees.map((employee) => (
                    <TableRow key={employee._id}>
                      <TableCell padding="checkbox">
                        <input
                          type="checkbox"
                          checked={selectedEmployees.includes(employee._id)}
                          onChange={() => handleEmployeeSelection(employee._id)}
                        />
                      </TableCell>
                      <TableCell>{`${employee.firstName} ${employee.lastName}`}</TableCell>
                      <TableCell>{employee.email}</TableCell>
                      <TableCell>{employee.position || '-'}</TableCell>
                      <TableCell>{employee.department || '-'}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </Box>
        </TabPanel>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        {tabValue === 0 && (
          <Button
            onClick={handleBulkCreate}
            disabled={loading || newEmployees.length === 0}
            variant="contained"
            startIcon={loading ? <CircularProgress size={20} /> : <AddIcon />}
          >
            {loading ? 'Creating...' : 'Create Employees'}
          </Button>
        )}
        {tabValue === 1 && (
          <Button
            onClick={handleBulkUpdate}
            disabled={loading || selectedEmployees.length === 0}
            variant="contained"
            startIcon={loading ? <CircularProgress size={20} /> : <EditIcon />}
          >
            {loading ? 'Updating...' : 'Update Employees'}
          </Button>
        )}
        {tabValue === 2 && (
          <Button
            onClick={handleBulkDelete}
            disabled={loading || selectedEmployees.length === 0}
            variant="contained"
            color="error"
            startIcon={loading ? <CircularProgress size={20} /> : <DeleteIcon />}
          >
            {loading ? 'Deleting...' : 'Delete Employees'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default BulkEmployeeOperations; 