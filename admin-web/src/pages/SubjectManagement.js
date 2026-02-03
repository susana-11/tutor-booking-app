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
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  MoreVert,
  School,
  Visibility,
  VisibilityOff,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import toast from 'react-hot-toast';

const SubjectManagement = () => {
  const [subjects, setSubjects] = useState([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedSubject, setSelectedSubject] = useState(null);
  const [actionMenuAnchor, setActionMenuAnchor] = useState(null);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    category: '',
    gradeLevel: '',
    isActive: true,
    icon: '',
    color: '#1976d2',
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
    'Elementary (K-5)',
    'Middle School (6-8)',
    'High School (9-12)',
    'College/University',
    'Professional',
  ];

  // Mock data - replace with API calls
  useEffect(() => {
    setSubjects([
      {
        id: 1,
        name: 'Algebra',
        description: 'Basic algebraic concepts and problem solving',
        category: 'Mathematics',
        gradeLevel: 'High School (9-12)',
        isActive: true,
        tutorCount: 15,
        studentCount: 45,
        sessionCount: 120,
        averageRating: 4.5,
        createdDate: '2026-01-01',
        color: '#2196F3',
      },
      {
        id: 2,
        name: 'Calculus',
        description: 'Advanced calculus including derivatives and integrals',
        category: 'Mathematics',
        gradeLevel: 'College/University',
        isActive: true,
        tutorCount: 8,
        studentCount: 25,
        sessionCount: 80,
        averageRating: 4.7,
        createdDate: '2026-01-01',
        color: '#4CAF50',
      },
      {
        id: 3,
        name: 'Physics',
        description: 'Fundamental physics concepts and applications',
        category: 'Sciences',
        gradeLevel: 'High School (9-12)',
        isActive: true,
        tutorCount: 12,
        studentCount: 38,
        sessionCount: 95,
        averageRating: 4.3,
        createdDate: '2026-01-01',
        color: '#FF9800',
      },
      {
        id: 4,
        name: 'Spanish',
        description: 'Spanish language learning for beginners to advanced',
        category: 'Languages',
        gradeLevel: 'Elementary (K-5)',
        isActive: true,
        tutorCount: 6,
        studentCount: 22,
        sessionCount: 65,
        averageRating: 4.6,
        createdDate: '2026-01-01',
        color: '#E91E63',
      },
      {
        id: 5,
        name: 'SAT Prep',
        description: 'Comprehensive SAT test preparation',
        category: 'Test Preparation',
        gradeLevel: 'High School (9-12)',
        isActive: false,
        tutorCount: 4,
        studentCount: 12,
        sessionCount: 30,
        averageRating: 4.2,
        createdDate: '2026-01-01',
        color: '#9C27B0',
      },
    ]);
  }, []);

  const handleOpenDialog = (subject = null) => {
    if (subject) {
      setSelectedSubject(subject);
      setFormData({
        name: subject.name,
        description: subject.description,
        category: subject.category,
        gradeLevel: subject.gradeLevel,
        isActive: subject.isActive,
        icon: subject.icon || '',
        color: subject.color || '#1976d2',
      });
    } else {
      setSelectedSubject(null);
      setFormData({
        name: '',
        description: '',
        category: '',
        gradeLevel: '',
        isActive: true,
        icon: '',
        color: '#1976d2',
      });
    }
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedSubject(null);
    setFormData({
      name: '',
      description: '',
      category: '',
      gradeLevel: '',
      isActive: true,
      icon: '',
      color: '#1976d2',
    });
  };

  const handleSave = async () => {
    try {
      if (selectedSubject) {
        // Update existing subject
        setSubjects(subjects.map(subject =>
          subject.id === selectedSubject.id
            ? { ...subject, ...formData }
            : subject
        ));
        toast.success('Subject updated successfully');
      } else {
        // Create new subject
        const newSubject = {
          id: Math.max(...subjects.map(s => s.id)) + 1,
          ...formData,
          tutorCount: 0,
          studentCount: 0,
          sessionCount: 0,
          averageRating: 0,
          createdDate: new Date().toISOString().split('T')[0],
        };
        setSubjects([...subjects, newSubject]);
        toast.success('Subject created successfully');
      }
      handleCloseDialog();
    } catch (error) {
      toast.error('Failed to save subject');
    }
  };

  const handleDelete = async (subjectId) => {
    if (window.confirm('Are you sure you want to delete this subject?')) {
      try {
        setSubjects(subjects.filter(subject => subject.id !== subjectId));
        toast.success('Subject deleted successfully');
      } catch (error) {
        toast.error('Failed to delete subject');
      }
    }
    handleActionClose();
  };

  const handleToggleStatus = async (subjectId) => {
    try {
      setSubjects(subjects.map(subject =>
        subject.id === subjectId
          ? { ...subject, isActive: !subject.isActive }
          : subject
      ));
      toast.success('Subject status updated');
    } catch (error) {
      toast.error('Failed to update subject status');
    }
    handleActionClose();
  };

  const handleActionClick = (event, subject) => {
    setSelectedSubject(subject);
    setActionMenuAnchor(event.currentTarget);
  };

  const handleActionClose = () => {
    setActionMenuAnchor(null);
    setSelectedSubject(null);
  };

  const columns = [
    {
      field: 'name',
      headerName: 'Subject',
      width: 200,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <Box
            sx={{
              width: 12,
              height: 12,
              borderRadius: '50%',
              backgroundColor: params.row.color,
              mr: 1,
            }}
          />
          <Typography variant="body2" fontWeight="medium">
            {params.value}
          </Typography>
        </Box>
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
      width: 180,
    },
    {
      field: 'tutorCount',
      headerName: 'Tutors',
      width: 100,
      type: 'number',
    },
    {
      field: 'studentCount',
      headerName: 'Students',
      width: 100,
      type: 'number',
    },
    {
      field: 'sessionCount',
      headerName: 'Sessions',
      width: 100,
      type: 'number',
    },
    {
      field: 'averageRating',
      headerName: 'Rating',
      width: 100,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <Typography variant="body2">
            {params.value > 0 ? params.value.toFixed(1) : 'N/A'}
          </Typography>
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
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="overline">
                Total Tutors
              </Typography>
              <Typography variant="h4">
                {subjects.reduce((sum, s) => sum + s.tutorCount, 0)}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="overline">
                Total Sessions
              </Typography>
              <Typography variant="h4">
                {subjects.reduce((sum, s) => sum + s.sessionCount, 0)}
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
            <Grid item xs={12} md={6}>
              <FormControl fullWidth>
                <InputLabel>Grade Level</InputLabel>
                <Select
                  value={formData.gradeLevel}
                  label="Grade Level"
                  onChange={(e) => setFormData({ ...formData, gradeLevel: e.target.value })}
                  required
                >
                  {gradeLevels.map((level) => (
                    <MenuItem key={level} value={level}>
                      {level}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                label="Color"
                type="color"
                value={formData.color}
                onChange={(e) => setFormData({ ...formData, color: e.target.value })}
                InputLabelProps={{ shrink: true }}
              />
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
            disabled={!formData.name || !formData.category || !formData.gradeLevel}
          >
            {selectedSubject ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default SubjectManagement;