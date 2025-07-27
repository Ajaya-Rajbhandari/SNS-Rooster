import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Chip,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  CircularProgress,
  Menu,
  Divider
} from '@mui/material';
import {
  Business as BusinessIcon,
  People as PeopleIcon,
  Payment as PaymentIcon,
  Security as SecurityIcon,
  Info as InfoIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  CheckCircle as CheckCircleIcon,
  Close as CloseIcon,
  Send as SendIcon,
  MarkEmailRead as MarkReadIcon,
  Delete as DeleteIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

interface Notification {
  id: string;
  type: 'info' | 'warning' | 'error' | 'success';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  category: 'system' | 'company' | 'user' | 'payment' | 'security';
  actionUrl?: string;
}

interface NotificationCenterProps {
  open: boolean;
  onClose: () => void;
  anchorEl?: HTMLElement | null;
}

const NotificationCenter: React.FC<NotificationCenterProps> = ({ open, onClose, anchorEl }) => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(false);
  const [sendDialogOpen, setSendDialogOpen] = useState(false);
  const [sendForm, setSendForm] = useState({
    type: 'info',
    title: '',
    message: '',
    target: 'all' // 'all', 'specific', 'companies'
  });

  useEffect(() => {
    if (open) {
      fetchNotifications();
    }
  }, [open]);

  const fetchNotifications = async () => {
    try {
      setLoading(true);
      // Fetch notifications from backend
      const response = await apiService.get<any>('/api/super-admin/notifications');
      setNotifications(response.notifications || []);
    } catch (error) {
      console.error('Error fetching notifications:', error);
      // Set mock notifications for development
      setNotifications([
        {
          id: '1',
          type: 'info',
          title: 'New Company Registered',
          message: 'TechCorp Solutions has joined the platform',
          timestamp: new Date().toISOString(),
          read: false,
          category: 'company'
        },
        {
          id: '2',
          type: 'success',
          title: 'Payment Received',
          message: 'Monthly payment from Global Industries processed successfully',
          timestamp: new Date(Date.now() - 3600000).toISOString(),
          read: false,
          category: 'payment'
        },
        {
          id: '3',
          type: 'warning',
          title: 'System Maintenance',
          message: 'Scheduled maintenance will occur tonight at 2 AM',
          timestamp: new Date(Date.now() - 7200000).toISOString(),
          read: true,
          category: 'system'
        },
        {
          id: '4',
          type: 'error',
          title: 'Failed Login Attempt',
          message: 'Multiple failed login attempts detected from IP 192.168.1.100',
          timestamp: new Date(Date.now() - 10800000).toISOString(),
          read: false,
          category: 'security'
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const markAsRead = async (notificationId: string) => {
    try {
      await apiService.put(`/api/super-admin/notifications/${notificationId}/read`);
      setNotifications(prev => 
        prev.map(notif => 
          notif.id === notificationId ? { ...notif, read: true } : notif
        )
      );
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  const markAllAsRead = async () => {
    try {
      await apiService.put('/api/super-admin/notifications/mark-all-read');
      setNotifications(prev => prev.map(notif => ({ ...notif, read: true })));
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
    }
  };

  const deleteNotification = async (notificationId: string) => {
    try {
      await apiService.delete(`/api/super-admin/notifications/${notificationId}`);
      setNotifications(prev => prev.filter(notif => notif.id !== notificationId));
    } catch (error) {
      console.error('Error deleting notification:', error);
    }
  };

  const sendNotification = async () => {
    try {
      await apiService.post('/api/super-admin/notifications/send', sendForm);
      setSendDialogOpen(false);
      setSendForm({ type: 'info', title: '', message: '', target: 'all' });
      // Refresh notifications
      fetchNotifications();
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  };

  const getNotificationIcon = (type: string, category: string) => {
    if (category === 'company') return <BusinessIcon />;
    if (category === 'user') return <PeopleIcon />;
    if (category === 'payment') return <PaymentIcon />;
    if (category === 'security') return <SecurityIcon />;
    
    switch (type) {
      case 'success': return <CheckCircleIcon />;
      case 'warning': return <WarningIcon />;
      case 'error': return <ErrorIcon />;
      default: return <InfoIcon />;
    }
  };

  const getNotificationColor = (type: string) => {
    switch (type) {
      case 'success': return 'success';
      case 'warning': return 'warning';
      case 'error': return 'error';
      default: return 'info';
    }
  };

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);
    
    if (diffInHours < 1) return 'Just now';
    if (diffInHours < 24) return `${Math.floor(diffInHours)}h ago`;
    return date.toLocaleDateString();
  };

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <>
      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={onClose}
        PaperProps={{
          sx: {
            width: 400,
            maxHeight: 600
          }
        }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Typography variant="h6" component="div">
              Notifications
              {unreadCount > 0 && (
                <Chip
                  label={unreadCount}
                  size="small"
                  color="primary"
                  sx={{ ml: 1 }}
                />
              )}
            </Typography>
            <Box>
              <IconButton size="small" onClick={markAllAsRead} disabled={unreadCount === 0}>
                <MarkReadIcon />
              </IconButton>
              <IconButton size="small" onClick={() => setSendDialogOpen(true)}>
                <SendIcon />
              </IconButton>
              <IconButton size="small" onClick={onClose}>
                <CloseIcon />
              </IconButton>
            </Box>
          </Box>
        </Box>

        <Box sx={{ maxHeight: 400, overflow: 'auto' }}>
          {loading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', p: 3 }}>
              <CircularProgress />
            </Box>
          ) : notifications.length === 0 ? (
            <Box sx={{ p: 3, textAlign: 'center' }}>
              <Typography color="text.secondary">
                No notifications
              </Typography>
            </Box>
          ) : (
            <List sx={{ p: 0 }}>
              {notifications.map((notification, index) => (
                <React.Fragment key={notification.id}>
                  <ListItem
                    sx={{
                      backgroundColor: notification.read ? 'transparent' : 'action.hover',
                      '&:hover': { backgroundColor: 'action.hover' }
                    }}
                  >
                    <ListItemAvatar>
                      <Avatar sx={{ bgcolor: `${getNotificationColor(notification.type)}.light` }}>
                        {getNotificationIcon(notification.type, notification.category)}
                      </Avatar>
                    </ListItemAvatar>
                    <ListItemText
                      primary={
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <Typography
                            variant="subtitle2"
                            component="div"
                            sx={{ fontWeight: notification.read ? 400 : 600 }}
                          >
                            {notification.title}
                          </Typography>
                          <Typography variant="caption" component="div" color="text.secondary">
                            {formatTimestamp(notification.timestamp)}
                          </Typography>
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="body2" component="div" color="text.secondary">
                            {notification.message}
                          </Typography>
                          <Chip
                            label={notification.category}
                            size="small"
                            variant="outlined"
                            sx={{ mt: 0.5 }}
                          />
                        </Box>
                      }
                      primaryTypographyProps={{
                        component: 'div' // Change from 'p' to 'div' to prevent nesting issues
                      }}
                      secondaryTypographyProps={{
                        component: 'div' // Change from 'p' to 'div' to prevent nesting issues
                      }}
                    />
                    <Box>
                      {!notification.read && (
                        <IconButton
                          size="small"
                          onClick={() => markAsRead(notification.id)}
                        >
                          <MarkReadIcon />
                        </IconButton>
                      )}
                      <IconButton
                        size="small"
                        onClick={() => deleteNotification(notification.id)}
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </ListItem>
                  {index < notifications.length - 1 && <Divider />}
                </React.Fragment>
              ))}
            </List>
          )}
        </Box>
      </Menu>

      {/* Send Notification Dialog */}
      <Dialog open={sendDialogOpen} onClose={() => setSendDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Send Notification</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
            <FormControl fullWidth>
              <InputLabel>Type</InputLabel>
              <Select
                value={sendForm.type}
                onChange={(e) => setSendForm(prev => ({ ...prev, type: e.target.value }))}
                label="Type"
              >
                <MenuItem value="info">Info</MenuItem>
                <MenuItem value="success">Success</MenuItem>
                <MenuItem value="warning">Warning</MenuItem>
                <MenuItem value="error">Error</MenuItem>
              </Select>
            </FormControl>

            <FormControl fullWidth>
              <InputLabel>Target</InputLabel>
              <Select
                value={sendForm.target}
                onChange={(e) => setSendForm(prev => ({ ...prev, target: e.target.value }))}
                label="Target"
              >
                <MenuItem value="all">All Companies</MenuItem>
                <MenuItem value="specific">Specific Companies</MenuItem>
                <MenuItem value="companies">Active Companies Only</MenuItem>
              </Select>
            </FormControl>

            <TextField
              fullWidth
              label="Title"
              value={sendForm.title}
              onChange={(e) => setSendForm(prev => ({ ...prev, title: e.target.value }))}
            />

            <TextField
              fullWidth
              label="Message"
              multiline
              rows={4}
              value={sendForm.message}
              onChange={(e) => setSendForm(prev => ({ ...prev, message: e.target.value }))}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSendDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={sendNotification}
            variant="contained"
            disabled={!sendForm.title || !sendForm.message}
          >
            Send
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default NotificationCenter; 