import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Grid,
  Paper,
  Button,
  Card,
  CardContent,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Chip,
  Divider,
  Alert,
  CircularProgress,
  useTheme
} from '@mui/material';
import {
  Business as BusinessIcon,
  People as PeopleIcon,
  Subscriptions as SubscriptionsIcon,
  TrendingUp as TrendingUpIcon,
  Notifications as NotificationsIcon,
  Schedule as ScheduleIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  Error as ErrorIcon,
  ArrowForward as ArrowForwardIcon
} from '@mui/icons-material';
import Layout from '../components/Layout';
import StatCard from '../components/dashboard/StatCard';
import apiService from '../services/apiService';

interface DashboardStats {
  totalCompanies: number;
  totalUsers: number;
  totalPlans: number;
  activeSubscriptions: number;
  monthlyRevenue: number;
  pendingApprovals: number;
}

interface RecentActivity {
  id: string;
  type: 'company_created' | 'user_registered' | 'subscription_updated' | 'payment_received';
  title: string;
  description: string;
  timestamp: string;
  status: 'success' | 'warning' | 'error' | 'info';
}

const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    totalCompanies: 0,
    totalUsers: 0,
    totalPlans: 0,
    activeSubscriptions: 0,
    monthlyRevenue: 0,
    pendingApprovals: 0
  });
  const [recentActivities, setRecentActivities] = useState<RecentActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const theme = useTheme();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      // Fetch stats from backend
      const statsResponse = await apiService.get<any>('/api/super-admin/dashboard/stats');
      setStats(statsResponse);

      // Mock recent activities for now
      setRecentActivities([
        {
          id: '1',
          type: 'company_created',
          title: 'New Company Registered',
          description: 'TechCorp Solutions joined the platform',
          timestamp: new Date().toISOString(),
          status: 'success'
        },
        {
          id: '2',
          type: 'subscription_updated',
          title: 'Subscription Upgraded',
          description: 'Global Industries upgraded to Premium plan',
          timestamp: new Date(Date.now() - 3600000).toISOString(),
          status: 'info'
        },
        {
          id: '3',
          type: 'payment_received',
          title: 'Payment Received',
          description: 'Monthly payment from InnovateTech',
          timestamp: new Date(Date.now() - 7200000).toISOString(),
          status: 'success'
        }
      ]);
    } catch (err) {
      console.error('Error fetching dashboard data:', err);
      setError('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'company_created':
        return <BusinessIcon />;
      case 'user_registered':
        return <PeopleIcon />;
      case 'subscription_updated':
        return <SubscriptionsIcon />;
      case 'payment_received':
        return <TrendingUpIcon />;
      default:
        return <NotificationsIcon />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success':
        return 'success';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'info';
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <Layout>
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
          <CircularProgress />
        </Box>
      </Layout>
    );
  }

  return (
    <Layout>
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
        {/* Header */}
        <Box>
          <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
            Dashboard
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Welcome back! Here's what's happening with your SNS Rooster platform.
          </Typography>
        </Box>

        {/* Error Alert */}
        {error && (
          <Alert severity="error" onClose={() => setError('')}>
            {error}
          </Alert>
        )}

        {/* Stats Cards */}
        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 3 }}>
          <StatCard
            title="Total Companies"
            value={stats.totalCompanies}
            subtitle="Active companies in the system"
            icon={<BusinessIcon />}
            color="primary"
            trend={{ value: 12, isPositive: true, label: "vs last month" }}
            onClick={() => navigate('/companies')}
          />
          <StatCard
            title="Total Users"
            value={stats.totalUsers}
            subtitle="Registered users across all companies"
            icon={<PeopleIcon />}
            color="success"
            trend={{ value: 8, isPositive: true, label: "vs last month" }}
            onClick={() => navigate('/users')}
          />
          <StatCard
            title="Subscription Plans"
            value={stats.totalPlans}
            subtitle="Available subscription plans"
            icon={<SubscriptionsIcon />}
            color="info"
            onClick={() => navigate('/subscription-plans')}
          />
          <StatCard
            title="Monthly Revenue"
            value={formatCurrency(stats.monthlyRevenue)}
            subtitle="Total revenue this month"
            icon={<TrendingUpIcon />}
            color="warning"
            trend={{ value: 15, isPositive: true, label: "vs last month" }}
          />
        </Box>

        {/* Main Content Grid */}
        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr', gap: 3, '@media (min-width: 960px)': { gridTemplateColumns: '2fr 1fr' } }}>
          {/* Quick Actions */}
          <Paper sx={{ p: 3, height: '100%' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
              <Typography variant="h6" component="h2" sx={{ fontWeight: 600 }}>
                Quick Actions
              </Typography>
            </Box>
            <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 2 }}>
              <Button
                variant="contained"
                fullWidth
                size="large"
                startIcon={<BusinessIcon />}
                onClick={() => navigate('/companies')}
                sx={{ 
                  py: 2, 
                  justifyContent: 'flex-start',
                  textTransform: 'none',
                  fontSize: '1rem'
                }}
              >
                Manage Companies
              </Button>
              <Button
                variant="contained"
                fullWidth
                size="large"
                startIcon={<SubscriptionsIcon />}
                onClick={() => navigate('/subscription-plans')}
                sx={{ 
                  py: 2, 
                  justifyContent: 'flex-start',
                  textTransform: 'none',
                  fontSize: '1rem'
                }}
              >
                Manage Plans
              </Button>
              <Button
                variant="outlined"
                fullWidth
                size="large"
                startIcon={<PeopleIcon />}
                onClick={() => navigate('/users')}
                sx={{ 
                  py: 2, 
                  justifyContent: 'flex-start',
                  textTransform: 'none',
                  fontSize: '1rem'
                }}
              >
                Manage Users
              </Button>
              <Button
                variant="outlined"
                fullWidth
                size="large"
                startIcon={<TrendingUpIcon />}
                onClick={() => navigate('/analytics')}
                sx={{ 
                  py: 2, 
                  justifyContent: 'flex-start',
                  textTransform: 'none',
                  fontSize: '1rem'
                }}
              >
                View Analytics
              </Button>
            </Box>
          </Paper>

          {/* System Status */}
          <Paper sx={{ p: 3, height: '100%' }}>
            <Typography variant="h6" component="h2" sx={{ fontWeight: 600, mb: 3 }}>
              System Status
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <CheckCircleIcon color="success" />
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body2" fontWeight={500}>
                    Backend API
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    All systems operational
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <CheckCircleIcon color="success" />
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body2" fontWeight={500}>
                    Database
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Connected and healthy
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <CheckCircleIcon color="success" />
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body2" fontWeight={500}>
                    Email Service
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Sending emails normally
                  </Typography>
                </Box>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <WarningIcon color="warning" />
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body2" fontWeight={500}>
                    Storage
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    75% capacity used
                  </Typography>
                </Box>
              </Box>
            </Box>
          </Paper>
        </Box>

        {/* Recent Activities */}
        <Paper sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
            <Typography variant="h6" component="h2" sx={{ fontWeight: 600 }}>
              Recent Activities
            </Typography>
            <Button
              variant="text"
              endIcon={<ArrowForwardIcon />}
              onClick={() => navigate('/analytics')}
            >
              View All
            </Button>
          </Box>
          <List sx={{ p: 0 }}>
            {recentActivities.map((activity, index) => (
              <React.Fragment key={activity.id}>
                <ListItem sx={{ px: 0 }}>
                  <ListItemAvatar>
                    <Avatar sx={{ bgcolor: `${getStatusColor(activity.status)}.light` }}>
                      {getActivityIcon(activity.type)}
                    </Avatar>
                  </ListItemAvatar>
                  <ListItemText
                    primary={activity.title}
                    secondary={
                      <Box>
                        <Typography variant="body2" color="text.secondary">
                          {activity.description}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {formatDate(activity.timestamp)}
                        </Typography>
                      </Box>
                    }
                  />
                  <Chip
                    label={activity.status}
                    color={getStatusColor(activity.status) as any}
                    size="small"
                    variant="outlined"
                  />
                </ListItem>
                {index < recentActivities.length - 1 && <Divider />}
              </React.Fragment>
            ))}
          </List>
        </Paper>
      </Box>
    </Layout>
  );
};

export default DashboardPage; 