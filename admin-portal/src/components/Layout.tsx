import React, { useState } from 'react';
import {
  ListItemIcon,
  Menu,
  MenuItem,
  Tooltip,
  Box,
  Typography,
  IconButton,
  Badge,
  AppBar,
  Toolbar
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Business as BusinessIcon,
  Subscriptions as SubscriptionsIcon,
  People as PeopleIcon,
  Analytics as AnalyticsIcon,
  Settings as SettingsIcon,
  Payment as PaymentIcon,
  AccountCircle as AccountCircleIcon,
  Logout as LogoutIcon,
  Lock as LockIcon,
  Monitor as MonitorIcon,
  Notifications as NotificationsIcon,
  ArrowBack as ArrowBackIcon
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useSidebar } from '../contexts/SidebarContext';
import NotificationCenter from './NotificationCenter';

// Removed unused variables - sidebarWidth is now calculated from context

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const { sidebarCollapsed, setSidebarCollapsed, sidebarWidth } = useSidebar();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [notificationAnchorEl, setNotificationAnchorEl] = useState<null | HTMLElement>(null);

  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout } = useAuth();

  const handleProfileMenuClose = () => {
    setAnchorEl(null);
  };

  const handleNotificationMenuClose = () => {
    setNotificationAnchorEl(null);
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
    handleProfileMenuClose();
  };

  const handleChangePassword = () => {
    navigate('/change-password');
    handleProfileMenuClose();
  };

  const handleProfileMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleNotificationMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setNotificationAnchorEl(event.currentTarget);
  };

  const handleSidebarToggle = () => {
    setSidebarCollapsed(!sidebarCollapsed);
  };

  const menuItems = [
    { text: 'Dashboard', icon: <DashboardIcon />, path: '/dashboard' },
    { text: 'Companies', icon: <BusinessIcon />, path: '/companies' },
    { text: 'Archived Companies', icon: <BusinessIcon />, path: '/companies/archived' },
    { text: 'Subscription Plans', icon: <SubscriptionsIcon />, path: '/subscription-plans' },
    { text: 'Users', icon: <PeopleIcon />, path: '/users' },
    { text: 'Analytics', icon: <AnalyticsIcon />, path: '/analytics' },
    { text: 'Billing', icon: <PaymentIcon />, path: '/billing' },
    { text: 'Monitoring', icon: <MonitorIcon />, path: '/monitoring' },
    { text: 'Settings', icon: <SettingsIcon />, path: '/settings' },
  ];

  return (
    <div style={{ 
      display: 'flex', 
      minHeight: '100vh', 
      width: '100%',
      margin: 0,
      padding: 0
    }}>
      {/* Sidebar */}
      <div style={{ 
        width: sidebarWidth, 
        flexShrink: 0,
        backgroundColor: '#f5f5f5',
        color: '#333',
        display: 'flex',
        flexDirection: 'column',
        margin: 0,
        padding: 0,
        borderRight: '1px solid #e0e0e0',
        position: 'fixed',
        top: 0,
        left: 0,
        height: '100vh',
        zIndex: 1200,
        overflowY: 'auto'
      }}>
        {/* Logo/Brand Section */}
        <div style={{ 
          padding: sidebarCollapsed ? '16px' : '24px', 
          display: 'flex', 
          alignItems: 'center', 
          gap: sidebarCollapsed ? '0' : '16px',
          borderBottom: '1px solid #e0e0e0',
          justifyContent: sidebarCollapsed ? 'center' : 'space-between'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ 
              width: 40, 
              height: 40, 
              borderRadius: '50%', 
              backgroundColor: '#1976d2',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <span style={{ color: 'white', fontWeight: 'bold', fontSize: '16px' }}>
                SNS
              </span>
            </div>
            {!sidebarCollapsed && (
              <div>
                <div style={{ fontWeight: 'bold', fontSize: '18px', color: '#1976d2' }}>
                  SNS Rooster
                </div>
                <div style={{ fontSize: '12px', color: '#666' }}>
                  Admin Portal
                </div>
              </div>
            )}
          </div>
          
          {/* Collapse/Expand Button */}
          <IconButton
            onClick={handleSidebarToggle}
            style={{ 
              color: '#666',
              padding: '4px',
              minWidth: 'auto'
            }}
          >
            {sidebarCollapsed ? (
              <ArrowBackIcon style={{ transform: 'rotate(180deg)', fontSize: '20px' }} />
            ) : (
              <ArrowBackIcon style={{ fontSize: '20px' }} />
            )}
          </IconButton>
        </div>

        {/* Navigation Menu */}
        <div style={{ paddingTop: 16, flex: 1 }}>
          {menuItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <div key={item.text} style={{ marginBottom: 4 }}>
                <Tooltip 
                  title={sidebarCollapsed ? item.text : ''} 
                  placement="right"
                  disableHoverListener={!sidebarCollapsed}
                >
                  <div
                    onClick={() => navigate(item.path)}
                    style={{
                      margin: sidebarCollapsed ? '4px' : '8px',
                      borderRadius: 8,
                      backgroundColor: isActive ? '#1976d2' : 'transparent',
                      color: isActive ? 'white' : '#333',
                      justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
                      minHeight: 48,
                      alignItems: 'center',
                      display: 'flex',
                      cursor: 'pointer',
                      padding: sidebarCollapsed ? '0' : '0 16px',
                      transition: 'background-color 0.2s'
                    }}
                    onMouseEnter={(e) => {
                      if (!isActive) {
                        e.currentTarget.style.backgroundColor = '#e3f2fd';
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (!isActive) {
                        e.currentTarget.style.backgroundColor = 'transparent';
                      }
                    }}
                  >
                    <div style={{ 
                      minWidth: sidebarCollapsed ? 40 : 32,
                      marginRight: sidebarCollapsed ? 0 : 8,
                      display: 'flex',
                      justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
                      alignItems: 'center',
                      color: isActive ? 'white' : '#666',
                    }}>
                      {item.icon}
                    </div>
                    {!sidebarCollapsed && (
                      <span style={{ 
                        fontWeight: isActive ? 600 : 400,
                        fontSize: '14px'
                      }}>
                        {item.text}
                      </span>
                    )}
                  </div>
                </Tooltip>
              </div>
            );
          })}
        </div>


      </div>

      {/* Main Content Area */}
      <div style={{ 
        flex: 1, 
        display: 'flex', 
        flexDirection: 'column',
        backgroundColor: 'white',
        minHeight: '100vh',
        margin: 0,
        padding: 0,
        marginLeft: sidebarWidth
      }}>


        {/* Top Header Bar */}
        <AppBar 
          position="fixed" 
          elevation={0}
          style={{ 
            backgroundColor: 'white', 
            color: '#333',
            borderBottom: '1px solid #e0e0e0',
            width: `calc(100% - ${sidebarWidth}px)`,
            left: sidebarWidth,
            zIndex: 1100
          }}
        >
          <Toolbar style={{ paddingLeft: 24, paddingRight: 24 }}>
            <Box style={{ display: 'flex', alignItems: 'center', gap: 8, marginRight: 'auto' }}>
              <Typography variant="h6" style={{ color: '#333', fontWeight: 500 }}>
                {(() => {
                  const currentPath = location.pathname;
                  switch (currentPath) {
                    case '/dashboard':
                      return 'Dashboard';
                    case '/companies':
                      return 'Company Management';
                    case '/companies/archived':
                      return 'Archived Companies';
                    case '/subscription-plans':
                      return 'Subscription Plan Management';
                    case '/users':
                      return 'Company User Management';
                    case '/analytics':
                      return 'Analytics Dashboard';
                    case '/monitoring':
                      return 'System Monitoring';
                    case '/settings':
                      return 'Settings';
                    default:
                      return 'Dashboard';
                  }
                })()}
              </Typography>
            </Box>
            
            <Box style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              {/* Notification Bell */}
              <IconButton
                onClick={handleNotificationMenuOpen}
                style={{ color: '#333' }}
              >
                <Badge badgeContent={4} color="error">
                  <NotificationsIcon />
                </Badge>
              </IconButton>
              
              {/* User Avatar with Dropdown */}
              <IconButton
                onClick={handleProfileMenuOpen}
                style={{ 
                  width: 40, 
                  height: 40, 
                  backgroundColor: '#1976d2',
                  color: 'white',
                  marginLeft: 8
                }}
              >
                <span style={{ fontWeight: 'bold', fontSize: '16px' }}>
                  {user?.firstName?.charAt(0) || 'S'}
                </span>
              </IconButton>
            </Box>
          </Toolbar>
        </AppBar>

        {/* Content Area */}
        <div style={{ 
          flex: 1, 
          padding: '24px',
          marginTop: '64px'
        }}>
          {children}
        </div>
      </div>

      {/* User Profile Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleProfileMenuClose}
        PaperProps={{
          elevation: 0,
          sx: {
            overflow: 'visible',
            filter: 'drop-shadow(0px 2px 8px rgba(0,0,0,0.32))',
            mt: 1.5,
            minWidth: 200,
          },
        }}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        {/* User Info Header */}
        <Box style={{ padding: '16px', borderBottom: '1px solid #e0e0e0' }}>
          <Box style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
            <div style={{ 
              width: 40, 
              height: 40, 
              borderRadius: '50%',
              backgroundColor: '#1976d2',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontWeight: 'bold'
            }}>
              {user?.firstName?.charAt(0) || 'S'}
            </div>
            <Box>
              <Typography variant="body1" style={{ 
                fontSize: '14px', 
                fontWeight: 600, 
                color: '#333',
                lineHeight: 1.2
              }}>
                Super Admin
              </Typography>
              <Typography variant="body2" style={{ 
                fontSize: '12px', 
                color: '#666',
                lineHeight: 1.2
              }}>
                Admin
              </Typography>
            </Box>
          </Box>
          <div style={{ 
            display: 'inline-block',
            padding: '4px 8px',
            borderRadius: 12,
            fontSize: '12px',
            color: '#4caf50',
            backgroundColor: 'transparent',
            border: '1px solid #4caf50'
          }}>
            Online
          </div>
        </Box>
        
        <MenuItem onClick={() => navigate('/profile')}>
          <ListItemIcon>
            <AccountCircleIcon fontSize="small" />
          </ListItemIcon>
          Profile
        </MenuItem>
        <MenuItem onClick={handleChangePassword}>
          <ListItemIcon>
            <LockIcon fontSize="small" />
          </ListItemIcon>
          Change Password
        </MenuItem>
        <MenuItem onClick={handleLogout}>
          <ListItemIcon>
            <LogoutIcon fontSize="small" />
          </ListItemIcon>
          Logout
        </MenuItem>
      </Menu>

      {/* Notification Center */}
      <NotificationCenter
        open={Boolean(notificationAnchorEl)}
        onClose={handleNotificationMenuClose}
        anchorEl={notificationAnchorEl}
      />
    </div>
  );
};

export default Layout; 