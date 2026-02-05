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
  CircularProgress,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { Visibility, CheckCircle, Cancel, Message, Send } from '@mui/icons-material';
import axios from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

const DisputeManagement = () => {
  const [disputes, setDisputes] = useState([]);
  const [selectedDispute, setSelectedDispute] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [resolution, setResolution] = useState('');
  const [newMessage, setNewMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filter, setFilter] = useState({ status: 'all', priority: 'all' });

  useEffect(() => {
    fetchDisputes();
  }, [filter]);

  const fetchDisputes = async () => {
    try {
      setLoading(true);
      const token = localStorage.getItem('adminToken');
      const response = await axios.get(`${API_BASE_URL}/admin/disputes`, {
        headers: { 'Authorization': `Bearer ${token}` },
        params: filter
      });

      if (response.data.success) {
        setDisputes(response.data.data.disputes.map(dispute => ({
          id: dispute._id,
          bookingId: dispute.bookingId?._id || 'N/A',
          student: dispute.studentId ? `${dispute.studentId.firstName} ${dispute.studentId.lastName}` : 'Unknown',
          tutor: dispute.tutorId ? `${dispute.tutorId.firstName} ${dispute.tutorId.lastName}` : 'Unknown',
          subject: dispute.bookingId?.subject?.name || 'N/A',
          issue: dispute.issue,
          status: dispute.status,
          priority: dispute.priority,
          createdDate: new Date(dispute.createdAt).toLocaleDateString(),
          amount: dispute.amount,
          description: dispute.description,
          messages: dispute.messages || [],
          resolution: dispute.resolution,
          raisedBy: dispute.raisedBy,
          studentEmail: dispute.studentId?.email,
          tutorEmail: dispute.tutorId?.email,
        })));
      }
    } catch (err) {
      console.error('Failed to fetch disputes:', err);
      setError(err.response?.data?.message || 'Failed to load disputes');
      toast.error('Failed to load disputes');
    } finally {
      setLoading(false);
    }
  };

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
      const token = localStorage.getItem('adminToken');
      await axios.post(
        `${API_BASE_URL}/admin/disputes/${disputeId}/resolve`,
        { resolution: resolutionText },
        { headers: { 'Authorization': `Bearer ${token}` } }
      );
      
      toast.success('Dispute resolved successfully');
      setDialogOpen(false);
      setResolution('');
      fetchDisputes();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to resolve dispute');
    }
  };

  const handleSendMessage = async (disputeId) => {
    if (!newMessage.trim()) return;

    try {
      const token = localStorage.getItem('adminToken');
      await axios.post(
        `${API_BASE_URL}/admin/disputes/${disputeId}/messages`,
        { message: newMessage },
        { headers: { 'Authorization': `Bearer ${token}` } }
      );
      
      toast.success('Message sent successfully');
      setNewMessage('');
      
      // Refresh dispute details
      const response = await axios.get(
        `${API_BASE_URL}/admin/disputes/${disputeId}`,
        { headers: { 'Authorization': `Bearer ${token}` } }
      );
      
      if (response.data.success) {
        const dispute = response.data.data.dispute;
        setSelectedDispute({
          ...selectedDispute,
          messages: dispute.messages,
          status: dispute.status,
        });
      }
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to send message');
    }
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 100 },
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
      renderCell: (params) => `ETB ${params.value}`,
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
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" fontWeight="bold">
          Dispute Management
        </Typography>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={filter.status}
              label="Status"
              onChange={(e) => setFilter({ ...filter, status: e.target.value })}
            >
              <MenuItem value="all">All Status</MenuItem>
              <MenuItem value="open">Open</MenuItem>
              <MenuItem value="in_progress">In Progress</MenuItem>
              <MenuItem value="resolved">Resolved</MenuItem>
              <MenuItem value="closed">Closed</MenuItem>
            </Select>
          </FormControl>
          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Priority</InputLabel>
            <Select
              value={filter.priority}
              label="Priority"
              onChange={(e) => setFilter({ ...filter, priority: e.target.value })}
            >
              <MenuItem value="all">All Priority</MenuItem>
              <MenuItem value="high">High</MenuItem>
              <MenuItem value="medium">Medium</MenuItem>
              <MenuItem value="low">Low</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Box>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={disputes}
            columns={columns}
            pageSize={10}
            rowsPerPageOptions={[10, 25, 50]}
            disableSelectionOnClick
            loading={loading}
            sx={{
              border: 'none',
              '& .MuiDataGrid-cell': {
                borderBottom: '1px solid #f0f0f0',
              },
            }}
          />
        </Box>
      </Card>

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          Dispute Details - {selectedDispute?.bookingId}
          <Chip
            label={selectedDispute?.status?.replace('_', ' ')}
            color={getStatusColor(selectedDispute?.status)}
            size="small"
            sx={{ ml: 2 }}
          />
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
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Raised By"
                  value={selectedDispute.raisedBy}
                  InputProps={{ readOnly: true }}
                  margin="normal"
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Amount"
                  value={`ETB ${selectedDispute.amount}`}
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
                  <List sx={{ maxHeight: 300, overflow: 'auto', bgcolor: 'background.paper', borderRadius: 1 }}>
                    {selectedDispute.messages.map((msg, index) => (
                      <ListItem key={index} alignItems="flex-start">
                        <ListItemAvatar>
                          <Avatar>{msg.sender?.firstName?.charAt(0) || 'U'}</Avatar>
                        </ListItemAvatar>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                              <Typography variant="subtitle2">
                                {msg.sender ? `${msg.sender.firstName} ${msg.sender.lastName}` : 'Unknown'}
                                <Chip label={msg.senderRole} size="small" sx={{ ml: 1 }} />
                              </Typography>
                              <Typography variant="caption" color="text.secondary">
                                {new Date(msg.timestamp).toLocaleString()}
                              </Typography>
                            </Box>
                          }
                          secondary={
                            <Typography variant="body2" sx={{ mt: 0.5 }}>
                              {msg.message}
                            </Typography>
                          }
                        />
                      </ListItem>
                    ))}
                  </List>
                </Grid>
              )}

              {selectedDispute.status !== 'resolved' && selectedDispute.status !== 'closed' && (
                <Grid item xs={12}>
                  <Divider sx={{ my: 2 }} />
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <TextField
                      fullWidth
                      label="Add Message"
                      value={newMessage}
                      onChange={(e) => setNewMessage(e.target.value)}
                      placeholder="Type your message..."
                      size="small"
                    />
                    <Button
                      variant="outlined"
                      startIcon={<Send />}
                      onClick={() => handleSendMessage(selectedDispute.id)}
                      disabled={!newMessage.trim()}
                    >
                      Send
                    </Button>
                  </Box>
                </Grid>
              )}

              {selectedDispute.status !== 'resolved' && selectedDispute.status !== 'closed' && (
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

              {selectedDispute.resolution && (
                <Grid item xs={12}>
                  <Divider sx={{ my: 2 }} />
                  <TextField
                    fullWidth
                    label="Resolution"
                    value={selectedDispute.resolution}
                    multiline
                    rows={3}
                    InputProps={{ readOnly: true }}
                  />
                </Grid>
              )}
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
          {selectedDispute?.status !== 'resolved' && selectedDispute?.status !== 'closed' && (
            <Button
              variant="contained"
              startIcon={<CheckCircle />}
              onClick={() => handleResolve(selectedDispute.id, resolution)}
              disabled={!resolution.trim()}
            >
              Resolve
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DisputeManagement;
