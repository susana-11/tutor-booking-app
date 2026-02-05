import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  Typography,
  Button,
  Chip,
  Avatar,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  TextField,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Paper,
  Rating,
  Tab,
  Tabs,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  CheckCircle,
  Cancel,
  Visibility,
  AttachFile,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import axios from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

const TutorVerification = () => {
  const [tutors, setTutors] = useState([]);
  const [selectedTutor, setSelectedTutor] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchTutors();
  }, []);

  const fetchTutors = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE_URL}/admin/tutors`);
      
      if (response.data) {
        const tutorsData = Array.isArray(response.data) ? response.data : [];
        setTutors(tutorsData.map(tutor => ({
          id: tutor._id,
          firstName: tutor.userId?.firstName || 'N/A',
          lastName: tutor.userId?.lastName || 'N/A',
          email: tutor.userId?.email || 'N/A',
          phone: tutor.userId?.phone || 'N/A',
          status: tutor.status,
          appliedDate: new Date(tutor.createdAt).toLocaleDateString(),
          subjects: tutor.subjects?.map(s => s.name || s) || [],
          experience: tutor.experience || 'Not specified',
          education: tutor.education || 'Not specified',
          hourlyRate: tutor.pricing?.hourlyRate || 0,
          bio: tutor.bio || 'No bio provided',
          location: tutor.location || 'Not specified',
          languages: tutor.languages || [],
          availability: tutor.availability || 'Not specified',
          teachingMode: tutor.teachingMode || 'Not specified',
          rating: tutor.stats?.averageRating || 0,
          totalSessions: tutor.stats?.totalSessions || 0,
          rejectionReason: tutor.rejectionReason,
          profileData: tutor,
        })));
      }
    } catch (err) {
      console.error('Failed to fetch tutors:', err);
      setError(err.response?.data?.message || 'Failed to load tutors');
    } finally {
      setLoading(false);
    }
  };

  const handleViewDetails = (tutor) => {
    setSelectedTutor(tutor);
    setDialogOpen(true);
    setTabValue(0);
  };

  const handleApprove = async (tutorId) => {
    try {
      await axios.post(`${API_BASE_URL}/admin/tutors/${tutorId}/approve`);
      toast.success('Tutor approved successfully');
      setDialogOpen(false);
      fetchTutors();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to approve tutor');
    }
  };

  const handleReject = async (tutorId) => {
    const reason = prompt('Please provide a reason for rejection:');
    if (!reason) return;

    try {
      await axios.post(`${API_BASE_URL}/admin/tutors/${tutorId}/reject`, { reason });
      toast.success('Tutor application rejected');
      setDialogOpen(false);
      fetchTutors();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to reject tutor');
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'pending': return 'warning';
      case 'approved': return 'success';
      case 'rejected': return 'error';
      default: return 'default';
    }
  };

  const columns = [
    {
      field: 'avatar',
      headerName: '',
      width: 60,
      renderCell: (params) => (
        <Avatar sx={{ width: 32, height: 32 }}>
          {params.row.firstName.charAt(0)}
        </Avatar>
      ),
      sortable: false,
      filterable: false,
    },
    {
      field: 'name',
      headerName: 'Name',
      width: 200,
      renderCell: (params) => (
        <Box>
          <Typography variant="body2" fontWeight="medium">
            {`${params.row.firstName} ${params.row.lastName}`}
          </Typography>
          <Typography variant="caption" color="text.secondary">
            {params.row.email}
          </Typography>
        </Box>
      ),
    },
    {
      field: 'subjects',
      headerName: 'Subjects',
      width: 200,
      renderCell: (params) => (
        <Box>
          {params.value.slice(0, 2).map((subject, index) => (
            <Chip
              key={index}
              label={subject}
              size="small"
              sx={{ mr: 0.5, mb: 0.5 }}
            />
          ))}
          {params.value.length > 2 && (
            <Typography variant="caption" color="text.secondary">
              +{params.value.length - 2} more
            </Typography>
          )}
        </Box>
      ),
    },
    {
      field: 'experience',
      headerName: 'Experience',
      width: 120,
    },
    {
      field: 'hourlyRate',
      headerName: 'Rate/Hour',
      width: 100,
      renderCell: (params) => `ETB ${params.value}`,
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getStatusColor(params.value)}
          size="small"
          sx={{ textTransform: 'capitalize' }}
        />
      ),
    },
    {
      field: 'appliedDate',
      headerName: 'Applied Date',
      width: 120,
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 120,
      renderCell: (params) => (
        <Button
          size="small"
          variant="outlined"
          startIcon={<Visibility />}
          onClick={() => handleViewDetails(params.row)}
        >
          View
        </Button>
      ),
      sortable: false,
      filterable: false,
    },
  ];

  const TabPanel = ({ children, value, index }) => (
    <div hidden={value !== index}>
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );

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
      <Typography variant="h4" fontWeight="bold" sx={{ mb: 3 }}>
        Tutor Verification
      </Typography>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={tutors}
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

      {/* Tutor Details Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="lg" fullWidth>
        <DialogTitle>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Typography variant="h6">
              {selectedTutor ? `${selectedTutor.firstName} ${selectedTutor.lastName}` : 'Tutor Details'}
            </Typography>
            {selectedTutor && (
              <Chip
                label={selectedTutor.status}
                color={getStatusColor(selectedTutor.status)}
                sx={{ textTransform: 'capitalize' }}
              />
            )}
          </Box>
        </DialogTitle>
        
        <DialogContent>
          {selectedTutor && (
            <Box>
              <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
                <Tab label="Profile Information" />
                <Tab label="Performance" />
              </Tabs>

              <TabPanel value={tabValue} index={0}>
                <Grid container spacing={3}>
                  <Grid item xs={12} md={4}>
                    <Paper sx={{ p: 2, textAlign: 'center' }}>
                      <Avatar sx={{ width: 80, height: 80, mx: 'auto', mb: 2 }}>
                        {selectedTutor.firstName.charAt(0)}
                      </Avatar>
                      <Typography variant="h6">
                        {`${selectedTutor.firstName} ${selectedTutor.lastName}`}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {selectedTutor.education}
                      </Typography>
                      {selectedTutor.rating > 0 && (
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', mt: 1 }}>
                          <Rating value={selectedTutor.rating} readOnly size="small" />
                          <Typography variant="body2" sx={{ ml: 1 }}>
                            ({selectedTutor.totalSessions} sessions)
                          </Typography>
                        </Box>
                      )}
                    </Paper>
                  </Grid>
                  
                  <Grid item xs={12} md={8}>
                    <Grid container spacing={2}>
                      <Grid item xs={12} md={6}>
                        <TextField
                          fullWidth
                          label="Email"
                          value={selectedTutor.email}
                          InputProps={{ readOnly: true }}
                          InputLabelProps={{ shrink: true }}
                        />
                      </Grid>
                      <Grid item xs={12} md={6}>
                        <TextField
                          fullWidth
                          label="Phone"
                          value={selectedTutor.phone}
                          InputProps={{ readOnly: true }}
                          InputLabelProps={{ shrink: true }}
                        />
                      </Grid>
                      <Grid item xs={12} md={6}>
                        <TextField
                          fullWidth
                          label="Experience"
                          value={selectedTutor.experience}
                          InputProps={{ readOnly: true }}
                          InputLabelProps={{ shrink: true }}
                        />
                      </Grid>
                      <Grid item xs={12} md={6}>
                        <TextField
                          fullWidth
                          label="Hourly Rate"
                          value={`ETB ${selectedTutor.hourlyRate}`}
                          InputProps={{ readOnly: true }}
                          InputLabelProps={{ shrink: true }}
                        />
                      </Grid>
                      <Grid item xs={12}>
                        <TextField
                          fullWidth
                          label="Bio"
                          value={selectedTutor.bio}
                          multiline
                          rows={3}
                          InputProps={{ readOnly: true }}
                          InputLabelProps={{ shrink: true }}
                        />
                      </Grid>
                      <Grid item xs={12}>
                        <Typography variant="subtitle2" gutterBottom>
                          Subjects
                        </Typography>
                        <Box>
                          {selectedTutor.subjects.map((subject, index) => (
                            <Chip
                              key={index}
                              label={subject}
                              sx={{ mr: 1, mb: 1 }}
                            />
                          ))}
                        </Box>
                      </Grid>
                      {selectedTutor.rejectionReason && (
                        <Grid item xs={12}>
                          <Alert severity="error">
                            <Typography variant="subtitle2">Rejection Reason:</Typography>
                            <Typography variant="body2">{selectedTutor.rejectionReason}</Typography>
                          </Alert>
                        </Grid>
                      )}
                    </Grid>
                  </Grid>
                </Grid>
              </TabPanel>

              <TabPanel value={tabValue} index={1}>
                {selectedTutor.status === 'approved' ? (
                  <Grid container spacing={3}>
                    <Grid item xs={12} md={4}>
                      <Paper sx={{ p: 2, textAlign: 'center' }}>
                        <Typography variant="h4" color="primary">
                          {selectedTutor.rating > 0 ? selectedTutor.rating.toFixed(1) : 'N/A'}
                        </Typography>
                        <Typography variant="body2">Average Rating</Typography>
                      </Paper>
                    </Grid>
                    <Grid item xs={12} md={4}>
                      <Paper sx={{ p: 2, textAlign: 'center' }}>
                        <Typography variant="h4" color="primary">
                          {selectedTutor.totalSessions || 0}
                        </Typography>
                        <Typography variant="body2">Total Sessions</Typography>
                      </Paper>
                    </Grid>
                    <Grid item xs={12} md={4}>
                      <Paper sx={{ p: 2, textAlign: 'center' }}>
                        <Typography variant="h4" color="primary">
                          ETB {((selectedTutor.totalSessions || 0) * selectedTutor.hourlyRate).toLocaleString()}
                        </Typography>
                        <Typography variant="body2">Total Earnings</Typography>
                      </Paper>
                    </Grid>
                  </Grid>
                ) : (
                  <Typography variant="body1" color="text.secondary" align="center">
                    Performance data will be available after tutor approval and first sessions.
                  </Typography>
                )}
              </TabPanel>
            </Box>
          )}
        </DialogContent>
        
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
          {selectedTutor?.status === 'pending' && (
            <>
              <Button
                color="error"
                onClick={() => handleReject(selectedTutor.id)}
                startIcon={<Cancel />}
              >
                Reject
              </Button>
              <Button
                variant="contained"
                color="success"
                onClick={() => handleApprove(selectedTutor.id)}
                startIcon={<CheckCircle />}
              >
                Approve
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default TutorVerification;
