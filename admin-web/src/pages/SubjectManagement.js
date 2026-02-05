import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  FormControl,
  InputLabel,
  Select,
  Switch,
  FormControlLabel,
  CircularProgress,
  Alert,
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  MoreVert,
  Visibility,
  VisibilityOff,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import axios from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://tutor-app-backend-wtru.onrender.com/api';

const SubjectManagement = () => {
  const [subjects, setSubjects] = useState([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [actionMenuAnchor, setActionMenuAnchor] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: '',
    gradeLevel: [],
    isActive: true,
  });

  const categories = [
    'Mathematics',
    'Sciences',
    'Languages',
    'Social Studies',
    'Arts',
    'Technology',
    'Business',
    'Test Preparation',
  ];

  const gradeLevels = [
    'Elementary',
    'Middle School',
    'High School',
    'College',
    'Professional',
  ];

  useEffect(() => {
    fetchSubjects();
  }, []);

  const fetchSubjects = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const token = localStorage.getItem('adminToken');
      const response = await axios.get(`${API_BASE_URL}/subjects/admin`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (response.data.success) {
        setSubjects(response.data.data.map(subject => ({
          id: subject._id,
          name: subject.name,
          description: subject.description || '',
          category: subject.category || 'General',
          gradeLevel: subject.gradeLevel || [],
          isActive: subject.isActive !== false,
          tutorCount: 0, // Would need separate API call
          studentCount: 0,
          sessionCount: 0,
          averageRating: 0,
          createdDate: new Date(subject.createdAt).toLocaleDateString(),
        })));
      }
    } catch (err) {
      console.error('Failed to fetch subjects:', err);
      const errorMessage = err.response?.data?.message || 'Failed to load subjects';
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (subject = null) => {
    if (subject) {
      setSelectedSubject(subject);
      setFormData({
        name: subject.name,
        description: subject.description,
        category: subject.category,
        gradeLevel: subject.gradeLevel,
        isActive: subject.isActive,
      });
    } else {
      setSelectedSubject(null);
      setFormData({
        name: '',
        description: '',
        category: '',
        gradeLevel: [],
        isActive: true,
      });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedSubject(null);
  };

  const handleSave = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const config = {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      };
      
      if (selectedSubject) {
        await axios.put(`${API_BASE_URL}/subjects/admin/${selectedSubject.id}`, formData, config);
        toast.success('Subject updated successfully');
      } else {
        await axios.post(`${API_BASE_URL}/subjects/admin`, formData, config);
        toast.success('Subject created successfully');
      }
      handleCloseDialog();
      fetchSubjects();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to save subject');
    }
  };

  const handleDelete = async (subjectId) => {
    if (window.confirm('Are you sure you want to delete this subject?')) {
      try {
        const token = localStorage.getItem('adminToken');
        await axios.delete(`${API_BASE_URL}/subjects/admin/${subjectId}`, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
        toast.success('Subject deleted successfully');
        fetchSubjects();
      } catch (error) {
        toast.error(error.response?.data?.message || 'Failed to delete subject');
      }
    }
    handleActionClose();
  };

  const handleToggleStatus = async (subjectId) => {
    try {
      const subject = subjects.find(s => s.id === subjectId);
      const token = localStorage.getItem('adminToken');
      await axios.put(`${API_BASE_URL}/subjects/admin/${subjectId}`, {
        ...subject,
        isActive: !subject.isActive
      }, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      toast.success('Subject status updated');
      fetchSubjects();
    } catch (error) {
      toast.error(error.response?.data?.message || 'Failed to update subject status');
    }
    handleActionClose();
  };

  const handleActionClick = (event, subject) => {
    setSelectedSubject(subject);
    setActionMenuAnchor(event.currentTarget);
  };

  const handleActionClose = () => {
    setActionMenuAnchor(null);
  };

  const columns = [
    {
      field: 'name',
      headerName: 'Subject',
      width: 200,
      renderCell: (params) => (
        <Typography variant="body2" fontWeight="medium">
          {params.value}
        </Typography>
      ),
    },
    {
      field: 'category',
      headerName: 'Category',
      width: 150,
      renderCell: (params) => (
        <Chip label={params.value} size="small" variant="outlined" />
      ),
    },
    {
      field: 'gradeLevel',
      headerName: 'Grade Level',
      width: 200,
      renderCell: (params) => (
        <Box>
          {params.value.slice(0, 2).map((level, index) => (
            <Chip key={index} label={level} size="small" sx={{ mr: 0.5 }} />
          ))}
          {params.value.length > 2 && ` +${params.value.length - 2}`}
        </Box>
      ),
    },
    {
      field: 'isActive',
      headerName: 'Status',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value ? 'Active' : 'Inactive'}
          color={params.value ? 'success' : 'default'}
          size="small"
        />
      ),
    },
    {
      field: 'createdDate',
      headerName: 'Created',
      width: 120,
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 80,
      renderCell: (params) => (
        <IconButton
          size="small"
          onClick={(e) => handleActionClick(e, params.row)}
        >
          <MoreVert />
        </IconButton>
      ),
      sortable: false,
      filterable: false,
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
          Subject Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
        >
          Add Subject
        </Button>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="overline">
                Total Subjects
              </Typography>
              <Typography variant="h4">
                {subjects.length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="overline">
                Active Subjects
              </Typography>
              <Typography variant="h4">
                {subjects.filter(s => s.isActive).length}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Card>
        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={subjects}
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

      {/* Action Menu */}
      <Menu
        anchorEl={actionMenuAnchor}
        open={Boolean(actionMenuAnchor)}
        onClose={handleActionClose}
      >
        <MenuItem onClick={() => {
          handleOpenDialog(selectedSubject);
          handleActionClose();
        }}>
          <Edit sx={{ mr: 1 }} fontSize="small" />
          Edit Subject
        </MenuItem>
        <MenuItem onClick={() => handleToggleStatus(selectedSubject?.id)}>
          {selectedSubject?.isActive ? (
            <>
              <VisibilityOff sx={{ mr: 1 }} fontSize="small" />
              Deactivate
            </>
          ) : (
            <>
              <Visibility sx={{ mr: 1 }} fontSize="small" />
              Activate
            </>
          )}
        </MenuItem>
        <MenuItem 
          onClick={() => handleDelete(selectedSubject?.id)}
          sx={{ color: 'error.main' }}
        >
          <Delete sx={{ mr: 1 }} fontSize="small" />
          Delete Subject
        </MenuItem>
      </Menu>

      {/* Subject Dialog */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedSubject ? 'Edit Subject' : 'Add New Subject'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Subject Name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Category</InputLabel>
                <Select
                  value={formData.category}
                  label="Category"
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  required
                >
                  {categories.map((category) => (
                    <MenuItem key={category} value={category}>
                      {category}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControl fullWidth>
                <InputLabel>Grade Levels</InputLabel>
                <Select
                  multiple
                  value={formData.gradeLevel}
                  label="Grade Levels"
                  onChange={(e) => setFormData({ ...formData, gradeLevel: e.target.value })}
                  renderValue={(selected) => (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {selected.map((value) => (
                        <Chip key={value} label={value} size="small" />
                      ))}
                    </Box>
                  )}
                >
                  {gradeLevels.map((level) => (
                    <MenuItem key={level} value={level}>
                      {level}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                multiline
                rows={3}
              />
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.isActive}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  />
                }
                label="Active"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button 
            variant="contained" 
            onClick={handleSave}
            disabled={!formData.name || !formData.category}
          >
            {selectedSubject ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default SubjectManagement;
