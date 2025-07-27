import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  Grid,
  IconButton,
  Tooltip
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  Clear as ClearIcon,
  Storage as StorageIcon,
  Speed as SpeedIcon
} from '@mui/icons-material';
import { useCache } from '../contexts/CacheContext';

const CacheStatsWidget: React.FC = () => {
  const { stats, clearAllCaches, refreshStats } = useCache();

  const getCacheColor = (type: string) => {
    switch (type) {
      case 'short': return 'error';
      case 'medium': return 'warning';
      case 'long': return 'info';
      case 'static': return 'success';
      default: return 'default';
    }
  };

  const getCacheLabel = (type: string) => {
    switch (type) {
      case 'short': return 'Short (30s)';
      case 'medium': return 'Medium (5m)';
      case 'long': return 'Long (30m)';
      case 'static': return 'Static (24h)';
      default: return type;
    }
  };

  const getHitRate = (cacheStats: any) => {
    if (!cacheStats || cacheStats.total === 0) return 0;
    return Math.round((cacheStats.valid / cacheStats.total) * 100);
  };

  const totalItems = Object.values(stats).reduce((sum: number, cache: any) => sum + (cache?.total || 0), 0);
  const totalValid = Object.values(stats).reduce((sum: number, cache: any) => sum + (cache?.valid || 0), 0);
  const overallHitRate = totalItems > 0 ? Math.round((totalValid / totalItems) * 100) : 0;

  return (
    <Card sx={{ minWidth: 275, mb: 2 }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
          <Box display="flex" alignItems="center">
            <StorageIcon sx={{ mr: 1 }} />
            <Typography variant="h6" component="div">
              Cache Statistics
            </Typography>
          </Box>
          <Box>
            <Tooltip title="Refresh Stats">
              <IconButton size="small" onClick={refreshStats}>
                <RefreshIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Clear All Caches">
              <IconButton size="small" onClick={clearAllCaches} color="error">
                <ClearIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>

        {/* Overall Stats */}
        <Box mb={2}>
          <Box display="flex" gap={2}>
            <Box flex={1} textAlign="center">
              <Typography variant="h4" color="primary">
                {totalItems}
              </Typography>
              <Typography variant="caption" color="textSecondary">
                Total Items
              </Typography>
            </Box>
            <Box flex={1} textAlign="center">
              <Typography variant="h4" color="success.main">
                {overallHitRate}%
              </Typography>
              <Typography variant="caption" color="textSecondary">
                Hit Rate
              </Typography>
            </Box>
          </Box>
        </Box>

        {/* Cache Type Breakdown */}
        <Typography variant="subtitle2" gutterBottom>
          Cache Breakdown:
        </Typography>
        <Box display="flex" flexWrap="wrap" gap={1} mb={2}>
          {Object.entries(stats).map(([type, cacheStats]: [string, any]) => (
            <Chip
              key={type}
              label={`${getCacheLabel(type)}: ${cacheStats?.valid || 0}/${cacheStats?.total || 0} (${getHitRate(cacheStats)}%)`}
              color={getCacheColor(type) as any}
              size="small"
              variant="outlined"
            />
          ))}
        </Box>

        {/* Performance Indicator */}
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box display="flex" alignItems="center">
            <SpeedIcon sx={{ mr: 1, color: overallHitRate > 70 ? 'success.main' : overallHitRate > 40 ? 'warning.main' : 'error.main' }} />
            <Typography variant="body2" color="textSecondary">
              Performance: {overallHitRate > 70 ? 'Excellent' : overallHitRate > 40 ? 'Good' : 'Poor'}
            </Typography>
          </Box>
          <Button
            size="small"
            variant="outlined"
            onClick={clearAllCaches}
            startIcon={<ClearIcon />}
          >
            Clear All
          </Button>
        </Box>
      </CardContent>
    </Card>
  );
};

export default CacheStatsWidget; 