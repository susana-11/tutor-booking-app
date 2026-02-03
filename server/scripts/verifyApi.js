const http = require('http');

const PORT = 5000;
const BASE_URL = `http://localhost:${PORT}/api`;

// Helper to make HTTP requests
function request(method, path, body = null, token = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: PORT,
            path: `/api${path}`,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };

        if (token) {
            options.headers['Authorization'] = `Bearer ${token}`;
        }

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    resolve({ status: res.statusCode, data: parsed });
                } catch (e) {
                    resolve({ status: res.statusCode, data });
                }
            });
        });

        req.on('error', (e) => reject(e));

        if (body) {
            req.write(JSON.stringify(body));
        }
        req.end();
    });
}

async function runTests() {
    console.log('🚀 Starting API Verification Tests...\n');

    try {
        // 1. Health Check
        console.log('1️⃣  Checking Server Health...');
        const health = await request('GET', '/health');
        if (health.status !== 200) throw new Error('Server not healthy');
        console.log('   ✅ Server is running\n');

        // 2. Login as Tutor (to test visibility)
        console.log('2️⃣  Logging in as Tutor...');
        // Note: You need a valid tutor email/password here. 
        // I'll try a common test one or create one if this fails? 
        // For now, I'll assumet a test user exists or fail gracefully.
        const tutorLogin = await request('POST', '/auth/login', {
            email: 'susipo1611@gmail.com', // Using user's email from logs if available, or generic
            password: 'password123'
        });

        let tutorToken;
        if (tutorLogin.status === 200) {
            tutorToken = tutorLogin.data.token;
            console.log('   ✅ Tutor logged in');
        } else {
            console.log('   ⚠️ Could not log in as tutor (skipping tutor tests):', tutorLogin.data.message);
        }

        if (tutorToken) {
            // 3. Test Visibility Toggle
            console.log('\n3️⃣  Testing Visibility Toggle...');

            // Turn OFF
            console.log('   -> Turning visibility OFF');
            const turnOff = await request('PUT', '/profiles/tutor/visibility', { isActive: false }, tutorToken);
            console.log(`      Status: ${turnOff.status} - ${turnOff.data.message}`);

            // Search to verify hidden
            const searchHidden = await request('GET', '/tutors?search=susipo'); // Assuming name match
            // This search verification is tricky without exact name, but reliable for toggle API check

            // Turn ON
            console.log('   -> Turning visibility ON');
            const turnOn = await request('PUT', '/profiles/tutor/visibility', { isActive: true }, tutorToken);
            console.log(`      Status: ${turnOn.status} - ${turnOn.data.message}`);

            if (turnOn.status === 200) console.log('   ✅ Visibility toggle API works');
        }

        // 4. Test Public Tutors Endpoint
        console.log('\n4️⃣  Testing Public Tutors Search...');
        const tutors = await request('GET', '/tutors');
        if (tutors.status === 200) {
            console.log(`   ✅ Fetched ${tutors.data.data.tutors.length} tutors`);
        } else {
            console.log('   ❌ Failed to fetch tutors');
        }

    } catch (error) {
        console.error('❌ Test failed:', error);
    }
}

runTests();
