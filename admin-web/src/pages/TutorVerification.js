import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
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
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Paper,
  Rating,
  Tab,
  Tabs,
} from '@mui/material';
import {
  CheckCircle,
  Cancel,
  Visibility,
  School,
  Work,
  Star,
  AttachFile,
  Email,
  Phone,
  LocationOn,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import toast from 'react-hot-toast';

const TutorVerification = () => {
  const [tutors, setTutors] = useState([]);
  const [selectedTutor, setSelectedTutor] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(false);

  // Mock data - replace with API calls
  useEffect(() => {
    setTutors([
      {
        id: 1,
        firstName: 'Sarah',
        lastName: 'Johnson',
        email: 'sarah.johnson@email.com',
        phone: '+1234567891',
        status: 'pending',
        appliedDate: '2026-01-28',
        subjects: ['Mathematics', 'Physics'],
        experience: '5 years',
        education: 'PhD in Mathematics, MIT',
        hourlyRate: 45,
        bio: 'Experienced mathematics tutor with a passion for helping students understand complex concepts.',
        documents: [
          { name: 'Degree Certificate', type: 'pdf', verified: false },
          { name: 'Teaching Certificate', type: 'pdf', verified: false },
          { name: 'ID Proof', type: 'pdf', verified: false },
        ],
        profilePicture: null,
        location: 'Boston, MA',
        languages: ['English', 'Spanish'],
        availability: 'Weekdays 9 AM - 5 PM',
        teachingMode: 'Both Online & In-Person',
      },
      {
        id: 2,
        firstName: 'Michael',
        lastName: 'Chen',
        email: 'michael.chen@email.com',
        phone: '+1234567892',
        status: 'pending',
        appliedDate: '2026-01-25',
        subjects: ['Physics', 'Chemistry'],
        experience: '8 years',
        education: 'PhD in Physics, Stanford',
        hourlyRate: 55,
        bio: 'Physics professor with extensive research background and teaching experience.',
        documents: [
          { name: 'Degree Certificate', type: 'pdf', verified: true },
          { name: 'Teaching Certificate', type: 'pdf', verified: true },
          { name: 'ID Proof', type: 'pdf', verified: false },
        ],
        profilePicture: null,
        location: 'San Francisco, CA',
        languages: ['English', 'Mandarin'],
        availability: 'Flexible',
        teachingMode: 'Online Only',
      },
      {
        id: 3,
        firstName: 'Emily',
        lastName: 'Davis',
        email: 'emily.davis@email.com',
        phone: '+1234567893',
        status: 'approved',
        appliedDate: '2026-01-20',
        approvedDate: '2026-01-22',
        subjects: ['English', 'Literature'],
        experience: '3 years',
        education: 'MA in English Literature, Harvard',
        hourlyRate: 35,
        bio: 'English literature enthusiast helping students improve their writing and comprehension skills.',
        documents: [
          { name: 'Degree Certificate', type: 'pdf', verified: true },
          { name: 'Teaching Certificate', type: 'pdf', verified: true },
          { name: 'ID Proof', type: 'pdf', verified: true },
        ],
        profilePicture: null,
        location: 'Cambridge, MA',
        languages: ['English'],
        availability: 'Evenings and Weekends',
        teachingMode: 'In-Person Only',
        rating: 4.8,
        totalSessions: 25,
      },
      {
        id: 4,
        firstName: 'Ahmed',
        lastName: 'Hassan',
        email: 'ahmed.hassan@email.com',
        phone: '+1234567894',
        status: 'rejected',
        appliedDate: '2026-01-15',
        rejectedDate: '2026-01-18',
        rejectionReason: 'Insufficient documentation provided',
        subjects: ['Chemistry', 'Biology'],
        experience: '2 years',
        education: 'BS in Chemistry, Local University',
        hourlyRate: 30,
        bio: 'Chemistry student looking to help others with basic chemistry concepts.',
        documents: [
          { name: 'Degree Certificate', type: 'pdf', verified: false },
          { name: 'ID Proof', type: 'pdf', verified: false },
        ],
        profilePicture: null,
        location: 'New York, NY',
        languages: ['English', 'Arabic'],
        availability: 'Weekends Only',
        teachingMode: 'Both Online & In-Person',
      },
    ]);
  }, []);

  const handleViewDetails = (tutor) => {
    setSelectedTutor(tutor);
    setDialogOpen(true);
    setTabValue(0);
  };

  const handleApprove = async (tutorId) => {
    try {
      // API call would go here
      setTutors(tutors.map(tutor => 
        tutor.id === tutorId 
          ? { ...tutor, status: 'approved', approvedDate: new Date().toISOString().split('T')[0] }
          : tutor
      ));
      toast.success('Tutor approved successfully');
      setDialogOpen(false);
    } catch (error) {
      toast.error('Failed to approve tutor');
    }
  };

  const handleReject = async (tutorId, reason) => {
    try {
      // API call would go here
      setTutors(tutors.map(tutor => 
        tutor.id === tutorId 
          ? { 
              ...tutor, 
              status: 'rejected', 
              rejectedDate: new Date().toISOString().split('T')[0],
              rejectionReason: reason 
            }
          : tutor
      ));
      toast.success('Tutor application rejected');
      setDialogOpen(false);
    } catch (error) {
      toast.error('Failed to reject tutor');
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
      renderCell: (params) => `$${params.value}`,
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
      type: 'date',
      valueGetter: (params) => new Date(params.value),
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
                <Tab label="Documents" />
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
                      {selectedTutor.rating && (
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
                          label="Location"
                          value={selectedTutor.location}
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
                          value={`$${selectedTutor.hourlyRate}`}
                          InputProps={{ readOnly: true }}
                          InputLabelProps={{ shrink: true }}
                        />
                      </Grid>
                      <Grid item xs={12} md={6}>
                        <TextField
                          fullWidth
                          label="Teaching Mode"
                          value={selectedTutor.teachingMode}
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
                      <Grid item xs={12}>
                        <Typography variant="subtitle2" gutterBottom>
                          Languages
                        </Typography>
                        <Box>
                          {selectedTutor.languages.map((language, index) => (
                            <Chip
                              key={index}
                              label={language}
                              variant="outlined"
                              sx={{ mr: 1, mb: 1 }}
                            />
                          ))}
                        </Box>
                      </Grid>
                    </Grid>
                  </Grid>
                </Grid>
              </TabPanel>

              <TabPanel value={tabValue} index={1}>
                <Typography variant="h6" gutterBottom>
                  Submitted Documents
                </Typography>
                <List>
                  {selectedTutor.documents.map((doc, index) => (
                    <ListItem key={index} divider>
                      <ListItemIcon>
                        <AttachFile />
                      </ListItemIcon>
                      <ListItemText
                        primary={doc.name}
                        secondary={`Type: ${doc.type.toUpperCase()}`}
                      />
                      <Chip
                        label={doc.verified ? 'Verified' : 'Pending'}
                        color={doc.verified ? 'success' : 'warning'}
                        size="small"
                      />
                      <Button size="small" sx={{ ml: 1 }}>
                        View
                      </Button>
                    </ListItem>
                  ))}
                </List>
              </TabPanel>

              <TabPanel value={tabValue} index={2}>
                {selectedTutor.status === 'approved' ? (
                  <Grid container spacing={3}>
                    <Grid item xs={12} md={4}>
                      <Paper sx={{ p: 2, textAlign: 'center' }}>
                        <Typography variant="h4" color="primary">
                          {selectedTutor.rating || 'N/A'}
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
                          ${((selectedTutor.totalSessions || 0) * selectedTutor.hourlyRate).toLocaleString()}
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
                onClick={() => {
                  const reason = prompt('Please provide a reason for rejection:');
                  if (reason) {
                    handleReject(selectedTutor.id, reason);
                  }
                }}
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