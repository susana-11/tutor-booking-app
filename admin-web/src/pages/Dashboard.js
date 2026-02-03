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
  Paper,
  Chip,
  IconButton,
} from '@mui/material';
import {
  People,
  School,
  EventNote,
  AttachMoney,
  TrendingUp,
  TrendingDown,
  MoreVert,
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
  BarChart,
  Bar,
} from 'recharts';

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalUsers: 1250,
    totalTutors: 89,
    totalBookings: 456,
    totalRevenue: 12450,
    pendingVerifications: 12,
    activeDisputes: 3,
  });

  const [recentBookings] = useState([
    {
      id: 1,
      student: 'John Doe',
      tutor: 'Dr. Sarah Johnson',
      subject: 'Mathematics',
      date: '2026-01-30',
      status: 'confirmed',
      amount: 45,
    },
    {
      id: 2,
      student: 'Jane Smith',
      tutor: 'Prof. Michael Chen',
      subject: 'Physics',
      date: '2026-01-30',
      status: 'pending',
      amount: 55,
    },
    {
      id: 3,
      student: 'Bob Wilson',
      tutor: 'Ms. Emily Davis',
      subject: 'English',
      date: '2026-01-29',
      status: 'completed',
      amount: 35,
    },
    {
      id: 4,
      student: 'Alice Brown',
      tutor: 'Dr. Ahmed Hassan',
      subject: 'Chemistry',
      date: '2026-01-29',
      status: 'cancelled',
      amount: 50,
    },
  ]);

  const [chartData] = useState([
    { name: 'Jan', bookings: 65, revenue: 2400 },
    { name: 'Feb', bookings: 59, revenue: 2210 },
    { name: 'Mar', bookings: 80, revenue: 2290 },
    { name: 'Apr', bookings: 81, revenue: 2000 },
    { name: 'May', bookings: 56, revenue: 2181 },
    { name: 'Jun', bookings: 55, revenue: 2500 },
    { name: 'Jul', bookings: 40, revenue: 2100 },
  ]);

  const [subjectData] = useState([
    { name: 'Mathematics', value: 35, color: '#0088FE' },
    { name: 'Physics', value: 25, color: '#00C49F' },
    { name: 'Chemistry', value: 20, color: '#FFBB28' },
    { name: 'English', value: 15, color: '#FF8042' },
    { name: 'Others', value: 5, color: '#8884D8' },
  ]);

  const StatCard = ({ title, value, icon, trend, trendValue, color }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography color="textSecondary" gutterBottom variant="overline">
              {title}
            </Typography>
            <Typography variant="h4" component="h2">
              {typeof value === 'number' && title.includes('Revenue') 
                ? `$${value.toLocaleString()}` 
                : value.toLocaleString()}
            </Typography>
            {trend && (
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
                  {trendValue}% from last month
                </Typography>
              </Box>
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
    switch (status.toLowerCase()) {
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
            value={stats.totalUsers}
            icon={<People />}
            trend="up"
            trendValue={12}
            color="primary.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Tutors"
            value={stats.totalTutors}
            icon={<School />}
            trend="up"
            trendValue={8}
            color="success.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Bookings"
            value={stats.totalBookings}
            icon={<EventNote />}
            trend="up"
            trendValue={15}
            color="warning.main"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Monthly Revenue"
            value={stats.totalRevenue}
            icon={<AttachMoney />}
            trend="up"
            trendValue={23}
            color="error.main"
          />
        </Grid>
      </Grid>

      {/* Charts */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Bookings & Revenue Trend
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis yAxisId="left" />
                  <YAxis yAxisId="right" orientation="right" />
                  <Tooltip />
                  <Bar yAxisId="left" dataKey="bookings" fill="#8884d8" />
                  <Line
                    yAxisId="right"
                    type="monotone"
                    dataKey="revenue"
                    stroke="#82ca9d"
                    strokeWidth={2}
                  />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Popular Subjects
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={subjectData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {subjectData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
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
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {recentBookings.map((booking) => (
                      <TableRow key={booking.id}>
                        <TableCell>{booking.student}</TableCell>
                        <TableCell>{booking.tutor}</TableCell>
                        <TableCell>{booking.subject}</TableCell>
                        <TableCell>{booking.date}</TableCell>
                        <TableCell>
                          <Chip
                            label={booking.status}
                            color={getStatusColor(booking.status)}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>${booking.amount}</TableCell>
                        <TableCell>
                          <IconButton size="small">
                            <MoreVert />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card sx={{ mb: 2 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Pending Actions
              </Typography>
              <Box sx={{ mb: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Tutor Verifications</Typography>
                  <Typography variant="body2" color="warning.main">
                    {stats.pendingVerifications}
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={(stats.pendingVerifications / 20) * 100}
                  color="warning"
                />
              </Box>
              <Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Active Disputes</Typography>
                  <Typography variant="body2" color="error.main">
                    {stats.activeDisputes}
                  </Typography>
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={(stats.activeDisputes / 10) * 100}
                  color="error"
                />
              </Box>
            </CardContent>
          </Card>

          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                System Health
              </Typography>
              <Box sx={{ mb: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Server Status</Typography>
                  <Typography variant="body2" color="success.main">
                    Online
                  </Typography>
                </Box>
                <LinearProgress variant="determinate" value={98} color="success" />
              </Box>
              <Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2">Database</Typography>
                  <Typography variant="body2" color="success.main">
                    Healthy
                  </Typography>
                </Box>
                <LinearProgress variant="determinate" value={95} color="success" />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;