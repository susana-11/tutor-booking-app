import axios from 'axios';

// Configure axios defaults
axios.defaults.timeout = 120000; // 120 seconds (2 minutes) for Render free tier wake-up
axios.defaults.headers.common['Content-Type'] = 'application/json';

// Add request interceptor for debugging
axios.interceptors.request.use(
  (config) => {
    console.log('🚀 API Request:', config.method?.toUpperCase(), config.url);
    return config;
  },
  (error) => {
    console.error('❌ Request Error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor for debugging
axios.interceptors.response.use(
  (response) => {
    console.log('✅ API Response:', response.config.url, response.status);
    return response;
  },
  (error) => {
    if (error.code === 'ECONNABORTED') {
      console.error('⏱️ Request Timeout - Server may be waking up. Please wait and try again.');
    } else if (error.response) {
      console.error('❌ API Error:', error.response.status, error.response.data);
    } else if (error.request) {
      console.error('❌ No Response:', error.message);
    } else {
      console.error('❌ Error:', error.message);
    }
    return Promise.reject(error);
  }
);

export default axios;
