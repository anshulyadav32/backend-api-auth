#!/usr/bin/env node
/**
 * COMPREHENSIVE AUTHENTICATION SYSTEM TEST SUITE
 * Tests every component and feature systematically
 */

const https = require('https');
const http = require('http');
const querystring = require('querystring');

const BASE_URL = 'http://localhost:8080';
let authToken = '';
let refreshToken = '';
let csrfToken = '';
let mfaSecret = '';
let testUserId = '';

// Colors for console output
const colors = {
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m',
    bold: '\x1b[1m'
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function makeRequest(method, path, data = null, headers = {}) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 8080,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'Test-Suite/1.0',
                ...headers
            }
        };

        if (data) {
            const postData = JSON.stringify(data);
            options.headers['Content-Length'] = Buffer.byteLength(postData);
        }

        const req = http.request(options, (res) => {
            let responseData = '';
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(responseData);
                    resolve({ status: res.statusCode, data: parsed, headers: res.headers });
                } catch (e) {
                    resolve({ status: res.statusCode, data: responseData, headers: res.headers });
                }
            });
        });

        req.on('error', (err) => {
            reject(err);
        });

        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function testApiEndpoint(name, method, path, data, expectedStatus, token = null) {
    try {
        const headers = {};
        if (token) headers['Authorization'] = `Bearer ${token}`;
        if (csrfToken) headers['X-CSRF-Token'] = csrfToken;

        const response = await makeRequest(method, path, data, headers);
        
        if (response.status === expectedStatus) {
            log(`✅ ${name}: PASSED (${response.status})`, 'green');
            return response;
        } else {
            log(`❌ ${name}: FAILED - Expected ${expectedStatus}, got ${response.status}`, 'red');
            console.log('Response:', response.data);
            return response;
        }
    } catch (error) {
        log(`❌ ${name}: ERROR - ${error.message}`, 'red');
        return null;
    }
}

async function runComprehensiveTests() {
    log('\n🚀 STARTING COMPREHENSIVE AUTHENTICATION SYSTEM TESTS', 'bold');
    log('=' * 60, 'blue');

    // Test 1: Server Health Check
    log('\n📋 PHASE 1: BASIC SERVER FUNCTIONALITY', 'blue');
    await testApiEndpoint('Health Check', 'GET', '/health', null, 200);
    await testApiEndpoint('Index Endpoint', 'GET', '/', null, 200);

    // Test 2: User Registration
    log('\n📋 PHASE 2: USER REGISTRATION', 'blue');
    const userData = {
        email: 'testuser@example.com',
        password: 'SecurePass123!',
        name: 'Test User'
    };
    
    const registerResponse = await testApiEndpoint('User Registration', 'POST', '/auth/register', userData, 201);
    if (registerResponse && registerResponse.data.user) {
        testUserId = registerResponse.data.user.id;
        log(`   User ID: ${testUserId}`, 'yellow');
    }

    // Test 3: User Login
    log('\n📋 PHASE 3: USER LOGIN', 'blue');
    const loginData = {
        email: userData.email,
        password: userData.password
    };
    
    const loginResponse = await testApiEndpoint('User Login', 'POST', '/auth/login', loginData, 200);
    if (loginResponse && loginResponse.data.accessToken) {
        authToken = loginResponse.data.accessToken;
        log(`   Access Token: ${authToken.substring(0, 20)}...`, 'yellow');
    }

    // Test 4: Protected Route Access
    log('\n📋 PHASE 4: PROTECTED ROUTES', 'blue');
    await testApiEndpoint('Profile Access (With Token)', 'GET', '/auth/profile', null, 200, authToken);
    await testApiEndpoint('Profile Access (Without Token)', 'GET', '/auth/profile', null, 401);

    // Test 5: MFA Setup
    log('\n📋 PHASE 5: MULTI-FACTOR AUTHENTICATION', 'blue');
    const mfaSetupResponse = await testApiEndpoint('MFA Setup', 'POST', '/auth/mfa/setup', null, 200, authToken);
    if (mfaSetupResponse && mfaSetupResponse.data.secret) {
        mfaSecret = mfaSetupResponse.data.secret;
        log(`   MFA Secret: ${mfaSecret.substring(0, 10)}...`, 'yellow');
        log(`   QR Code URL: ${mfaSetupResponse.data.qrCodeUrl ? 'Generated' : 'Not generated'}`, 'yellow');
    }

    // Test 6: Token Refresh
    log('\n📋 PHASE 6: TOKEN REFRESH', 'blue');
    await testApiEndpoint('Token Refresh', 'POST', '/auth/refresh', null, 200);

    // Test 7: Admin Functions (if user has admin rights)
    log('\n📋 PHASE 7: ADMIN FUNCTIONALITY', 'blue');
    await testApiEndpoint('List Users (Admin)', 'GET', '/auth/admin/users', null, 403, authToken); // Should fail for non-admin

    // Test 8: Security Headers
    log('\n📋 PHASE 8: SECURITY FEATURES', 'blue');
    const securityResponse = await makeRequest('GET', '/');
    if (securityResponse && securityResponse.headers) {
        const securityHeaders = [
            'x-content-type-options',
            'x-frame-options',
            'x-xss-protection',
            'strict-transport-security'
        ];
        
        securityHeaders.forEach(header => {
            if (securityResponse.headers[header]) {
                log(`✅ Security Header: ${header}`, 'green');
            } else {
                log(`❌ Missing Security Header: ${header}`, 'red');
            }
        });
    }

    // Test 9: Rate Limiting
    log('\n📋 PHASE 9: RATE LIMITING', 'blue');
    log('Testing rate limiting (will make multiple requests)...', 'yellow');
    
    for (let i = 0; i < 5; i++) {
        const rateLimitResponse = await testApiEndpoint(
            `Rate Limit Test ${i + 1}`, 
            'POST', 
            '/auth/login', 
            { email: 'fake@test.com', password: 'wrongpass' }, 
            401
        );
        await new Promise(resolve => setTimeout(resolve, 100)); // Small delay
    }

    // Test 10: Input Validation
    log('\n📋 PHASE 10: INPUT VALIDATION', 'blue');
    await testApiEndpoint('Invalid Email Format', 'POST', '/auth/register', 
        { email: 'invalid-email', password: 'pass', name: 'Test' }, 400);
    
    await testApiEndpoint('Weak Password', 'POST', '/auth/register', 
        { email: 'test@test.com', password: '123', name: 'Test' }, 400);

    // Test 11: OAuth Test Page
    log('\n📋 PHASE 11: OAUTH INTERFACE', 'blue');
    await testApiEndpoint('OAuth Test Page', 'GET', '/oauth-test.html', null, 200);

    // Test 12: Logout
    log('\n📋 PHASE 12: LOGOUT', 'blue');
    await testApiEndpoint('User Logout', 'POST', '/auth/logout', null, 200, authToken);

    // Test 13: Access After Logout
    log('\n📋 PHASE 13: POST-LOGOUT SECURITY', 'blue');
    await testApiEndpoint('Profile Access After Logout', 'GET', '/auth/profile', null, 401, authToken);

    // Final Summary
    log('\n🎉 COMPREHENSIVE TESTING COMPLETED!', 'bold');
    log('=' * 60, 'blue');
    log('Check the results above for any failures that need attention.', 'yellow');
}

// Run the tests
runComprehensiveTests().catch(console.error);
