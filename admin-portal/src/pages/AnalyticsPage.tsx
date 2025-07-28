import React, { useState, useEffect, useCallback } from 'react';
import {
  Box,
  Typography,
  Paper,
  Card,
  CardContent,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Button
} from '@mui/material';
import {
  TrendingUp as TrendingUpIcon,
  TrendingDown as TrendingDownIcon,
  Business as BusinessIcon,
  People as PeopleIcon,
  AttachMoney as MoneyIcon,
  Assessment as AssessmentIcon,
  Refresh as RefreshIcon,
  Download as DownloadIcon,
  BarChart as BarChartIcon,
  PieChart as PieChartIcon
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';
import apiService from '../services/apiService';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8', '#82CA9D'];

interface AnalyticsData {
  overview: {
    totalCompanies: number;
    activeCompanies: number;
    totalUsers: number;
    totalRevenue: number;
    monthlyGrowth: number;
    userGrowth: number;
  };
  revenueData: Array<{
    month: string;
    revenue: number;
    subscriptions: number;
  }>;
  companyGrowth: Array<{
    month: string;
    newCompanies: number;
    activeCompanies: number;
  }>;
  userActivity: Array<{
    date: string;
    activeUsers: number;
    newUsers: number;
  }>;
  subscriptionDistribution: Array<{
    plan: string;
    companies: number;
    percentage: number;
  }>;
  topCompanies: Array<{
    name: string;
    users: number;
    revenue: number;
    status: string;
  }>;
}

const AnalyticsPage: React.FC = () => {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [timeRange, setTimeRange] = useState('30d');
  const [activeTab, setActiveTab] = useState(0);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  const [userActivityData, setUserActivityData] = useState<any>(null);
  const [companyPerformanceData, setCompanyPerformanceData] = useState<any>(null);
  const [reportLoading, setReportLoading] = useState(false);
  const [userActivityLoading, setUserActivityLoading] = useState(false);
  const [companyPerformanceLoading, setCompanyPerformanceLoading] = useState(false);
  const [reportButtonLoading, setReportButtonLoading] = useState<string | null>(null);

  const fetchAnalyticsData = useCallback(async () => {
    try {
      setLoading(true);
      setError('');
      
      // Fetch comprehensive analytics data
      const [analyticsResponse, userActivityResponse, companyPerformanceResponse] = await Promise.all([
        apiService.get(`/api/super-admin/analytics?timeRange=${timeRange}`),
        apiService.get(`/api/super-admin/analytics/user-activity?timeRange=${timeRange}`),
        apiService.get(`/api/super-admin/analytics/company-performance?timeRange=${timeRange}`)
      ]);
      
      setData(analyticsResponse as AnalyticsData);
      setUserActivityData(userActivityResponse as any);
      setCompanyPerformanceData(companyPerformanceResponse as any);
      setLastUpdated(new Date());
    } catch (err: any) {
      console.error('Error fetching analytics data:', err);
      setError('Failed to load analytics data. Please check your connection and try again.');
    } finally {
      setLoading(false);
    }
  }, [timeRange]);

  useEffect(() => {
    fetchAnalyticsData();
  }, [fetchAnalyticsData]);

  const handleRefresh = () => {
    setLoading(true);
    setError('');
    setSuccess('');
    fetchAnalyticsData();
    
    // Also refresh specific tab data if it's loaded
    if (userActivityData) {
      fetchUserActivityData();
    }
    if (companyPerformanceData) {
      fetchCompanyPerformanceData();
    }
    
    setLastUpdated(new Date());
  };

  const fetchUserActivityData = async () => {
    try {
      setUserActivityLoading(true);
      const response: any = await apiService.get(`/api/super-admin/analytics/user-activity?timeRange=${timeRange}`);
      
      // Transform the data to match chart expectations
      const transformedData = {
        ...response,
        roleDistribution: response.roleDistribution?.map((item: any) => ({
          name: item._id || 'Unknown',
          value: item.count || 0
        })) || [],
        loginActivity: response.loginActivity || []
      };
      
      setUserActivityData(transformedData);
    } catch (err: any) {
      console.error('Error fetching user activity data:', err);
      setError('Failed to load user activity data');
    } finally {
      setUserActivityLoading(false);
    }
  };

  const fetchCompanyPerformanceData = async () => {
    try {
      setCompanyPerformanceLoading(true);
      const response: any = await apiService.get(`/api/super-admin/analytics/company-performance?timeRange=${timeRange}`);
      
      // Transform the data to match chart expectations
      const transformedData = {
        ...response,
        performanceMetrics: {
          ...response.performanceMetrics,
          subscriptionPlanDistribution: response.performanceMetrics?.subscriptionPlanDistribution?.map((item: any) => ({
            name: item._id || 'Unknown',
            value: item.count || 0
          })) || []
        }
      };
      
      setCompanyPerformanceData(transformedData);
    } catch (err: any) {
      console.error('Error fetching company performance data:', err);
      setError('Failed to load company performance data');
    } finally {
      setCompanyPerformanceLoading(false);
    }
  };

  const handleExport = async () => {
    try {
      setError('');
      setSuccess('');
      // Generate a comprehensive analytics report
      await handleGenerateReport('system_overview', 'json');
      setSuccess('Analytics data exported successfully!');
      // Auto-clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      setError(`Failed to export data: ${err.response?.data?.error || err.message}`);
    }
  };

  const handleGenerateReport = async (reportType: string, format: string = 'json') => {
    const buttonKey = `${reportType}_${format}`;
    setReportButtonLoading(buttonKey);
    setReportLoading(true);
    setError('');
    setSuccess('');
    
    try {
      const response = await apiService.post('/api/super-admin/analytics/reports', {
        reportType,
        timeRange,
        format
      });
      
      if (format === 'csv') {
        // Handle CSV download
        const blob = new Blob([response as string], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${reportType}_${timeRange}_${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);
      } else {
        // Handle JSON download
        const blob = new Blob([JSON.stringify(response, null, 2)], { type: 'application/json' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${reportType}_${timeRange}_${new Date().toISOString().split('T')[0]}.json`;
        a.click();
        window.URL.revokeObjectURL(url);
      }
      
      setSuccess(`${reportType.replace('_', ' ').toUpperCase()} report downloaded successfully!`);
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      setError(`Failed to generate ${reportType} report: ${err.response?.data?.error || err.message}`);
    } finally {
      setReportLoading(false);
      setReportButtonLoading(null);
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-US').format(num);
  };

  const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

  if (loading && !data) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, height: '100%' }}>
      {/* Header */}
      <Paper sx={{ p: 2 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Box>
            <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
              Analytics Dashboard
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Comprehensive insights into your SNS Rooster platform performance
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Time Range</InputLabel>
              <Select
                value={timeRange}
                onChange={(e) => setTimeRange(e.target.value)}
                label="Time Range"
              >
                <MenuItem value="7d">Last 7 days</MenuItem>
                <MenuItem value="30d">Last 30 days</MenuItem>
                <MenuItem value="90d">Last 90 days</MenuItem>
                <MenuItem value="1y">Last year</MenuItem>
              </Select>
            </FormControl>
            <Tooltip title="Refresh Data">
              <IconButton onClick={handleRefresh} disabled={loading}>
                {loading ? <CircularProgress size={20} /> : <RefreshIcon />}
              </IconButton>
            </Tooltip>
            <Tooltip title="Export Data">
              <IconButton onClick={handleExport} disabled={reportLoading}>
                {reportLoading ? <CircularProgress size={20} /> : <DownloadIcon />}
              </IconButton>
            </Tooltip>
          </Box>
        </Box>
        <Typography variant="caption" color="text.secondary">
          Last updated: {lastUpdated.toLocaleString()}
        </Typography>
      </Paper>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" onClose={() => setError('')} sx={{ mb: 1 }}>
          {error}
        </Alert>
      )}

      {/* Success Alert */}
      {success && (
        <Alert severity="success" onClose={() => setSuccess('')} sx={{ mb: 1 }}>
          {success}
        </Alert>
      )}

      {data && (
        <>
          {/* Overview Cards */}
          <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr 1fr' }, gap: 2, mb: 2 }}>
            <Box sx={{ gridColumn: { xs: '1', md: 'auto' } }}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2 }}>
                    <Box sx={{ flex: 1 }}>
                      <Typography color="textSecondary" gutterBottom variant="body2" component="div">
                        Total Companies
                      </Typography>
                      <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                        {formatNumber(data.overview.totalCompanies)}
                      </Typography>
                      <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                        {data.overview.monthlyGrowth > 0 ? (
                          <TrendingUpIcon color="success" sx={{ fontSize: 16, mr: 0.5 }} />
                        ) : (
                          <TrendingDownIcon color="error" sx={{ fontSize: 16, mr: 0.5 }} />
                        )}
                        <Typography variant="caption" color={data.overview.monthlyGrowth > 0 ? 'success.main' : 'error.main'} component="div">
                          {Math.abs(data.overview.monthlyGrowth)}% this month
                        </Typography>
                      </Box>
                    </Box>
                    <BusinessIcon color="primary" sx={{ fontSize: 32 }} />
                  </Box>
                </CardContent>
              </Card>
            </Box>

            <Box sx={{ gridColumn: { xs: '1', md: 'auto' } }}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2 }}>
                    <Box sx={{ flex: 1 }}>
                      <Typography color="textSecondary" gutterBottom variant="body2" component="div">
                        Total Users
                      </Typography>
                      <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                        {formatNumber(data.overview.totalUsers)}
                      </Typography>
                      <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                        {data.overview.userGrowth > 0 ? (
                          <TrendingUpIcon color="success" sx={{ fontSize: 16, mr: 0.5 }} />
                        ) : (
                          <TrendingDownIcon color="error" sx={{ fontSize: 16, mr: 0.5 }} />
                        )}
                        <Typography variant="caption" color={data.overview.userGrowth > 0 ? 'success.main' : 'error.main'} component="div">
                          {Math.abs(data.overview.userGrowth)}% this month
                        </Typography>
                      </Box>
                    </Box>
                    <PeopleIcon color="primary" sx={{ fontSize: 32 }} />
                  </Box>
                </CardContent>
              </Card>
            </Box>

            <Box sx={{ gridColumn: { xs: '1', md: 'auto' } }}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2 }}>
                    <Box sx={{ flex: 1 }}>
                      <Typography color="textSecondary" gutterBottom variant="body2" component="div">
                        Total Revenue
                      </Typography>
                      <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                        {formatCurrency(data.overview.totalRevenue)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" component="div">
                        Lifetime revenue
                      </Typography>
                    </Box>
                    <MoneyIcon color="primary" sx={{ fontSize: 32 }} />
                  </Box>
                </CardContent>
              </Card>
            </Box>

            <Box sx={{ gridColumn: { xs: '1', md: 'auto' } }}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2 }}>
                    <Box sx={{ flex: 1 }}>
                      <Typography color="textSecondary" gutterBottom variant="body2" component="div">
                        Active Companies
                      </Typography>
                      <Typography variant="h4" component="div" sx={{ fontWeight: 700 }}>
                        {formatNumber(data.overview.activeCompanies)}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" component="div">
                        {Math.round((data.overview.activeCompanies / data.overview.totalCompanies) * 100)}% of total
                      </Typography>
                    </Box>
                    <AssessmentIcon color="primary" sx={{ fontSize: 32 }} />
                  </Box>
                </CardContent>
              </Card>
            </Box>
          </Box>

          {/* Charts Tabs */}
          <Paper sx={{ p: 3 }}>
            <Box sx={{ 
              borderBottom: 1, 
              borderColor: 'divider',
              overflowX: 'auto',
              '&::-webkit-scrollbar': {
                height: '8px',
              },
              '&::-webkit-scrollbar-track': {
                background: '#f1f1f1',
                borderRadius: '4px',
              },
              '&::-webkit-scrollbar-thumb': {
                background: '#c1c1c1',
                borderRadius: '4px',
                '&:hover': {
                  background: '#a8a8a8',
                },
              },
            }}>
              <Tabs 
                value={activeTab} 
                onChange={(e, newValue) => setActiveTab(newValue)} 
                sx={{ 
                  mb: 2,
                  minWidth: 'max-content',
                  '& .MuiTab-root': {
                    minWidth: 'auto',
                    padding: '8px 12px',
                    fontSize: '0.8rem',
                    textTransform: 'none',
                  }
                }}
                variant="scrollable"
                scrollButtons="auto"
                allowScrollButtonsMobile
              >
                <Tab label="Overview" icon={<AssessmentIcon />} />
                <Tab label="Revenue Analytics" icon={<MoneyIcon />} />
                <Tab label="Company Growth" icon={<BusinessIcon />} />
                <Tab label="User Activity" icon={<PeopleIcon />} />
                <Tab label="Advanced User Analytics" icon={<PeopleIcon />} />
                <Tab label="Company Performance" icon={<BusinessIcon />} />
                <Tab label="Subscription Distribution" icon={<PieChartIcon />} />
                <Tab label="Top Companies" icon={<BarChartIcon />} />
                <Tab label="Custom Reports" icon={<DownloadIcon />} />
              </Tabs>
            </Box>

            {/* Overview */}
            {activeTab === 0 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Platform Overview
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr 1fr' }, gap: 2 }}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>Key Metrics</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Total Companies:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>{formatNumber(data.overview.totalCompanies)}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Active Companies:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>{formatNumber(data.overview.activeCompanies)}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Total Users:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>{formatNumber(data.overview.totalUsers)}</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Total Revenue:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>{formatCurrency(data.overview.totalRevenue)}</Typography>
                        </Box>
                      </Box>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>Growth Rates</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Monthly Growth:</Typography>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, minWidth: 'fit-content' }}>
                            <TrendingUpIcon color="success" sx={{ fontSize: 20 }} />
                            <Typography variant="h6" color="success.main" sx={{ fontWeight: 600 }}>+{data.overview.monthlyGrowth}%</Typography>
                          </Box>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>User Growth:</Typography>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, minWidth: 'fit-content' }}>
                            <TrendingUpIcon color="success" sx={{ fontSize: 20 }} />
                            <Typography variant="h6" color="success.main" sx={{ fontWeight: 600 }}>+{data.overview.userGrowth}%</Typography>
                          </Box>
                        </Box>
                      </Box>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>Performance Metrics</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>System Uptime:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>99.8%</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Avg Response Time:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>245ms</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Active Sessions:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>156</Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
                          <Typography variant="body2" color="text.secondary" sx={{ flex: 1 }}>Data Usage:</Typography>
                          <Typography variant="h6" sx={{ fontWeight: 600, minWidth: 'fit-content' }}>2.4GB</Typography>
                        </Box>
                      </Box>
                    </CardContent>
                  </Card>
                </Box>
              </Box>
            )}

            {/* Revenue Analytics */}
            {activeTab === 1 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Revenue & Subscription Trends
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '2fr 1fr' }, gap: 2, mb: 2 }}>
                  <ResponsiveContainer width="100%" height={400}>
                    <LineChart data={data.revenueData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis yAxisId="left" />
                      <YAxis yAxisId="right" orientation="right" />
                      <RechartsTooltip formatter={(value: any, name: string) => [
                        name === 'revenue' ? formatCurrency(value as number) : value,
                        name === 'revenue' ? 'Revenue' : 'Subscriptions'
                      ]} />
                      <Legend />
                      <Line
                        yAxisId="left"
                        type="monotone"
                        dataKey="revenue"
                        stroke="#8884d8"
                        strokeWidth={3}
                        name="Revenue"
                      />
                      <Line
                        yAxisId="right"
                        type="monotone"
                        dataKey="subscriptions"
                        stroke="#82ca9d"
                        strokeWidth={3}
                        name="Subscriptions"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                  
                  {/* Revenue Summary Cards */}
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Revenue Summary</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Revenue:</Typography>
                            <Typography variant="h6" color="primary">
                              {formatCurrency(data.overview.totalRevenue)}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Monthly Growth:</Typography>
                            <Typography variant="h6" color="success.main">
                              +{data.overview.monthlyGrowth}%
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Subscription Metrics</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Active Subscriptions:</Typography>
                            <Typography variant="h6" color="primary">
                              {data.revenueData?.[data.revenueData.length - 1]?.subscriptions || 0}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Growth Rate:</Typography>
                            <Typography variant="h6" color="success.main">
                              +{data.overview.userGrowth}%
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  </Box>
                </Box>
              </Box>
            )}

            {/* Company Growth */}
            {activeTab === 2 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Company Growth Trends
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '2fr 1fr' }, gap: 2, mb: 2 }}>
                  <ResponsiveContainer width="100%" height={400}>
                    <AreaChart data={data.companyGrowth}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <RechartsTooltip />
                      <Legend />
                      <Area
                        type="monotone"
                        dataKey="newCompanies"
                        stackId="1"
                        stroke="#8884d8"
                        fill="#8884d8"
                        name="New Companies"
                      />
                      <Area
                        type="monotone"
                        dataKey="activeCompanies"
                        stackId="1"
                        stroke="#82ca9d"
                        fill="#82ca9d"
                        name="Active Companies"
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                  
                  {/* Company Growth Summary */}
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Growth Summary</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Companies:</Typography>
                            <Typography variant="h6" color="primary">
                              {data.overview.totalCompanies}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Active Companies:</Typography>
                            <Typography variant="h6" color="success.main">
                              {data.overview.activeCompanies}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Growth Rate:</Typography>
                            <Typography variant="h6" color="success.main">
                              +{data.overview.monthlyGrowth}%
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Top Companies</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          {data.topCompanies?.slice(0, 3).map((company, index) => (
                            <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="body2" sx={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                {company.name}
                              </Typography>
                              <Typography variant="body2" color="primary">
                                {company.users} users
                              </Typography>
                            </Box>
                          ))}
                        </Box>
                      </CardContent>
                    </Card>
                  </Box>
                </Box>
              </Box>
            )}

            {/* User Activity */}
            {activeTab === 3 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Daily User Activity
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '2fr 1fr' }, gap: 2, mb: 2 }}>
                  <ResponsiveContainer width="100%" height={400}>
                    <BarChart data={data.userActivity}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="date" />
                      <YAxis />
                      <RechartsTooltip />
                      <Legend />
                      <Bar dataKey="activeUsers" fill="#8884d8" name="Active Users" />
                      <Bar dataKey="newUsers" fill="#82ca9d" name="New Users" />
                    </BarChart>
                  </ResponsiveContainer>
                  
                  {/* User Activity Summary */}
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>User Summary</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Users:</Typography>
                            <Typography variant="h6" color="primary">
                              {data.overview.totalUsers}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">User Growth:</Typography>
                            <Typography variant="h6" color="success.main">
                              +{data.overview.userGrowth}%
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Active Today:</Typography>
                            <Typography variant="h6" color="success.main">
                              {data.userActivity?.[data.userActivity.length - 1]?.activeUsers || 0}
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Recent Activity</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          {data.userActivity?.slice(-3).reverse().map((day, index) => (
                            <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="body2">
                                {new Date(day.date).toLocaleDateString()}
                              </Typography>
                              <Typography variant="body2" color="primary">
                                {day.activeUsers} active
                              </Typography>
                            </Box>
                          ))}
                        </Box>
                      </CardContent>
                    </Card>
                  </Box>
                </Box>
              </Box>
            )}

            {/* Subscription Distribution */}
            {activeTab === 6 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Subscription Plan Distribution
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '2fr 1fr' }, gap: 2, mb: 2 }}>
                  <ResponsiveContainer width="100%" height={400}>
                    <PieChart>
                      <Pie
                        data={data.subscriptionDistribution}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={(props: any) => `${props.payload?.plan || 'Unknown'}: ${props.payload?.companies || 0}`}
                        outerRadius={150}
                        fill="#8884d8"
                        dataKey="companies"
                      >
                        {data.subscriptionDistribution?.map((entry: any, index: number) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <RechartsTooltip formatter={(value: any, name: string) => [value, 'Companies']} />
                    </PieChart>
                  </ResponsiveContainer>
                  
                  {/* Subscription Summary */}
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Plan Distribution</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          {data.subscriptionDistribution?.map((plan, index) => (
                            <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Box 
                                  sx={{ 
                                    width: 12, 
                                    height: 12, 
                                    borderRadius: '50%', 
                                    backgroundColor: COLORS[index % COLORS.length] 
                                  }} 
                                />
                                <Typography variant="body2">
                                  {plan.plan}
                                </Typography>
                              </Box>
                              <Typography variant="body2" color="primary">
                                {plan.companies} ({plan.percentage}%)
                              </Typography>
                            </Box>
                          ))}
                        </Box>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Summary</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Plans:</Typography>
                            <Typography variant="h6" color="primary">
                              {data.subscriptionDistribution?.length || 0}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Companies:</Typography>
                            <Typography variant="h6" color="primary">
                              {data.subscriptionDistribution?.reduce((sum, plan) => sum + plan.companies, 0) || 0}
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  </Box>
                </Box>
              </Box>
            )}

            {/* Top Companies */}
            {activeTab === 7 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Top Performing Companies
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: '2fr 1fr' }, gap: 2, mb: 2 }}>
                  <ResponsiveContainer width="100%" height={400}>
                    <BarChart data={data.topCompanies} layout="horizontal">
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis type="number" />
                      <YAxis dataKey="name" type="category" width={150} />
                      <RechartsTooltip formatter={(value: any, name: string) => [
                        name === 'revenue' ? formatCurrency(value as number) : value,
                        name === 'revenue' ? 'Revenue' : 'Users'
                      ]} />
                      <Legend />
                      <Bar dataKey="users" fill="#8884d8" name="Users" />
                      <Bar dataKey="revenue" fill="#82ca9d" name="Revenue" />
                    </BarChart>
                  </ResponsiveContainer>
                  
                  {/* Top Companies Summary */}
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Company Rankings</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          {data.topCompanies?.map((company, index) => (
                            <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Typography variant="body2" color="text.secondary">
                                  #{index + 1}
                                </Typography>
                                <Typography variant="body2" sx={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                  {company.name}
                                </Typography>
                              </Box>
                              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                                <Typography variant="body2" color="primary">
                                  {company.users} users
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  {formatCurrency(company.revenue)}
                                </Typography>
                              </Box>
                            </Box>
                          ))}
                        </Box>
                      </CardContent>
                    </Card>
                    
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Performance Summary</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Users:</Typography>
                            <Typography variant="h6" color="primary">
                              {data.topCompanies?.reduce((sum, company) => sum + company.users, 0) || 0}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Total Revenue:</Typography>
                            <Typography variant="h6" color="primary">
                              {formatCurrency(data.topCompanies?.reduce((sum, company) => sum + company.revenue, 0) || 0)}
                            </Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2">Avg Revenue/User:</Typography>
                            <Typography variant="h6" color="primary">
                              {formatCurrency(
                                (data.topCompanies?.reduce((sum, company) => sum + company.revenue, 0) || 0) / 
                                (data.topCompanies?.reduce((sum, company) => sum + company.users, 0) || 1)
                              )}
                            </Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                  </Box>
                </Box>
              </Box>
            )}

            {/* Advanced User Analytics */}
            {activeTab === 4 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Advanced User Activity Analytics
                </Typography>
                <Box sx={{ mb: 3 }}>
                  <Button 
                    variant="outlined" 
                    onClick={() => fetchUserActivityData()}
                    disabled={userActivityLoading}
                    startIcon={userActivityLoading ? <CircularProgress size={16} /> : undefined}
                  >
                    {userActivityLoading ? 'Loading...' : (userActivityData ? 'Reload User Activity Data' : 'Load User Activity Data')}
                  </Button>
                </Box>
                {userActivityData && (
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Role Distribution</Typography>
                        <ResponsiveContainer width="100%" height={300}>
                          <PieChart>
                            <Pie
                              data={userActivityData.roleDistribution}
                              cx="50%"
                              cy="50%"
                              labelLine={false}
                              label={(props: any) => `${props.payload?.name || 'Unknown'}: ${props.payload?.value || 0}`}
                              outerRadius={100}
                              fill="#8884d8"
                              dataKey="value"
                            >
                              {userActivityData.roleDistribution.map((entry: any, index: number) => (
                                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                              ))}
                            </Pie>
                            <RechartsTooltip />
                          </PieChart>
                        </ResponsiveContainer>
                      </CardContent>
                    </Card>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Login Activity</Typography>
                        <ResponsiveContainer width="100%" height={300}>
                          <LineChart data={userActivityData.loginActivity}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="date" />
                            <YAxis />
                            <RechartsTooltip />
                            <Legend />
                            <Line type="monotone" dataKey="logins" stroke="#8884d8" name="Total Logins" />
                            <Line type="monotone" dataKey="uniqueUsers" stroke="#82ca9d" name="Unique Users" />
                          </LineChart>
                        </ResponsiveContainer>
                      </CardContent>
                    </Card>
                  </Box>
                )}
              </Box>
            )}

            {/* Company Performance Metrics */}
            {activeTab === 5 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Company Performance Metrics
                </Typography>
                <Box sx={{ mb: 3 }}>
                  <Button 
                    variant="outlined" 
                    onClick={() => fetchCompanyPerformanceData()}
                    disabled={companyPerformanceLoading}
                    startIcon={companyPerformanceLoading ? <CircularProgress size={16} /> : undefined}
                  >
                    {companyPerformanceLoading ? 'Loading...' : (companyPerformanceData ? 'Reload Company Performance Data' : 'Load Company Performance Data')}
                  </Button>
                </Box>
                {companyPerformanceData && (
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Performance Metrics</Typography>
                        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography>Total Companies:</Typography>
                            <Typography variant="h6">{companyPerformanceData.performanceMetrics.totalCompanies}</Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography>Avg Users/Company:</Typography>
                            <Typography variant="h6">{companyPerformanceData.performanceMetrics.averageUsersPerCompany}</Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography>Growth Rate:</Typography>
                            <Typography variant="h6">{companyPerformanceData.performanceMetrics.companyGrowthRate}%</Typography>
                          </Box>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography>Employee Utilization:</Typography>
                            <Typography variant="h6">{companyPerformanceData.performanceMetrics.averageEmployeeUtilization}%</Typography>
                          </Box>
                        </Box>
                      </CardContent>
                    </Card>
                    <Card>
                      <CardContent>
                        <Typography variant="h6" gutterBottom>Top Performing Companies</Typography>
                        <Box sx={{ maxHeight: 300, overflow: 'auto' }}>
                          {companyPerformanceData.performanceMetrics.topPerformingCompanies.map((company: any, index: number) => (
                            <Box key={index} sx={{ display: 'flex', justifyContent: 'space-between', mb: 1, p: 1, bgcolor: 'grey.50', borderRadius: 1 }}>
                              <Typography variant="body2">{company.name}</Typography>
                              <Typography variant="body2" fontWeight="bold">{company.userCount} users</Typography>
                            </Box>
                          ))}
                        </Box>
                      </CardContent>
                    </Card>
                  </Box>
                )}
              </Box>
            )}

            {/* Custom Reports */}
            {activeTab === 8 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Custom Reports & Export
                </Typography>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>Generate Reports</Typography>
                      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <Button 
                          variant="contained" 
                          onClick={() => handleGenerateReport('user_activity', 'json')}
                          disabled={reportLoading || reportButtonLoading === 'user_activity_json'}
                          startIcon={reportButtonLoading === 'user_activity_json' ? <CircularProgress size={16} /> : <DownloadIcon />}
                        >
                          User Activity Report (JSON)
                        </Button>
                        <Button 
                          variant="contained" 
                          onClick={() => handleGenerateReport('user_activity', 'csv')}
                          disabled={reportLoading || reportButtonLoading === 'user_activity_csv'}
                          startIcon={reportButtonLoading === 'user_activity_csv' ? <CircularProgress size={16} /> : <DownloadIcon />}
                        >
                          User Activity Report (CSV)
                        </Button>
                        <Button 
                          variant="contained" 
                          onClick={() => handleGenerateReport('company_performance', 'json')}
                          disabled={reportLoading || reportButtonLoading === 'company_performance_json'}
                          startIcon={reportButtonLoading === 'company_performance_json' ? <CircularProgress size={16} /> : <DownloadIcon />}
                        >
                          Company Performance Report (JSON)
                        </Button>
                        <Button 
                          variant="contained" 
                          onClick={() => handleGenerateReport('company_performance', 'csv')}
                          disabled={reportLoading || reportButtonLoading === 'company_performance_csv'}
                          startIcon={reportButtonLoading === 'company_performance_csv' ? <CircularProgress size={16} /> : <DownloadIcon />}
                        >
                          Company Performance Report (CSV)
                        </Button>
                        <Button 
                          variant="contained" 
                          onClick={() => handleGenerateReport('subscription_analysis', 'json')}
                          disabled={reportLoading || reportButtonLoading === 'subscription_analysis_json'}
                          startIcon={reportButtonLoading === 'subscription_analysis_json' ? <CircularProgress size={16} /> : <DownloadIcon />}
                        >
                          Subscription Analysis Report (JSON)
                        </Button>
                        <Button 
                          variant="contained" 
                          onClick={() => handleGenerateReport('system_overview', 'json')}
                          disabled={reportLoading || reportButtonLoading === 'system_overview_json'}
                          startIcon={reportButtonLoading === 'system_overview_json' ? <CircularProgress size={16} /> : <DownloadIcon />}
                        >
                          System Overview Report (JSON)
                        </Button>
                      </Box>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent>
                      <Typography variant="h6" gutterBottom>Report Information</Typography>
                      <Typography variant="body2" color="text.secondary" paragraph component="div">
                        Generate comprehensive reports in JSON or CSV format for further analysis.
                      </Typography>
                      <Typography variant="body2" color="text.secondary" paragraph component="div">
                        <strong>Available Reports:</strong>
                      </Typography>
                      <Box component="ul" sx={{ pl: 2 }}>
                        <Typography component="li" variant="body2">User Activity Report</Typography>
                        <Typography component="li" variant="body2">Company Performance Report</Typography>
                        <Typography component="li" variant="body2">Subscription Analysis Report</Typography>
                        <Typography component="li" variant="body2">System Overview Report</Typography>
                      </Box>
                    </CardContent>
                  </Card>
                </Box>
              </Box>
            )}
          </Paper>
        </>
      )}
    </Box>
  );
};

export default AnalyticsPage; 