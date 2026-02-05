import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  CircularProgress,
  Alert,
  Tabs,
  Tab,
  Badge,
} from '@mui/material';
import {
  Visibility as ViewIcon,
  Reply as ReplyIcon,
  CheckCircle as ResolveIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import axios from '../config/axios';

const SupportTickets = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [replyMessage, setReplyMessage] = useState('');
  const [newStatus, setNewStatus] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');

  useEffect(() => {
    fetchTickets();
  }, []);

  const fetchTickets = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/support/admin/tickets');
      if (response.data.success) {
        setTickets(response.data.data);
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch tickets');
    } finally {
      setLoading(false);
    }
  };

  const handleViewTicket = async (ticketId) => {
    try {
      const response = await axios.get(`/support/tickets/${ticketId}`);
      if (response.data.success) {
        setSelectedTicket(response.data.data);
        setNewStatus(response.data.data.status);
        setDialogOpen(true);
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to fetch ticket details');
    }
  };

  const handleReply = async () => {
    if (!replyMessage.trim()) return;

    try {
      const response = await axios.post(
        `/support/tickets/${selectedTicket._id}/messages`,
        { message: replyMessage }
      );
      if (response.data.success) {
        setSelectedTicket(response.data.data);
        setReplyMessage('');
        fetchTickets(); // Refresh list
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to send reply');
    }
  };

  const handleUpdateStatus = async () => {
    try {
      const response = await axios.put(
        `/support/admin/tickets/${selectedTicket._id}`,
        { status: newStatus }
      );
      if (response.data.success) {
        setSelectedTicket(response.data.data);
        fetchTickets(); // Refresh list
        setError('');
      }
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to update status');
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'open':
        return 'primary';
      case 'in-progress':
        return 'warning';
      case 'resolved':
        return 'success';
      case 'closed':
        return 'default';
      default:
        return 'default';
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'low':
        return 'success';
      case 'medium':
        return 'warning';
      case 'high':
        return 'error';
      case 'urgent':
        return 'error';
      default:
        return 'default';
    }
  };

  const filteredTickets = tickets.filter((ticket) => {
    if (statusFilter !== 'all' && ticket.status !== statusFilter) return false;
    if (priorityFilter !== 'all' && ticket.priority !== priorityFilter) return false;
    return true;
  });

  const getTicketCounts = () => {
    return {
      all: tickets.length,
      open: tickets.filter((t) => t.status === 'open').length,
      'in-progress': tickets.filter((t) => t.status === 'in-progress').length,
      resolved: tickets.filter((t) => t.status === 'resolved').length,
      closed: tickets.filter((t) => t.status === 'closed').length,
    };
  };

  const counts = getTicketCounts();

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Support Tickets
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
          {error}
        </Alert>
      )}

      {/* Status Tabs */}
      <Paper sx={{ mb: 2 }}>
        <Tabs
          value={statusFilter}
          onChange={(e, newValue) => setStatusFilter(newValue)}
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab
            label={
              <Badge badgeContent={counts.all} color="primary">
                All
              </Badge>
            }
            value="all"
          />
          <Tab
            label={
              <Badge badgeContent={counts.open} color="primary">
                Open
              </Badge>
            }
            value="open"
          />
          <Tab
            label={
              <Badge badgeContent={counts['in-progress']} color="warning">
                In Progress
              </Badge>
            }
            value="in-progress"
          />
          <Tab
            label={
              <Badge badgeContent={counts.resolved} color="success">
                Resolved
              </Badge>
            }
            value="resolved"
          />
          <Tab
            label={
              <Badge badgeContent={counts.closed} color="default">
                Closed
              </Badge>
            }
            value="closed"
          />
        </Tabs>
      </Paper>

      {/* Priority Filter */}
      <Box sx={{ mb: 2 }}>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Priority Filter</InputLabel>
          <Select
            value={priorityFilter}
            label="Priority Filter"
            onChange={(e) => setPriorityFilter(e.target.value)}
          >
            <MenuItem value="all">All Priorities</MenuItem>
            <MenuItem value="low">Low</MenuItem>
            <MenuItem value="medium">Medium</MenuItem>
            <MenuItem value="high">High</MenuItem>
            <MenuItem value="urgent">Urgent</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {/* Tickets Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Ticket ID</TableCell>
              <TableCell>Subject</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Priority</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Messages</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredTickets.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} align="center">
                  No tickets found
                </TableCell>
              </TableRow>
            ) : (
              filteredTickets.map((ticket) => (
                <TableRow key={ticket._id}>
                  <TableCell>#{ticket._id.slice(-6)}</TableCell>
                  <TableCell>{ticket.subject}</TableCell>
                  <TableCell>
                    <Chip label={ticket.category} size="small" />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={ticket.priority.toUpperCase()}
                      color={getPriorityColor(ticket.priority)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={ticket.status.toUpperCase()}
                      color={getStatusColor(ticket.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>{ticket.messages.length}</TableCell>
                  <TableCell>
                    {new Date(ticket.createdAt).toLocaleDateString()}
                  </TableCell>
                  <TableCell>
                    <IconButton
                      size="small"
                      color="primary"
                      onClick={() => handleViewTicket(ticket._id)}
                    >
                      <ViewIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Ticket Detail Dialog */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        {selectedTicket && (
          <>
            <DialogTitle>
              <Box display="flex" justifyContent="space-between" alignItems="center">
                <Typography variant="h6">
                  Ticket #{selectedTicket._id.slice(-6)}
                </Typography>
                <IconButton onClick={() => setDialogOpen(false)}>
                  <CloseIcon />
                </IconButton>
              </Box>
            </DialogTitle>
            <DialogContent dividers>
              {/* Ticket Info */}
              <Box sx={{ mb: 3 }}>
                <Typography variant="h6" gutterBottom>
                  {selectedTicket.subject}
                </Typography>
                <Box display="flex" gap={1} mb={2}>
                  <Chip
                    label={selectedTicket.category}
                    size="small"
                  />
                  <Chip
                    label={selectedTicket.priority.toUpperCase()}
                    color={getPriorityColor(selectedTicket.priority)}
                    size="small"
                  />
                  <Chip
                    label={selectedTicket.status.toUpperCase()}
                    color={getStatusColor(selectedTicket.status)}
                    size="small"
                  />
                </Box>
                <Typography variant="body2" color="text.secondary" paragraph>
                  {selectedTicket.description}
                </Typography>
              </Box>

              {/* Messages */}
              <Typography variant="h6" gutterBottom>
                Conversation
              </Typography>
              <Box sx={{ maxHeight: 400, overflowY: 'auto', mb: 2 }}>
                {selectedTicket.messages.map((msg, index) => (
                  <Paper
                    key={index}
                    sx={{
                      p: 2,
                      mb: 1,
                      bgcolor: msg.senderRole === 'admin' ? 'primary.light' : 'grey.100',
                    }}
                  >
                    <Typography variant="caption" color="text.secondary">
                      {msg.senderRole === 'admin' ? 'Admin' : 'User'} •{' '}
                      {new Date(msg.timestamp).toLocaleString()}
                    </Typography>
                    <Typography variant="body2" sx={{ mt: 1 }}>
                      {msg.message}
                    </Typography>
                  </Paper>
                ))}
              </Box>

              {/* Reply Box */}
              {selectedTicket.status !== 'closed' && (
                <Box sx={{ mb: 2 }}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Reply to user"
                    value={replyMessage}
                    onChange={(e) => setReplyMessage(e.target.value)}
                    placeholder="Type your reply here..."
                  />
                  <Button
                    variant="contained"
                    startIcon={<ReplyIcon />}
                    onClick={handleReply}
                    sx={{ mt: 1 }}
                    disabled={!replyMessage.trim()}
                  >
                    Send Reply
                  </Button>
                </Box>
              )}

              {/* Status Update */}
              <Box>
                <FormControl fullWidth sx={{ mb: 1 }}>
                  <InputLabel>Update Status</InputLabel>
                  <Select
                    value={newStatus}
                    label="Update Status"
                    onChange={(e) => setNewStatus(e.target.value)}
                  >
                    <MenuItem value="open">Open</MenuItem>
                    <MenuItem value="in-progress">In Progress</MenuItem>
                    <MenuItem value="resolved">Resolved</MenuItem>
                    <MenuItem value="closed">Closed</MenuItem>
                  </Select>
                </FormControl>
                <Button
                  variant="contained"
                  color="success"
                  startIcon={<ResolveIcon />}
                  onClick={handleUpdateStatus}
                  disabled={newStatus === selectedTicket.status}
                >
                  Update Status
                </Button>
              </Box>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setDialogOpen(false)}>Close</Button>
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
};

export default SupportTickets;
