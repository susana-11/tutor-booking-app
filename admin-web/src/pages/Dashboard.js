import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Avatar,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  People,
  School,
  EventNote,
  AttachMoney,
  TrendingUp,
  TrendingDown,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const fetchDashboardStats = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/admin/stats`);
      
      if (response.data.success) {
        setStats(response.data.data);
      }
    } catch (err) {
      console.error('Failed to fetch dashboard stats:', err);
      setError(err.response?.data?.message || 'Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const StatCard = ({ title, value, icon, trend, trendValue, color }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography color="textSecondary" gutterBottom variant="overline">
              {title}
            </Typography>
            {loading ? (
              <CircularProgress size={24} sx={{ my: 1 }} />
            ) : (
              <>
                <Typography variant="h4" component="h2">
                  {typeof value === 'number' && title.includes('Revenue') 
                    ? `ETB ${value.toLocaleString()}` 
                    : value?.toLocaleString() || 0}
                </Typography>
                {trend && trendValue && (
                  <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                    {trend === 'up' ? (
                      <TrendingUp sx={{ color: 'success.main', mr: 0.5 }} />
                    ) : (
                      <TrendingDown sx={{ color: 'error.main', mr: 0.5 }} />
                    )}
                    <Typography
                      variant="body2"
                      sx={{
                        color: trend === 'up' ? 'success.main' : 'error.main',
                      }}
                    >
                      {trendValue}
                    </Typography>
                  </Box>
                )}
              </>
            )}
          </Box>
          <Avatar sx={{ bgcolor: color, width: 56, height: 56 }}>
            {icon}
          </Avatar>
        </Box>
      </CardContent>
    </Card>
  );

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'completed':
        return 'info';
      case 'cancelled':
        return 'error';
      default:
        return 'default';
    }
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    });
  };

  if (error) {
    return (
      <Box>
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 4, fontWeight: 'bold' }}>
        Dashboard Overview
      </Typography>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Users"
            value={stats?.users?.total}
            icon={<People />}
            trend="up"
            trendValue={`${stats?.users?.newThisMonth || 0} new this month`}
            color="primary.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Tutors"
            value={stats?.tutors?.approved}
            icon={<School />}
            trend="up"
            trendValue={`${stats?.tutors?.pending || 0} pending`}
            color="success.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Bookings"
            value={stats?.bookings?.total}
            icon={<EventNote />}
            trend="up"
            trendValue={`${stats?.bookings?.thisMonth || 0} this month`}
            color="warning.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Platform Revenue"
            value={stats?.revenue?.platform}
            icon={<AttachMoney />}
            trend="up"
            trendValue={`ETB ${(stats?.revenue?.platformThisMonth || 0).toLocaleString()} this month`}
            color="error.main"
          />
        </Grid>
      </Grid>

      {/* Booking Status Breakdown */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Booking Status Breakdown
              </Typography>
              {loading ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                  <CircularProgress />
                </Box>
              ) : (
                <Grid container spacing={2} sx={{ mt: 1 }}>
                  <Grid item xs={6}>
                    <Box sx={{ textAlign: 'center', p: 2 }}>
                      <Typography variant="h4" color="warning.main">
                        {stats?.bookings?.pending || 0}
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Pending
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={6}>
                    <Box sx={{ textAlign: 'center', p: 2 }}>
                      <Typography variant="h4" color="info.main">
                        {stats?.bookings?.confirmed || 0}
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Confirmed
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={6}>
                    <Box sx={{ textAlign: 'center', p: 2 }}>
                      <Typography variant="h4" color="success.main">
                        {stats?.bookings?.completed || 0}
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Completed
                      </Typography>
                    </Box>
                  </Grid>
                  <Grid item xs={6}>
                    <Box sx={{ textAlign: 'center', p: 2 }}>
                      <Typography variant="h4" color="error.main">
                        {stats?.bookings?.cancelled || 0}
                      </Typography>
                      <Typography variant="body2" color="textSecondary">
                        Cancelled
                      </Typography>
                    </Box>
                  </Grid>
                </Grid>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Revenue Breakdown
              </Typography>
              {loading ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                  <CircularProgress />
                </Box>
              ) : (
                <Box sx={{ mt: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                    <Typography variant="body1">Total Revenue</Typography>
                    <Typography variant="h6">
                      ETB {(stats?.revenue?.total || 0).toLocaleString()}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2, p: 2, bgcolor: 'success.50', borderRadius: 1 }}>
                    <Typography variant="body1">Platform Fee (15%)</Typography>
                    <Typography variant="h6" color="success.main">
                      ETB {(stats?.revenue?.platform || 0).toLocaleString()}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', p: 2, bgcolor: 'info.50', borderRadius: 1 }}>
                    <Typography variant="body1">Tutor Earnings (85%)</Typography>
                    <Typography variant="h6" color="info.main">
                      ETB {(stats?.revenue?.tutors || 0).toLocaleString()}
                    </Typography>
                  </Box>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Activity */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Bookings
              </Typography>
              {loading ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
                  <CircularProgress />
                </Box>
              ) : stats?.recentActivity?.bookings?.length > 0 ? (
                <TableContainer>
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Student</TableCell>
                        <TableCell>Tutor</TableCell>
                        <TableCell>Subject</TableCell>
                        <TableCell>Date</TableCell>
                        <TableCell>Status</TableCell>
                        <TableCell>Amount</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {stats.recentActivity.bookings.map((booking) => (
                        <TableRow key={booking._id}>
                          <TableCell>
                            {booking.studentId?.firstName} {booking.studentId?.lastName}
                          </TableCell>
                          <TableCell>
                            {booking.tutorId?.firstName} {booking.tutorId?.lastName}
                          </TableCell>
                          <TableCell>{booking.subject?.name || 'N/A'}</TableCell>
                          <TableCell>{formatDate(booking.sessionDate)}</TableCell>
                          <TableCell>
                            <Chip
                              label={booking.status}
                              color={getStatusColor(booking.status)}
                              size="small"
                            />
                          </TableCell>
                          <TableCell>ETB {booking.totalAmount}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              ) : (
                <Typography color="textSecondary" sx={{ py: 4, textAlign: 'center' }}>
                  No recent bookings
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card sx={{ mb: 2 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Pending Actions
              </Typography>
              {loading ? (
                <CircularProgress size={24} />
              ) : (
                <>
                  <Box sx={{ mb: 2 }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="body2">Tutor Verifications</Typography>
                      <Typography variant="body2" color="warning.main">
                        {stats?.tutors?.pending || 0}
                      </Typography>
                    </Box>
                    <LinearProgress
                      variant="determinate"
                      value={Math.min(((stats?.tutors?.pending || 0) / 20) * 100, 100)}
                      color="warning"
                    />
                  </Box>
                  <Box>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                      <Typography variant="body2">Pending Bookings</Typography>
                      <Typography variant="body2" color="info.main">
                        {stats?.bookings?.pending || 0}
                      </Typography>
                    </Box>
                    <LinearProgress
                      variant="determinate"
                      value={Math.min(((stats?.bookings?.pending || 0) / 50) * 100, 100)}
                      color="info"
                    />
                  </Box>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Users
              </Typography>
              {loading ? (
                <CircularProgress size={24} />
              ) : stats?.recentActivity?.users?.length > 0 ? (
                <Box>
                  {stats.recentActivity.users.map((user) => (
                    <Box
                      key={user._id}
                      sx={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        mb: 2,
                        pb: 2,
                        borderBottom: '1px solid',
                        borderColor: 'divider',
                        '&:last-child': { borderBottom: 'none', mb: 0, pb: 0 },
                      }}
                    >
                      <Box>
                        <Typography variant="body2" fontWeight="medium">
                          {user.firstName} {user.lastName}
                        </Typography>
                        <Typography variant="caption" color="textSecondary">
                          {user.email}
                        </Typography>
                      </Box>
                      <Chip
                        label={user.role}
                        color={user.role === 'tutor' ? 'primary' : 'secondary'}
                        size="small"
                      />
                    </Box>
                  ))}
                </Box>
              ) : (
                <Typography color="textSecondary" variant="body2">
                  No recent users
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
