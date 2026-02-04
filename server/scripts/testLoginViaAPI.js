const axios = require('axios');

async function testLoginViaAPI() {
  try {
    const baseURL = 'https://tutor-app-backend-wtru.onrender.com/api';
    
    console.log('🌐 Testing login via Render API...');
    console.log('   URL:', `${baseURL}/auth/login`);
    
    const credentials = {
      email: 'etsebruk.test@gmail.com',
      password: '123abc'
    };
    
    console.log('\n📤 Sending login request...');
    console.log('   Email:', credentials.email);
    console.log('   Password:', credentials.password);
    
    try {
      const response = await axios.post(`${baseURL}/auth/login`, credentials);
      
      console.log('\n✅ LOGIN SUCCESSFUL!');
      console.log('   Status:', response.status);
      console.log('   User:', response.data.data?.user?.firstName, response.data.data?.user?.lastName);
      console.log('   Role:', response.data.data?.user?.role);
      console.log('   Token:', response.data.data?.token?.substring(0, 20) + '...');
      
    } catch (error) {
      if (error.response) {
        console.log('\n❌ LOGIN FAILED!');
        console.log('   Status:', error.response.status);
        console.log('   Message:', error.response.data?.message);
        console.log('   Full response:', JSON.stringify(error.response.data, null, 2));
        
        // Try with old email
        console.log('\n🔄 Trying with OLD email (etsebruk@example.com)...');
        try {
          const oldResponse = await axios.post(`${baseURL}/auth/login`, {
            email: 'etsebruk@example.com',
            password: '123abc'
          });
          console.log('✅ OLD EMAIL WORKS! The database update did NOT reach Render!');
          console.log('   User:', oldResponse.data.data?.user?.firstName);
        } catch (oldError) {
          console.log('❌ Old email also fails:', oldError.response?.data?.message);
        }
        
      } else {
        console.log('\n❌ Network error:', error.message);
      }
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testLoginViaAPI();
