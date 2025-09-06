// test.js
const http = require('http');

// Test registration
const registerData = JSON.stringify({
  email: 'test@example.com',
  username: 'testuser',
  password: 'SuperStrongPass#123'
});

const registerOptions = {
  hostname: 'localhost',
  port: 8080,
  path: '/auth/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': registerData.length
  }
};

const registerReq = http.request(registerOptions, res => {
  console.log(`Registration status: ${res.statusCode}`);
  
  let data = '';
  res.on('data', chunk => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Registration response:', data);
    
    // If registration successful, test login
    if (res.statusCode === 201) {
      testLogin();
    }
  });
});

registerReq.on('error', error => {
  console.error('Error during registration:', error);
});

registerReq.write(registerData);
registerReq.end();

// Test login
function testLogin() {
  const loginData = JSON.stringify({
    emailOrUsername: 'testuser',
    password: 'SuperStrongPass#123'
  });
  
  const loginOptions = {
    hostname: 'localhost',
    port: 8080,
    path: '/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': loginData.length
    }
  };
  
  const loginReq = http.request(loginOptions, res => {
    console.log(`Login status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', chunk => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Login response:', data);
    });
  });
  
  loginReq.on('error', error => {
    console.error('Error during login:', error);
  });
  
  loginReq.write(loginData);
  loginReq.end();
}
