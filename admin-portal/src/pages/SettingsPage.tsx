import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Switch,
  FormControlLabel,
  TextField,
  Button,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip
} from '@mui/material';

import {
  Settings as SettingsIcon,
  Security as SecurityIcon,
  Notifications as NotificationsIcon,
  Storage as StorageIcon,
  Payment as PaymentIcon,
  Save as SaveIcon,
  Refresh as RefreshIcon,
  Warning as WarningIcon
} from '@mui/icons-material';
import Layout from '../components/Layout';
import apiService from '../services/apiService';

interface SystemSettings {
  platform: {
    siteName: string;
    siteUrl: string;
    supportEmail: string;
    maxFileSize: number;
    allowedFileTypes: string[];
    maintenanceMode: boolean;
    debugMode: boolean;
  };
  security: {
    passwordMinLength: number;
    requireSpecialChars: boolean;
    requireNumbers: boolean;
    requireUppercase: boolean;
    sessionTimeout: number;
    maxLoginAttempts: number;
    enableTwoFactor: boolean;
    ipWhitelist: string[];
  };
  notifications: {
    emailEnabled: boolean;
    smsEnabled: boolean;
    pushEnabled: boolean;
    emailProvider: string;
    smsProvider: string;
    defaultFromEmail: string;
    alertThreshold: number;
  };
  backup: {
    autoBackup: boolean;
    backupFrequency: string;
    retentionDays: number;
    backupLocation: string;
    lastBackup: string;
    nextBackup: string;
  };
  payment: {
    stripeEnabled: boolean;
    paypalEnabled: boolean;
    defaultCurrency: string;
    taxRate: number;
    invoicePrefix: string;
  };
}

const SettingsPage: React.FC = () => {
  const [settings, setSettings] = useState<SystemSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [activeTab, setActiveTab] = useState(0);
  const [hasChanges, setHasChanges] = useState(false);

  const fetchSettings = async () => {
    try {
      setLoading(true);
      setError('');
      
      // Fetch settings from backend
      const response = await apiService.get<any>('/api/super-admin/settings');
      setSettings(response);
    } catch (err: any) {
      console.error('Error fetching settings:', err);
      setError('Failed to load settings');
      
      // Set default settings for development
      setSettings({
        platform: {
          siteName: 'SNS Rooster',
          siteUrl: 'https://snstechservices.com.au',
          supportEmail: 'support@snstechservices.com.au',
          maxFileSize: 10,
          allowedFileTypes: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
          maintenanceMode: false,
          debugMode: false
        },
        security: {
          passwordMinLength: 8,
          requireSpecialChars: true,
          requireNumbers: true,
          requireUppercase: true,
          sessionTimeout: 30,
          maxLoginAttempts: 5,
          enableTwoFactor: false,
          ipWhitelist: []
        },
        notifications: {
          emailEnabled: true,
          smsEnabled: false,
          pushEnabled: true,
          emailProvider: 'smtp',
          smsProvider: 'twilio',
          defaultFromEmail: 'noreply@snstechservices.com.au',
          alertThreshold: 10
        },
        backup: {
          autoBackup: true,
          backupFrequency: 'daily',
          retentionDays: 30,
          backupLocation: 'local',
          lastBackup: '2024-12-20T10:30:00Z',
          nextBackup: '2024-12-21T02:00:00Z'
        },
        payment: {
          stripeEnabled: true,
          paypalEnabled: false,
          defaultCurrency: 'USD',
          taxRate: 10.0,
          invoicePrefix: 'SNS'
        }
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleSettingChange = (section: keyof SystemSettings, field: string, value: any) => {
    if (!settings) return;
    
    setSettings(prev => ({
      ...prev!,
      [section]: {
        ...prev![section],
        [field]: value
      }
    }));
    setHasChanges(true);
  };

  const handleSave = async () => {
    if (!settings) return;
    
    try {
      setSaving(true);
      setError('');
      setSuccess('');
      
      await apiService.put('/api/super-admin/settings', settings);
      
      setSuccess('Settings saved successfully!');
      setHasChanges(false);
      
      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: any) {
      console.error('Error saving settings:', err);
      setError('Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    fetchSettings();
    setHasChanges(false);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
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
        <Paper sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Box>
              <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 700 }}>
                System Settings
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Configure platform settings, security, notifications, and more
              </Typography>
            </Box>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Button
                variant="outlined"
                startIcon={<RefreshIcon />}
                onClick={handleReset}
                disabled={saving}
              >
                Reset
              </Button>
              <Button
                variant="contained"
                startIcon={saving ? <CircularProgress size={20} /> : <SaveIcon />}
                onClick={handleSave}
                disabled={saving || !hasChanges}
              >
                {saving ? 'Saving...' : 'Save Changes'}
              </Button>
            </Box>
          </Box>
          {hasChanges && (
            <Chip
              icon={<WarningIcon />}
              label="You have unsaved changes"
              color="warning"
              variant="outlined"
            />
          )}
        </Paper>

        {/* Error/Success Alerts */}
        {error && (
          <Alert severity="error" onClose={() => setError('')}>
            {error}
          </Alert>
        )}
        {success && (
          <Alert severity="success" onClose={() => setSuccess('')}>
            {success}
          </Alert>
        )}

        {settings && (
          <Paper sx={{ p: 3 }}>
            <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)} sx={{ mb: 3 }}>
              <Tab label="Platform" icon={<SettingsIcon />} />
              <Tab label="Security" icon={<SecurityIcon />} />
              <Tab label="Notifications" icon={<NotificationsIcon />} />
              <Tab label="Backup" icon={<StorageIcon />} />
              <Tab label="Payment" icon={<PaymentIcon />} />
            </Tabs>

            {/* Platform Settings */}
            {activeTab === 0 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Platform Configuration
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                  <TextField
                    fullWidth
                    label="Site Name"
                    value={settings.platform.siteName}
                    onChange={(e) => handleSettingChange('platform', 'siteName', e.target.value)}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Site URL"
                    value={settings.platform.siteUrl}
                    onChange={(e) => handleSettingChange('platform', 'siteUrl', e.target.value)}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Support Email"
                    value={settings.platform.supportEmail}
                    onChange={(e) => handleSettingChange('platform', 'supportEmail', e.target.value)}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Max File Size (MB)"
                    type="number"
                    value={settings.platform.maxFileSize}
                    onChange={(e) => handleSettingChange('platform', 'maxFileSize', parseInt(e.target.value))}
                    margin="normal"
                  />
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.platform.maintenanceMode}
                          onChange={(e) => handleSettingChange('platform', 'maintenanceMode', e.target.checked)}
                        />
                      }
                      label="Maintenance Mode"
                    />
                    <Typography variant="caption" color="text.secondary" display="block">
                      When enabled, only super admins can access the platform
                    </Typography>
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.platform.debugMode}
                          onChange={(e) => handleSettingChange('platform', 'debugMode', e.target.checked)}
                        />
                      }
                      label="Debug Mode"
                    />
                    <Typography variant="caption" color="text.secondary" display="block">
                      Enable detailed error logging and debugging information
                    </Typography>
                  </Box>
                </Box>
              </Box>
            )}

            {/* Security Settings */}
            {activeTab === 1 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Security Configuration
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                  <TextField
                    fullWidth
                    label="Minimum Password Length"
                    type="number"
                    value={settings.security.passwordMinLength}
                    onChange={(e) => handleSettingChange('security', 'passwordMinLength', parseInt(e.target.value))}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Session Timeout (minutes)"
                    type="number"
                    value={settings.security.sessionTimeout}
                    onChange={(e) => handleSettingChange('security', 'sessionTimeout', parseInt(e.target.value))}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Max Login Attempts"
                    type="number"
                    value={settings.security.maxLoginAttempts}
                    onChange={(e) => handleSettingChange('security', 'maxLoginAttempts', parseInt(e.target.value))}
                    margin="normal"
                  />
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.security.requireSpecialChars}
                          onChange={(e) => handleSettingChange('security', 'requireSpecialChars', e.target.checked)}
                        />
                      }
                      label="Require Special Characters in Passwords"
                    />
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.security.requireNumbers}
                          onChange={(e) => handleSettingChange('security', 'requireNumbers', e.target.checked)}
                        />
                      }
                      label="Require Numbers in Passwords"
                    />
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.security.requireUppercase}
                          onChange={(e) => handleSettingChange('security', 'requireUppercase', e.target.checked)}
                        />
                      }
                      label="Require Uppercase Letters in Passwords"
                    />
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.security.enableTwoFactor}
                          onChange={(e) => handleSettingChange('security', 'enableTwoFactor', e.target.checked)}
                        />
                      }
                      label="Enable Two-Factor Authentication"
                    />
                  </Box>
                </Box>
              </Box>
            )}

            {/* Notification Settings */}
            {activeTab === 2 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Notification Configuration
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                  <FormControl fullWidth margin="normal">
                    <InputLabel>Email Provider</InputLabel>
                    <Select
                      value={settings.notifications.emailProvider}
                      onChange={(e) => handleSettingChange('notifications', 'emailProvider', e.target.value)}
                      label="Email Provider"
                    >
                      <MenuItem value="smtp">SMTP</MenuItem>
                      <MenuItem value="sendgrid">SendGrid</MenuItem>
                      <MenuItem value="mailgun">Mailgun</MenuItem>
                    </Select>
                  </FormControl>
                  <FormControl fullWidth margin="normal">
                    <InputLabel>SMS Provider</InputLabel>
                    <Select
                      value={settings.notifications.smsProvider}
                      onChange={(e) => handleSettingChange('notifications', 'smsProvider', e.target.value)}
                      label="SMS Provider"
                    >
                      <MenuItem value="twilio">Twilio</MenuItem>
                      <MenuItem value="aws-sns">AWS SNS</MenuItem>
                      <MenuItem value="nexmo">Nexmo</MenuItem>
                    </Select>
                  </FormControl>
                  <TextField
                    fullWidth
                    label="Default From Email"
                    value={settings.notifications.defaultFromEmail}
                    onChange={(e) => handleSettingChange('notifications', 'defaultFromEmail', e.target.value)}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Alert Threshold"
                    type="number"
                    value={settings.notifications.alertThreshold}
                    onChange={(e) => handleSettingChange('notifications', 'alertThreshold', parseInt(e.target.value))}
                    margin="normal"
                  />
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.notifications.emailEnabled}
                          onChange={(e) => handleSettingChange('notifications', 'emailEnabled', e.target.checked)}
                        />
                      }
                      label="Enable Email Notifications"
                    />
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.notifications.smsEnabled}
                          onChange={(e) => handleSettingChange('notifications', 'smsEnabled', e.target.checked)}
                        />
                      }
                      label="Enable SMS Notifications"
                    />
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.notifications.pushEnabled}
                          onChange={(e) => handleSettingChange('notifications', 'pushEnabled', e.target.checked)}
                        />
                      }
                      label="Enable Push Notifications"
                    />
                  </Box>
                </Box>
              </Box>
            )}

            {/* Backup Settings */}
            {activeTab === 3 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Backup & Maintenance
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                  <FormControl fullWidth margin="normal">
                    <InputLabel>Backup Frequency</InputLabel>
                    <Select
                      value={settings.backup.backupFrequency}
                      onChange={(e) => handleSettingChange('backup', 'backupFrequency', e.target.value)}
                      label="Backup Frequency"
                    >
                      <MenuItem value="hourly">Hourly</MenuItem>
                      <MenuItem value="daily">Daily</MenuItem>
                      <MenuItem value="weekly">Weekly</MenuItem>
                      <MenuItem value="monthly">Monthly</MenuItem>
                    </Select>
                  </FormControl>
                  <TextField
                    fullWidth
                    label="Retention Days"
                    type="number"
                    value={settings.backup.retentionDays}
                    onChange={(e) => handleSettingChange('backup', 'retentionDays', parseInt(e.target.value))}
                    margin="normal"
                  />
                  <FormControl fullWidth margin="normal">
                    <InputLabel>Backup Location</InputLabel>
                    <Select
                      value={settings.backup.backupLocation}
                      onChange={(e) => handleSettingChange('backup', 'backupLocation', e.target.value)}
                      label="Backup Location"
                    >
                      <MenuItem value="local">Local Storage</MenuItem>
                      <MenuItem value="s3">AWS S3</MenuItem>
                      <MenuItem value="gcs">Google Cloud Storage</MenuItem>
                      <MenuItem value="azure">Azure Blob Storage</MenuItem>
                    </Select>
                  </FormControl>
                  <TextField
                    fullWidth
                    label="Last Backup"
                    value={formatDate(settings.backup.lastBackup)}
                    margin="normal"
                    InputProps={{ readOnly: true }}
                  />
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.backup.autoBackup}
                          onChange={(e) => handleSettingChange('backup', 'autoBackup', e.target.checked)}
                        />
                      }
                      label="Enable Automatic Backups"
                    />
                  </Box>
                </Box>
              </Box>
            )}

            {/* Payment Settings */}
            {activeTab === 4 && (
              <Box>
                <Typography variant="h6" gutterBottom>
                  Payment Configuration
                </Typography>
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1fr 1fr' }, gap: 3 }}>
                  <FormControl fullWidth margin="normal">
                    <InputLabel>Default Currency</InputLabel>
                    <Select
                      value={settings.payment.defaultCurrency}
                      onChange={(e) => handleSettingChange('payment', 'defaultCurrency', e.target.value)}
                      label="Default Currency"
                    >
                      <MenuItem value="USD">USD ($)</MenuItem>
                      <MenuItem value="EUR">EUR (€)</MenuItem>
                      <MenuItem value="GBP">GBP (£)</MenuItem>
                      <MenuItem value="AUD">AUD ($)</MenuItem>
                      <MenuItem value="CAD">CAD ($)</MenuItem>
                    </Select>
                  </FormControl>
                  <TextField
                    fullWidth
                    label="Tax Rate (%)"
                    type="number"
                    value={settings.payment.taxRate}
                    onChange={(e) => handleSettingChange('payment', 'taxRate', parseFloat(e.target.value))}
                    margin="normal"
                  />
                  <TextField
                    fullWidth
                    label="Invoice Prefix"
                    value={settings.payment.invoicePrefix}
                    onChange={(e) => handleSettingChange('payment', 'invoicePrefix', e.target.value)}
                    margin="normal"
                  />
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.payment.stripeEnabled}
                          onChange={(e) => handleSettingChange('payment', 'stripeEnabled', e.target.checked)}
                        />
                      }
                      label="Enable Stripe Payments"
                    />
                  </Box>
                  <Box sx={{ gridColumn: { xs: '1', md: '1 / -1' } }}>
                    <FormControlLabel
                      control={
                        <Switch
                          checked={settings.payment.paypalEnabled}
                          onChange={(e) => handleSettingChange('payment', 'paypalEnabled', e.target.checked)}
                        />
                      }
                      label="Enable PayPal Payments"
                    />
                  </Box>
                </Box>
              </Box>
            )}
          </Paper>
        )}
      </Box>
    </Layout>
  );
};

export default SettingsPage; 