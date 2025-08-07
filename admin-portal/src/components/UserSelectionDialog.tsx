import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  CircularProgress,
  Alert,
  Radio,
  FormControlLabel,
  RadioGroup
} from '@mui/material';
import {
  Search as SearchIcon,
  Person as PersonIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

interface User {
  _id: string;
  firstName: string;
  lastName: string;
  email: string;
  role: 'super_admin' | 'admin' | 'employee';
  department?: string;
  position?: string;
  isActive: boolean;
}

interface UserSelectionDialogProps {
  open: boolean;
  onClose: () => void;
  onSelect: (user: User) => void;
  companyId: string;
  excludeUserIds?: string[]; // Users to exclude (already have employees)
}

const UserSelectionDialog: React.FC<UserSelectionDialogProps> = ({
  open,
  onClose,
  onSelect,
  companyId,
  excludeUserIds = []
}) => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUserId, setSelectedUserId] = useState<string>('');

  useEffect(() => {
    if (open && companyId) {
      fetchUsers();
    }
  }, [open, companyId]);

  const fetchUsers = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiService.get<any>(`/api/super-admin/users?companyId=${companyId}&limit=1000`);
      const allUsers = response.users || [];
      
      // Filter out users that already have employees and super admin users
      const availableUsers = allUsers.filter((user: User) => 
        user.role !== 'super_admin' && 
        !excludeUserIds.includes(user._id) &&
        user.isActive
      );
      
      setUsers(availableUsers);
    } catch (err: any) {
      console.error('Error fetching users:', err);
      setError('Failed to fetch users');
    } finally {
      setLoading(false);
    }
  };

  const filteredUsers = users.filter(user =>
    `${user.firstName} ${user.lastName} ${user.email} ${user.department || ''} ${user.position || ''}`
      .toLowerCase()
      .includes(searchTerm.toLowerCase())
  );

  const handleSelect = () => {
    const selectedUser = users.find(user => user._id === selectedUserId);
    if (selectedUser) {
      onSelect(selectedUser);
      onClose();
    }
  };

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin': return '#1976d2';
      case 'employee': return '#388e3c';
      default: return '#757575';
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box display="flex" alignItems="center" gap={1}>
          <PersonIcon />
          <Typography variant="h6">Select User for Employee Creation</Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Typography variant="body2" color="textSecondary" sx={{ mb: 2 }}>
          Select a user to create an employee record. Only active users without existing employee records are shown.
        </Typography>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <Box sx={{ mb: 2 }}>
          <TextField
            fullWidth
            placeholder="Search users..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
            }}
          />
        </Box>

        {loading ? (
          <Box display="flex" justifyContent="center" p={3}>
            <CircularProgress />
          </Box>
        ) : filteredUsers.length === 0 ? (
          <Box textAlign="center" p={3}>
            <Typography color="textSecondary">
              {searchTerm ? 'No users found matching your search' : 'No available users found'}
            </Typography>
          </Box>
        ) : (
          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell padding="checkbox"></TableCell>
                  <TableCell><strong>Name</strong></TableCell>
                  <TableCell><strong>Email</strong></TableCell>
                  <TableCell><strong>Role</strong></TableCell>
                  <TableCell><strong>Department</strong></TableCell>
                  <TableCell><strong>Position</strong></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                <RadioGroup value={selectedUserId} onChange={(e) => setSelectedUserId(e.target.value)}>
                  {filteredUsers.map((user) => (
                    <TableRow key={user._id} hover>
                      <TableCell padding="checkbox">
                        <Radio value={user._id} />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" fontWeight="medium">
                          {user.firstName} {user.lastName}
                        </Typography>
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
                      <TableCell>{user.department || '-'}</TableCell>
                      <TableCell>{user.position || '-'}</TableCell>
                    </TableRow>
                  ))}
                </RadioGroup>
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleSelect}
          disabled={!selectedUserId}
        >
          Select User
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default UserSelectionDialog; 