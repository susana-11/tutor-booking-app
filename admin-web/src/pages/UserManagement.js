import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  InputAdornment,
  Chip,
  Avatar,
  IconButton,
  Menu,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  Grid,
  Tabs,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Tooltip,
  Alert,
  CircularProgress,
} from '@mui/material';
import {
  Search,
  Add,
  MoreVert,
  Edit,
  Delete,
  Block,
  CheckCircle,
  Email,
  Phone,
  Person,
  School,
  Warning,
  Refresh,
} from '@mui/icons-material';
import toast from 'react-hot-toast';
import axios from 'axios';

const UserManagement = () => {
  const [users, setUsers] = useState({ students: [], tutors: [] });
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedTab, setSelectedTab] = useState(0);
  const [selectedUser, setSelectedUser] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [actionMenuAnchor, setActionMenuAnchor] = useState(null);
  const [stats, setStats] = useState({});

  // Fetch users data
  const fetchUsers = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('adminToken');
      const response = await axios.get('/api/admin/users/by-role', {
        headers: { Authorization: `Bearer ${token}` }
      });

      if (response.data.success) {
        setUsers(response.data.data);
        setStats(response.data.data.stats);
      }
    } catch (error) {
      console.error('Error fetching users:', error);
      toast.error('Failed to fetch users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleSearch = (event) => {
    setSearchTerm(event.target.value);
  };

  const handleTabChange = (event, newValue) => {
    setSelectedTab(newValue);
  };

  const handleActionClick = (event, user) => {
    setSelectedUser(user);
    setActionMenuAnchor(event.currentTarget);
  };

  const handleActionClose = () => {
    setActionMenuAnchor(null);
    setSelectedUser(null);
  };

  const handleStatusChange = async (userId, newStatus) => {
    try {
      const token = localStorage.getItem('adminToken');
      const endpoint = newStatus === 'active' ? 'activate' : 'suspend';
      
      await axios.post(`/api/admin/users/${userId}/${endpoint}`, {}, {
        headers: { Authorization: `Bearer ${token}` }
      });

      toast.success(`User ${newStatus === 'active' ? 'activated' : 'suspended'} successfully`);
      fetchUsers(); // Refresh data
    } catch (error) {
      console.error('Error updating user status:', error);
      toast.error('Failed to update user status');
    }
    handleActionClose();
  };

  const handleDeleteUser = async (permanent = false) => {
    try {
      const token = localStorage.getItem('adminToken');
      
      await axios.delete(`/api/admin/users/${selectedUser._id}`, {
        headers: { Authorization: `Bearer ${token}` },
        data: { permanent }
      });

      toast.success(permanent ? 'User permanently deleted' : 'User deactivated successfully');
      fetchUsers(); // Refresh data
      setDeleteDialogOpen(false);
    } catch (error) {
      console.error('Error deleting user:', error);
      toast.error(error.response?.data?.message || 'Failed to delete user');
    }
    handleActionClose();
  };

  const handleViewDetails = (user) => {
    setSelectedUser(user);
    setDialogOpen(true);
    handleActionClose();
  };

  const filterUsers = (userList) => {
    return userList.filter(user => {
      const fullName = `${user.firstName} ${user.lastName}`.toLowerCase();
      const email = user.email.toLowerCase();
      const searchLower = searchTerm.toLowerCase();
      
      return fullName.includes(searchLower) || email.includes(searchLower);
    });
  };

  const getStatusColor = (isActive) => {
    return isActive ? 'success' : 'error';
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString();
  };

  const UserTable = ({ userList, userType }) => {
    const filteredUsers = filterUsers(userList);

    return (
      <TableContainer component={Paper} sx={{ mt: 2 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>User</TableCell>
              <TableCell>Contact</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Profile</TableCell>
              {userType === 'tutor' && <TableCell>Tutor Info</TableCell>}
              {userType === 'student' && <TableCell>Student Info</TableCell>}
              <TableCell>Joined</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredUsers.map((user) => (
              <TableRow key={user._id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar sx={{ width: 40, height: 40 }}>
                      {user.firstName.charAt(0)}
                    </Avatar>
                    <Box>
                      <Typography variant="body2" fontWeight="medium">
                        {`${user.firstName} ${user.lastName}`}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        ID: {user._id.slice(-6)}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                
                <TableCell>
                  <Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                      <Email fontSize="small" color="action" />
                      <Typography variant="body2">{user.email}</Typography>
                      {user.isEmailVerified && (
                        <CheckCircle fontSize="small" color="success" />
                      )}
                    </Box>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Phone fontSize="small" color="action" />
                      <Typography variant="body2">{user.phone}</Typography>
                    </Box>
                  </Box>
                </TableCell>
                
                <TableCell>
                  <Chip
                    label={user.isActive ? 'Active' : 'Inactive'}
                    color={getStatusColor(user.isActive)}
                    size="small"
                  />
                </TableCell>
                
                <TableCell>
                  <Box>
                    <Chip
                      label={user.isEmailVerified ? 'Email Verified' : 'Not Verified'}
                      color={user.isEmailVerified ? 'success' : 'warning'}
                      size="small"
                      sx={{ mb: 0.5 }}
                    />
                    <br />
                    <Chip
                      label={user.profileCompleted ? 'Complete' : 'Incomplete'}
                      color={user.profileCompleted ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                </TableCell>
                
                {userType === 'tutor' && (
                  <TableCell>
                    {user.profile ? (
                      <Box>
                        <Chip
                          label={user.profile.status || 'No Status'}
                          color={
                            user.profile.status === 'approved' ? 'success' :
                            user.profile.status === 'pending' ? 'warning' : 'error'
                          }
                          size="small"
                          sx={{ mb: 0.5 }}
                        />
                        <Typography variant="caption" display="block">
                          Rate: ${user.profile.pricing?.hourlyRate || 'N/A'}/hr
                        </Typography>
                        <Typography variant="caption" display="block">
                          Rating: {user.profile.stats?.averageRating || 'N/A'} ⭐
                        </Typography>
                      </Box>
                    ) : (
                      <Typography variant="caption" color="text.secondary">
                        No profile
                      </Typography>
                    )}
                  </TableCell>
                )}
                
                {userType === 'student' && (
                  <TableCell>
                    {user.profile ? (
                      <Box>
                        <Typography variant="caption" display="block">
                          Grade: {user.profile.grade || 'N/A'}
                        </Typography>
                        <Typography variant="caption" display="block">
                          School: {user.profile.school || 'N/A'}
                        </Typography>
                        <Typography variant="caption" display="block">
                          Subjects: {user.profile.interestedSubjects?.length || 0}
                        </Typography>
                      </Box>
                    ) : (
                      <Typography variant="caption" color="text.secondary">
                        No profile
                      </Typography>
                    )}
                  </TableCell>
                )}
                
                <TableCell>
                  <Typography variant="body2">
                    {formatDate(user.createdAt)}
                  </Typography>
                  {user.lastLogin && (
                    <Typography variant="caption" color="text.secondary" display="block">
                      Last: {formatDate(user.lastLogin)}
                    </Typography>
                  )}
                </TableCell>
                
                <TableCell>
                  <IconButton
                    size="small"
                    onClick={(e) => handleActionClick(e, user)}
                  >
                    <MoreVert />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
            {filteredUsers.length === 0 && (
              <TableRow>
                <TableCell colSpan={userType === 'tutor' ? 7 : 7} align="center">
                  <Typography variant="body2" color="text.secondary" sx={{ py: 4 }}>
                    No {userType}s found
                  </Typography>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
    );
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" fontWeight="bold">
          User Management
        </Typography>
        <Button
          variant="outlined"
          startIcon={<Refresh />}
          onClick={fetchUsers}
          disabled={loading}
        >
          Refresh
        </Button>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'primary.main' }}>
                  <Person />
                </Avatar>
                <Box>
                  <Typography variant="h6">{stats.totalStudents || 0}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Students
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'success.main' }}>
                  <School />
                </Avatar>
                <Box>
                  <Typography variant="h6">{stats.totalTutors || 0}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Tutors
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'info.main' }}>
                  <CheckCircle />
                </Avatar>
                <Box>
                  <Typography variant="h6">{stats.activeTutors || 0}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Active Tutors
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <Avatar sx={{ bgcolor: 'warning.main' }}>
                  <Warning />
                </Avatar>
                <Box>
                  <Typography variant="h6">{stats.pendingTutors || 0}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Pending Tutors
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Search */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <TextField
            fullWidth
            placeholder="Search users by name or email..."
            value={searchTerm}
            onChange={handleSearch}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search />
                </InputAdornment>
              ),
            }}
          />
        </CardContent>
      </Card>

      {/* Tabs */}
      <Card>
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={selectedTab} onChange={handleTabChange}>
            <Tab 
              label={`Students (${users.students?.length || 0})`} 
              icon={<Person />} 
              iconPosition="start"
            />
            <Tab 
              label={`Tutors (${users.tutors?.length || 0})`} 
              icon={<School />} 
              iconPosition="start"
            />
          </Tabs>
        </Box>

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            {selectedTab === 0 && (
              <UserTable userList={users.students || []} userType="student" />
            )}
            {selectedTab === 1 && (
              <UserTable userList={users.tutors || []} userType="tutor" />
            )}
          </>
        )}
      </Card>

      {/* Action Menu */}
      <Menu
        anchorEl={actionMenuAnchor}
        open={Boolean(actionMenuAnchor)}
        onClose={handleActionClose}
      >
        <MenuItem onClick={() => handleViewDetails(selectedUser)}>
          <Edit sx={{ mr: 1 }} fontSize="small" />
          View Details
        </MenuItem>
        {selectedUser?.isActive ? (
          <MenuItem onClick={() => handleStatusChange(selectedUser._id, 'inactive')}>
            <Block sx={{ mr: 1 }} fontSize="small" />
            Suspend User
          </MenuItem>
        ) : (
          <MenuItem onClick={() => handleStatusChange(selectedUser._id, 'active')}>
            <CheckCircle sx={{ mr: 1 }} fontSize="small" />
            Activate User
          </MenuItem>
        )}
        <MenuItem 
          onClick={() => setDeleteDialogOpen(true)}
          sx={{ color: 'error.main' }}
        >
          <Delete sx={{ mr: 1 }} fontSize="small" />
          Delete User
        </MenuItem>
      </Menu>

      {/* User Details Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedUser ? `${selectedUser.firstName} ${selectedUser.lastName}` : 'User Details'}
        </DialogTitle>
        <DialogContent>
          {selectedUser && (
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="First Name"
                  value={selectedUser.firstName}
                  margin="normal"
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Last Name"
                  value={selectedUser.lastName}
                  margin="normal"
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Email"
                  value={selectedUser.email}
                  margin="normal"
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Phone"
                  value={selectedUser.phone}
                  margin="normal"
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Role"
                  value={selectedUser.role}
                  margin="normal"
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Status"
                  value={selectedUser.isActive ? 'Active' : 'Inactive'}
                  margin="normal"
                  InputProps={{ readOnly: true }}
                />
              </Grid>
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
                  <Chip
                    label={selectedUser.isEmailVerified ? 'Email Verified' : 'Email Not Verified'}
                    color={selectedUser.isEmailVerified ? 'success' : 'error'}
                    icon={selectedUser.isEmailVerified ? <CheckCircle /> : <Email />}
                  />
                  <Chip
                    label={selectedUser.profileCompleted ? 'Profile Complete' : 'Profile Incomplete'}
                    color={selectedUser.profileCompleted ? 'success' : 'warning'}
                  />
                </Box>
              </Grid>
              {selectedUser.profile && (
                <Grid item xs={12}>
                  <Typography variant="h6" sx={{ mt: 2, mb: 1 }}>
                    Profile Information
                  </Typography>
                  <pre style={{ fontSize: '12px', background: '#f5f5f5', padding: '10px', borderRadius: '4px' }}>
                    {JSON.stringify(selectedUser.profile, null, 2)}
                  </pre>
                </Grid>
              )}
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Delete User</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This action cannot be undone. Choose your deletion method:
          </Alert>
          <Typography variant="body2" sx={{ mb: 2 }}>
            <strong>Deactivate:</strong> User account will be disabled but data preserved.
          </Typography>
          <Typography variant="body2">
            <strong>Permanent Delete:</strong> User and all associated data will be permanently removed.
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button 
            onClick={() => handleDeleteUser(false)}
            color="warning"
          >
            Deactivate
          </Button>
          <Button 
            onClick={() => handleDeleteUser(true)}
            color="error"
          >
            Permanent Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default UserManagement;