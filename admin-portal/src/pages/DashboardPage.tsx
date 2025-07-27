import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Typography,
  Paper,
  Button,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Avatar,
  Chip,
  Divider,
  Alert,
  CircularProgress
} from '@mui/material';
import {
  Business as BusinessIcon,
  People as PeopleIcon,
  Subscriptions as SubscriptionsIcon,
  TrendingUp as TrendingUpIcon,
  Notifications as NotificationsIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  ArrowForward as ArrowForwardIcon
} from '@mui/icons-material';
import Layout from '../components/Layout';
import StatCard from '../components/dashboard/StatCard';
import cachedApiService from '../services/cachedApiService';
import { useCache } from '../contexts/CacheContext';
import CacheStatsWidget from '../components/CacheStatsWidget';

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
  const { stats: cacheStats } = useCache();

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      // Fetch stats from backend
      const statsResponse = await cachedApiService.get<any>('/api/super-admin/dashboard/stats');
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
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, height: '100%' }}>
      {/* Welcome Message */}
      <Box sx={{ mb: 1 }}>
        <Typography variant="body1" color="text.secondary">
          Welcome back! Here's what's happening with your SNS Rooster platform.
        </Typography>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" onClose={() => setError('')} sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Box sx={{ 
        display: 'grid', 
        gridTemplateColumns: { 
          xs: '1fr',
          sm: 'repeat(2, 1fr)',
          md: 'repeat(2, 1fr)',
          lg: 'repeat(4, 1fr)'
        }, 
        gap: 2,
        mb: 2
      }}>
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
        <Box sx={{ 
          display: 'grid', 
          gridTemplateColumns: { 
            xs: '1fr',
            lg: '1fr 1fr'
          },
          gap: 2,
          flex: 1,
          minHeight: 0
        }}>
          {/* Quick Actions */}
          <Paper sx={{ p: 2, display: 'flex', flexDirection: 'column' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6" component="h2" sx={{ fontWeight: 600 }}>
                Quick Actions
              </Typography>
            </Box>
            <Box sx={{ 
              display: 'grid', 
              gridTemplateColumns: { 
                xs: '1fr',
                sm: 'repeat(2, 1fr)'
              }, 
              gap: 2,
              flex: 1
            }}>
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


        </Box>

        {/* Recent Activities */}
        <Paper sx={{ p: 2 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
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
                    primary={
                      <Typography component="div">
                        {activity.title}
                      </Typography>
                    }
                    secondary={
                      <Box>
                        <Typography variant="body2" component="div" color="text.secondary">
                          {activity.description}
                        </Typography>
                        <Typography variant="caption" component="div" color="text.secondary">
                          {formatDate(activity.timestamp)}
                        </Typography>
                      </Box>
                    }
                    secondaryTypographyProps={{
                      component: 'div'
                    }}
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
  );
};

export default DashboardPage; 