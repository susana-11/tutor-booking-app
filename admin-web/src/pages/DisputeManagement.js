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
  TextField,
  Grid,
  Avatar,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { Visibility, CheckCircle, Cancel, Message } from '@mui/icons-material';
import toast from 'react-hot-toast';

const DisputeManagement = () => {
  const [disputes, setDisputes] = useState([]);
  const [selectedDispute, setSelectedDispute] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [resolution, setResolution] = useState('');

  useEffect(() => {
    // Mock data
    setDisputes([
      {
        id: 1,
        bookingId: 'BK001',
        student: 'John Doe',
        tutor: 'Dr. Sarah Johnson',
        subject: 'Mathematics',
        issue: 'Tutor did not show up for the session',
        status: 'open',
        priority: 'high',
        createdDate: '2026-01-28',
        amount: 45,
        description: 'The tutor was supposed to join the session at 10 AM but never showed up. I waited for 30 minutes.',
        messages: [
          {
            sender: 'John Doe',
            message: 'The tutor did not show up for our scheduled session.',
            timestamp: '2026-01-28 10:30 AM',
          },
          {
            sender: 'Dr. Sarah Johnson',
            message: 'I apologize, I had a family emergency. Can we reschedule?',
            timestamp: '2026-01-28 2:00 PM',
          },
        ],
      },
      {
        id: 2,
        bookingId: 'BK002',
        student: 'Jane Smith',
        tutor: 'Prof. Michael Chen',
        subject: 'Physics',
        issue: 'Quality of teaching was poor',
        status: 'in_progress',
        priority: 'medium',
        createdDate: '2026-01-25',
        amount: 55,
        description: 'The tutor seemed unprepared and could not answer basic questions.',
        messages: [],
      },
    ]);
  }, []);

  const getStatusColor = (status) => {
    switch (status) {
      case 'open': return 'error';
      case 'in_progress': return 'warning';
      case 'resolved': return 'success';
      case 'closed': return 'default';
      default: return 'default';
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'high': return 'error';
      case 'medium': return 'warning';
      case 'low': return 'info';
      default: return 'default';
    }
  };

  const handleResolve = async (disputeId, resolutionText) => {
    try {
      setDisputes(disputes.map(dispute =>
        dispute.id === disputeId
          ? { ...dispute, status: 'resolved', resolution: resolutionText }
          : dispute
      ));
      toast.success('Dispute resolved successfully');
      setDialogOpen(false);
      setResolution('');
    } catch (error) {
      toast.error('Failed to resolve dispute');
    }
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'bookingId', headerName: 'Booking ID', width: 120 },
    { field: 'student', headerName: 'Student', width: 150 },
    { field: 'tutor', headerName: 'Tutor', width: 150 },
    { field: 'subject', headerName: 'Subject', width: 120 },
    { field: 'issue', headerName: 'Issue', width: 200 },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value.replace('_', ' ')}
          color={getStatusColor(params.value)}
          size="small"
        />
      ),
    },
    {
      field: 'priority',
      headerName: 'Priority',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getPriorityColor(params.value)}
          size="small"
          variant="outlined"
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
            setSelectedDispute(params.row);
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
        Dispute Management
      </Typography>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={disputes}
            columns={columns}
            pageSize={10}
            rowsPerPageOptions={[10, 25, 50]}
            disableSelectionOnClick
          />
        </Box>
      </Card>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          Dispute Details - {selectedDispute?.bookingId}
        </DialogTitle>
        <DialogContent>
          {selectedDispute && (
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Student"
                  value={selectedDispute.student}
                  InputProps={{ readOnly: true }}
                  margin="normal"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Tutor"
                  value={selectedDispute.tutor}
                  InputProps={{ readOnly: true }}
                  margin="normal"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Issue"
                  value={selectedDispute.issue}
                  InputProps={{ readOnly: true }}
                  margin="normal"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  value={selectedDispute.description}
                  multiline
                  rows={3}
                  InputProps={{ readOnly: true }}
                  margin="normal"
                />
              </Grid>
              
              {selectedDispute.messages && selectedDispute.messages.length > 0 && (
                <Grid item xs={12}>
                  <Typography variant="h6" sx={{ mt: 2, mb: 1 }}>
                    Messages
                  </Typography>
                  <List>
                    {selectedDispute.messages.map((msg, index) => (
                      <ListItem key={index}>
                        <ListItemAvatar>
                          <Avatar>{msg.sender.charAt(0)}</Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={msg.sender}
                          secondary={
                            <>
                              <Typography variant="body2">{msg.message}</Typography>
                              <Typography variant="caption" color="text.secondary">
                                {msg.timestamp}
                              </Typography>
                            </>
                          }
                        />
                      </ListItem>
                    ))}
                  </List>
                </Grid>
              )}

              {selectedDispute.status !== 'resolved' && (
                <Grid item xs={12}>
                  <Divider sx={{ my: 2 }} />
                  <TextField
                    fullWidth
                    label="Resolution"
                    value={resolution}
                    onChange={(e) => setResolution(e.target.value)}
                    multiline
                    rows={3}
                    placeholder="Enter your resolution for this dispute..."
                  />
                </Grid>
              )}
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
          {selectedDispute?.status !== 'resolved' && (
            <>
              <Button
                color="error"
                startIcon={<Cancel />}
                onClick={() => {
                  // Handle dispute rejection
                  toast.info('Dispute rejection functionality to be implemented');
                }}
              >
                Reject
              </Button>
              <Button
                variant="contained"
                startIcon={<CheckCircle />}
                onClick={() => handleResolve(selectedDispute.id, resolution)}
                disabled={!resolution.trim()}
              >
                Resolve
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DisputeManagement;