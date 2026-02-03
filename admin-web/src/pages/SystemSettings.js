import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Grid,
  Switch,
  FormControlLabel,
  Divider,
  Tab,
  Tabs,
  Alert,
} from '@mui/material';
import { Save, Refresh } from '@mui/icons-material';
import toast from 'react-hot-toast';

const SystemSettings = () => {
  const [tabValue, setTabValue] = useState(0);
  const [settings, setSettings] = useState({
    // General Settings
    siteName: 'Tutor Booking Platform',
    siteDescription: 'Connect students with qualified tutors',
    supportEmail: 'support@tutorbooking.com',
    maintenanceMode: false,
    
    // Payment Settings
    platformCommission: 10,
    minimumPayout: 50,
    paymentMethods: {
      creditCard: true,
      paypal: true,
      bankTransfer: false,
    },
    
    // Notification Settings
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: true,
    
    // Security Settings
    twoFactorAuth: false,
    sessionTimeout: 30,
    passwordMinLength: 8,
    
    // Booking Settings
    maxAdvanceBooking: 30,
    minCancellationTime: 24,
    autoApproveBookings: false,
  });

  const handleSave = async () => {
    try {
      // API call would go here
      toast.success('Settings saved successfully');
    } catch (error) {
      toast.error('Failed to save settings');
    }
  };

  const handleReset = () => {
    if (window.confirm('Are you sure you want to reset all settings to default?')) {
      // Reset to default values
      toast.info('Settings reset to default');
    }
  };

  const TabPanel = ({ children, value, index }) => (
    <div hidden={value !== index}>
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" sx={{ mb: 3 }}>
        System Settings
      </Typography>

      <Card>
        <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
          <Tab label="General" />
          <Tab label="Payment" />
          <Tab label="Notifications" />
          <Tab label="Security" />
          <Tab label="Booking" />
        </Tabs>

        <TabPanel value={tabValue} index={0}>
          <Typography variant="h6" gutterBottom>
            General Settings
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Site Name"
                value={settings.siteName}
                onChange={(e) => setSettings({ ...settings, siteName: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Support Email"
                value={settings.supportEmail}
                onChange={(e) => setSettings({ ...settings, supportEmail: e.target.value })}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Site Description"
                value={settings.siteDescription}
                onChange={(e) => setSettings({ ...settings, siteDescription: e.target.value })}
                multiline
                rows={3}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.maintenanceMode}
                    onChange={(e) => setSettings({ ...settings, maintenanceMode: e.target.checked })}
                  />
                }
                label="Maintenance Mode"
              />
              {settings.maintenanceMode && (
                <Alert severity="warning" sx={{ mt: 1 }}>
                  Maintenance mode will make the site unavailable to users
                </Alert>
              )}
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={tabValue} index={1}>
          <Typography variant="h6" gutterBottom>
            Payment Settings
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Platform Commission (%)"
                type="number"
                value={settings.platformCommission}
                onChange={(e) => setSettings({ ...settings, platformCommission: parseInt(e.target.value) })}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Minimum Payout ($)"
                type="number"
                value={settings.minimumPayout}
                onChange={(e) => setSettings({ ...settings, minimumPayout: parseInt(e.target.value) })}
              />
            </Grid>
            <Grid item xs={12}>
              <Typography variant="subtitle1" gutterBottom>
                Payment Methods
              </Typography>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.paymentMethods.creditCard}
                    onChange={(e) => setSettings({
                      ...settings,
                      paymentMethods: { ...settings.paymentMethods, creditCard: e.target.checked }
                    })}
                  />
                }
                label="Credit Card"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.paymentMethods.paypal}
                    onChange={(e) => setSettings({
                      ...settings,
                      paymentMethods: { ...settings.paymentMethods, paypal: e.target.checked }
                    })}
                  />
                }
                label="PayPal"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.paymentMethods.bankTransfer}
                    onChange={(e) => setSettings({
                      ...settings,
                      paymentMethods: { ...settings.paymentMethods, bankTransfer: e.target.checked }
                    })}
                  />
                }
                label="Bank Transfer"
              />
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={tabValue} index={2}>
          <Typography variant="h6" gutterBottom>
            Notification Settings
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.emailNotifications}
                    onChange={(e) => setSettings({ ...settings, emailNotifications: e.target.checked })}
                  />
                }
                label="Email Notifications"
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.smsNotifications}
                    onChange={(e) => setSettings({ ...settings, smsNotifications: e.target.checked })}
                  />
                }
                label="SMS Notifications"
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.pushNotifications}
                    onChange={(e) => setSettings({ ...settings, pushNotifications: e.target.checked })}
                  />
                }
                label="Push Notifications"
              />
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={tabValue} index={3}>
          <Typography variant="h6" gutterBottom>
            Security Settings
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Session Timeout (minutes)"
                type="number"
                value={settings.sessionTimeout}
                onChange={(e) => setSettings({ ...settings, sessionTimeout: parseInt(e.target.value) })}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Minimum Password Length"
                type="number"
                value={settings.passwordMinLength}
                onChange={(e) => setSettings({ ...settings, passwordMinLength: parseInt(e.target.value) })}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.twoFactorAuth}
                    onChange={(e) => setSettings({ ...settings, twoFactorAuth: e.target.checked })}
                  />
                }
                label="Require Two-Factor Authentication"
              />
            </Grid>
          </Grid>
        </TabPanel>

        <TabPanel value={tabValue} index={4}>
          <Typography variant="h6" gutterBottom>
            Booking Settings
          </Typography>
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Max Advance Booking (days)"
                type="number"
                value={settings.maxAdvanceBooking}
                onChange={(e) => setSettings({ ...settings, maxAdvanceBooking: parseInt(e.target.value) })}
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Min Cancellation Time (hours)"
                type="number"
                value={settings.minCancellationTime}
                onChange={(e) => setSettings({ ...settings, minCancellationTime: parseInt(e.target.value) })}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={settings.autoApproveBookings}
                    onChange={(e) => setSettings({ ...settings, autoApproveBookings: e.target.checked })}
                  />
                }
                label="Auto-approve Bookings"
              />
            </Grid>
          </Grid>
        </TabPanel>

        <Divider />
        
        <Box sx={{ p: 3, display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={handleReset}
          >
            Reset to Default
          </Button>
          <Button
            variant="contained"
            startIcon={<Save />}
            onClick={handleSave}
          >
            Save Settings
          </Button>
        </Box>
      </Card>
    </Box>
  );
};

export default SystemSettings;