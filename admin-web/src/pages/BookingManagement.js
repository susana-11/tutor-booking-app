import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  Typography,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { Visibility, Cancel, CheckCircle } from '@mui/icons-material';
import toast from 'react-hot-toast';

const BookingManagement = () => {
  const [bookings, setBookings] = useState([]);
  const [selectedBooking, setSelectedBooking] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');

  useEffect(() => {
    // Mock data
    setBookings([
      {
        id: 1,
        student: 'John Doe',
        tutor: 'Dr. Sarah Johnson',
        subject: 'Mathematics',
        date: '2026-02-01',
        time: '10:00 AM - 11:00 AM',
        status: 'confirmed',
        amount: 45,
        mode: 'online',
        createdAt: '2026-01-30',
      },
      {
        id: 2,
        student: 'Jane Smith',
        tutor: 'Prof. Michael Chen',
        subject: 'Physics',
        date: '2026-02-02',
        time: '2:00 PM - 3:00 PM',
        status: 'pending',
        amount: 55,
        mode: 'in-person',
        createdAt: '2026-01-29',
      },
      // Add more mock data...
    ]);
  }, []);

  const getStatusColor = (status) => {
    switch (status) {
      case 'confirmed': return 'success';
      case 'pending': return 'warning';
      case 'completed': return 'info';
      case 'cancelled': return 'error';
      default: return 'default';
    }
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'student', headerName: 'Student', width: 150 },
    { field: 'tutor', headerName: 'Tutor', width: 150 },
    { field: 'subject', headerName: 'Subject', width: 120 },
    { field: 'date', headerName: 'Date', width: 120 },
    { field: 'time', headerName: 'Time', width: 150 },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getStatusColor(params.value)}
          size="small"
        />
      ),
    },
    {
      field: 'amount',
      headerName: 'Amount',
      width: 100,
      renderCell: (params) => `$${params.value}`,
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      renderCell: (params) => (
        <Button
          size="small"
          startIcon={<Visibility />}
          onClick={() => {
            setSelectedBooking(params.row);
            setDialogOpen(true);
          }}
        >
          View
        </Button>
      ),
    },
  ];

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" sx={{ mb: 3 }}>
        Booking Management
      </Typography>

      <Card sx={{ mb: 3, p: 2 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} md={3}>
            <FormControl fullWidth>
              <InputLabel>Filter by Status</InputLabel>
              <Select
                value={filterStatus}
                label="Filter by Status"
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="pending">Pending</MenuItem>
                <MenuItem value="confirmed">Confirmed</MenuItem>
                <MenuItem value="completed">Completed</MenuItem>
                <MenuItem value="cancelled">Cancelled</MenuItem>
              </Select>
            </FormControl>
          </Grid>
        </Grid>
      </Card>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={bookings}
            columns={columns}
            pageSize={10}
            rowsPerPageOptions={[10, 25, 50]}
            disableSelectionOnClick
          />
        </Box>
      </Card>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Booking Details</DialogTitle>
        <DialogContent>
          {selectedBooking && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Student"
                  value={selectedBooking.student}
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Tutor"
                  value={selectedBooking.tutor}
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Subject"
                  value={selectedBooking.subject}
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Amount"
                  value={`$${selectedBooking.amount}`}
                  InputProps={{ readOnly: true }}
                />
              </Grid>
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
          {selectedBooking?.status === 'pending' && (
            <>
              <Button color="error" startIcon={<Cancel />}>
                Cancel Booking
              </Button>
              <Button variant="contained" startIcon={<CheckCircle />}>
                Confirm Booking
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default BookingManagement;