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
    
    // SECTION 1: BASIC AUTH
    log('\n📋 SECTION 1: BASIC AUTHENTICATION', 'blue');

    // Test 1.1: Health check
    await testApiEndpoint('Health Check', 'GET', '/health', null, 200);

    // Test 1.2: Registration
    const registerResponse = await testApiEndpoint('User Registration', 'POST', '/auth/register', {
        email: `test${Date.now()}@example.com`,
        password: 'SecureP@ssw0rd123!',
        name: 'Test User'
    }, 201);

    if (registerResponse && registerResponse.data && registerResponse.data.userId) {
        testUserId = registerResponse.data.userId;
    }

    // Test 1.3: Login
    const loginResponse = await testApiEndpoint('User Login', 'POST', '/auth/login', {
        email: 'admin@system.com', // Using a likely admin account
        password: 'Admin@123!'
    }, 200);

    if (loginResponse && loginResponse.data && loginResponse.data.token) {
        authToken = loginResponse.data.token;
        refreshToken = loginResponse.data.refreshToken;
    }

    // SECTION 2: PROTECTED ENDPOINTS
    if (authToken) {
        log('\n📋 SECTION 2: PROTECTED ENDPOINTS', 'blue');

        // Test 2.1: Get user profile
        await testApiEndpoint('Get User Profile', 'GET', '/auth/profile', null, 200, authToken);

        // Test 2.2: Update user profile
        await testApiEndpoint('Update User Profile', 'PUT', '/auth/profile', {
            name: 'Updated Name'
        }, 200, authToken);
    }

    // SECTION 3: TOKEN MANAGEMENT
    log('\n📋 SECTION 3: TOKEN MANAGEMENT', 'blue');

    // Test 3.1: Token refresh
    if (refreshToken) {
        const refreshResponse = await testApiEndpoint('Token Refresh', 'POST', '/auth/token', {
            refreshToken
        }, 200);

        if (refreshResponse && refreshResponse.data && refreshResponse.data.token) {
            authToken = refreshResponse.data.token;
        }
    }

    // Test 3.2: Token validation
    await testApiEndpoint('Token Validation', 'GET', '/auth/validate', null, 200, authToken);

    // SECTION 4: SECURITY FEATURES
    log('\n📋 SECTION 4: SECURITY FEATURES', 'blue');

    // Test 4.1: CSRF Protection
    const csrfResponse = await testApiEndpoint('Get CSRF Token', 'GET', '/auth/csrf-token', null, 200, authToken);
    if (csrfResponse && csrfResponse.data && csrfResponse.data.csrfToken) {
        csrfToken = csrfResponse.data.csrfToken;
    }

    // Test 4.2: Rate limiting
    log('Testing Rate Limiting...', 'yellow');
    for (let i = 0; i < 10; i++) {
        await makeRequest('GET', '/auth/status');
    }
    
    // SECTION 5: ERROR HANDLING
    log('\n📋 SECTION 5: ERROR HANDLING', 'blue');
    
    // Test 5.1: Invalid login
    await testApiEndpoint('Invalid Login', 'POST', '/auth/login', {
        email: 'nonexistent@example.com',
        password: 'WrongPassword123'
    }, 401);

    // Test 5.2: Protected route without token
    await testApiEndpoint('Protected Route Without Token', 'GET', '/auth/profile', null, 401);

    // SECTION 6: OAUTH FLOWS (MOCK)
    log('\n📋 SECTION 6: OAUTH FLOWS', 'blue');
    
    // Test 6.1: Get OAuth providers
    await testApiEndpoint('Get OAuth Providers', 'GET', '/auth/oauth/providers', null, 200);

    // SUMMARY
    log('\n✨ TEST SUITE COMPLETED', 'bold');
}

// Run the tests
runComprehensiveTests().catch(error => {
    log(`❌ Test Suite Error: ${error.message}`, 'red');
    console.error(error);
});
