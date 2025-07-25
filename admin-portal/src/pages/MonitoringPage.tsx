import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip
} from '@mui/material';
import Layout from '../components/Layout';
import {
  Refresh as RefreshIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Error as ErrorIcon,
  Memory as MemoryIcon,
  Storage as StorageIcon,
  Speed as SpeedIcon,
  Security as SecurityIcon
} from '@mui/icons-material';
import apiService from '../services/apiService';

interface HealthData {
  status: string;
  timestamp: string;
  uptime: number;
  memory: {
    rss: number;
    heapTotal: number;
    heapUsed: number;
    external: number;
  };
  database: string;
  environment: string;
  version: string;
}

interface DetailedHealthData {
  status: string;
  timestamp: string;
  uptime: number;
  memory: {
    rss: number;
    heapTotal: number;
    heapUsed: number;
    external: number;
    system: {
      total: number;
      free: number;
      used: number;
    };
  };
  cpu: {
    load: number[];
    cores: number;
  };
  database: {
    state: number;
    host: string;
    name: string;
    readyState: string;
  };
  environment: string;
  version: string;
  nodeVersion: string;
  platform: string;
  arch: string;
}

interface ErrorStats {
  total: number;
  bySeverity: {
    [key: string]: number;
  };
  recent: Array<{
    timestamp: string;
    error: {
      message: string;
      name: string;
    };
    severity: string;
  }>;
}

interface PerformanceStats {
  total: number;
  averageResponseTime: number;
  recent: Array<{
    timestamp: string;
    metrics: {
      duration: string;
      method: string;
      url: string;
    };
  }>;
}

const MonitoringPage: React.FC = () => {
  const [healthData, setHealthData] = useState<HealthData | null>(null);
  const [detailedHealth, setDetailedHealth] = useState<DetailedHealthData | null>(null);
  const [errorStats, setErrorStats] = useState<ErrorStats | null>(null);
  const [performanceStats, setPerformanceStats] = useState<PerformanceStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchHealthData = async () => {
    try {
      const response = await apiService.get<HealthData>('/api/monitoring/health');
      setHealthData(response);
    } catch (err) {
      console.error('Error fetching health data:', err);
    }
  };

  const fetchDetailedHealth = async () => {
    try {
      const response = await apiService.get<DetailedHealthData>('/api/monitoring/health/detailed');
      setDetailedHealth(response);
    } catch (err) {
      console.error('Error fetching detailed health data:', err);
    }
  };

  const fetchErrorStats = async () => {
    try {
      const response = await apiService.get<{data: ErrorStats}>('/api/monitoring/errors');
      setErrorStats(response.data);
    } catch (err) {
      console.error('Error fetching error stats:', err);
    }
  };

  const fetchPerformanceStats = async () => {
    try {
      const response = await apiService.get<{data: PerformanceStats}>('/api/monitoring/performance');
      setPerformanceStats(response.data);
    } catch (err) {
      console.error('Error fetching performance stats:', err);
    }
  };

  const fetchAllData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      await Promise.all([
        fetchHealthData(),
        fetchDetailedHealth(),
        fetchErrorStats(),
        fetchPerformanceStats()
      ]);
    } catch (err) {
      setError('Failed to fetch monitoring data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllData();
    
    // Refresh data every 30 seconds
    const interval = setInterval(fetchAllData, 30000);
    return () => clearInterval(interval);
  }, []);

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (days > 0) return `${days}d ${hours}h ${minutes}m`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
        return 'success';
      case 'unhealthy':
        return 'error';
      default:
        return 'warning';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'error';
      case 'high':
        return 'warning';
      case 'medium':
        return 'info';
      default:
        return 'default';
    }
  };

  if (loading) {
    return (
      <Layout>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
          <CircularProgress />
        </Box>
      </Layout>
    );
  }

  return (
    <Layout>
      <Box p={3}>
        <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
          <Typography variant="h4" component="h1">
            System Monitoring
          </Typography>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={fetchAllData}
          >
            Refresh
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        {/* Health Status Overview */}
        <Box display="flex" flexWrap="wrap" gap={2} mb={3}>
          <Card sx={{ minWidth: 250, flex: '1 1 250px' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <CheckCircleIcon 
                  color={healthData?.status === 'healthy' ? 'success' : 'error'} 
                  sx={{ mr: 1 }}
                />
                <Typography variant="h6">System Status</Typography>
              </Box>
              <Chip 
                label={healthData?.status || 'Unknown'} 
                color={getStatusColor(healthData?.status || '')}
                size="small"
              />
            </CardContent>
          </Card>

          <Card sx={{ minWidth: 250, flex: '1 1 250px' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <StorageIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Database</Typography>
              </Box>
              <Chip 
                label={healthData?.database || 'Unknown'} 
                color={healthData?.database === 'connected' ? 'success' : 'error'}
                size="small"
              />
            </CardContent>
          </Card>

          <Card sx={{ minWidth: 250, flex: '1 1 250px' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <SpeedIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Uptime</Typography>
              </Box>
              <Typography variant="body2">
                {healthData?.uptime ? formatUptime(healthData.uptime) : 'Unknown'}
              </Typography>
            </CardContent>
          </Card>

          <Card sx={{ minWidth: 250, flex: '1 1 250px' }}>
            <CardContent>
              <Box display="flex" alignItems="center" mb={2}>
                <MemoryIcon color="primary" sx={{ mr: 1 }} />
                <Typography variant="h6">Memory Usage</Typography>
              </Box>
              <Typography variant="body2">
                {healthData?.memory ? formatBytes(healthData.memory.heapUsed) : 'Unknown'}
              </Typography>
            </CardContent>
          </Card>
        </Box>

        {/* Detailed System Information */}
        {detailedHealth && (
          <Box display="flex" flexWrap="wrap" gap={2} mb={3}>
            <Card sx={{ minWidth: 300, flex: '1 1 300px' }}>
              <CardContent>
                <Typography variant="h6" mb={2}>System Information</Typography>
                <Box>
                  <Typography variant="body2">
                    <strong>Environment:</strong> {detailedHealth.environment}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Version:</strong> {detailedHealth.version}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Node Version:</strong> {detailedHealth.nodeVersion}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Platform:</strong> {detailedHealth.platform} ({detailedHealth.arch})
                  </Typography>
                  <Typography variant="body2">
                    <strong>CPU Cores:</strong> {detailedHealth.cpu.cores}
                  </Typography>
                </Box>
              </CardContent>
            </Card>

            <Card sx={{ minWidth: 300, flex: '1 1 300px' }}>
              <CardContent>
                <Typography variant="h6" mb={2}>Memory Details</Typography>
                <Box>
                  <Typography variant="body2">
                    <strong>Process Memory:</strong> {formatBytes(detailedHealth.memory.heapUsed)} / {formatBytes(detailedHealth.memory.heapTotal)}
                  </Typography>
                  <Typography variant="body2">
                    <strong>System Memory:</strong> {formatBytes(detailedHealth.memory.system.used)} / {formatBytes(detailedHealth.memory.system.total)}
                  </Typography>
                  <Typography variant="body2">
                    <strong>Memory Usage:</strong> {((detailedHealth.memory.system.used / detailedHealth.memory.system.total) * 100).toFixed(1)}%
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Box>
        )}

        {/* Error and Performance Statistics */}
        <Box display="flex" flexWrap="wrap" gap={2}>
          {errorStats && (
            <Card sx={{ minWidth: 400, flex: '1 1 400px' }}>
              <CardContent>
                <Typography variant="h6" mb={2}>Error Statistics</Typography>
                <Box display="flex" flexWrap="wrap" gap={2} mb={2}>
                  <Typography variant="body2" sx={{ minWidth: 200 }}>
                    <strong>Total Errors:</strong> {errorStats.total}
                  </Typography>
                  {Object.entries(errorStats.bySeverity).map(([severity, count]) => (
                    <Chip 
                      key={severity}
                      label={`${severity}: ${count}`}
                      color={getSeverityColor(severity)}
                      size="small"
                    />
                  ))}
                </Box>
                
                {errorStats.recent.length > 0 && (
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Time</TableCell>
                          <TableCell>Error</TableCell>
                          <TableCell>Severity</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {errorStats.recent.slice(0, 5).map((error, index) => (
                          <TableRow key={index}>
                            <TableCell>
                              {new Date(error.timestamp).toLocaleTimeString()}
                            </TableCell>
                            <TableCell>
                              <Tooltip title={error.error.message}>
                                <Typography variant="body2" noWrap>
                                  {error.error.message}
                                </Typography>
                              </Tooltip>
                            </TableCell>
                            <TableCell>
                              <Chip 
                                label={error.severity} 
                                color={getSeverityColor(error.severity)}
                                size="small"
                              />
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}
              </CardContent>
            </Card>
          )}

          {performanceStats && (
            <Card sx={{ minWidth: 400, flex: '1 1 400px' }}>
              <CardContent>
                <Typography variant="h6" mb={2}>Performance Statistics</Typography>
                <Box display="flex" flexWrap="wrap" gap={2} mb={2}>
                  <Typography variant="body2" sx={{ minWidth: 200 }}>
                    <strong>Total Requests:</strong> {performanceStats.total}
                  </Typography>
                  <Typography variant="body2" sx={{ minWidth: 200 }}>
                    <strong>Average Response Time:</strong> {performanceStats.averageResponseTime}ms
                  </Typography>
                </Box>
                
                {performanceStats.recent.length > 0 && (
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Time</TableCell>
                          <TableCell>Method</TableCell>
                          <TableCell>URL</TableCell>
                          <TableCell>Duration</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {performanceStats.recent.slice(0, 5).map((perf, index) => (
                          <TableRow key={index}>
                            <TableCell>
                              {new Date(perf.timestamp).toLocaleTimeString()}
                            </TableCell>
                            <TableCell>
                              <Chip 
                                label={perf.metrics.method} 
                                size="small"
                                color={perf.metrics.method === 'GET' ? 'success' : 'primary'}
                              />
                            </TableCell>
                            <TableCell>
                              <Tooltip title={perf.metrics.url}>
                                <Typography variant="body2" noWrap>
                                  {perf.metrics.url}
                                </Typography>
                              </Tooltip>
                            </TableCell>
                            <TableCell>
                              {perf.metrics.duration}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}
              </CardContent>
            </Card>
          )}
        </Box>
      </Box>
    </Layout>
  );
};

export default MonitoringPage; 