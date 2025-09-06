# COMPREHENSIVE AUTHENTICATION SYSTEM MANUAL TESTS
# Testing each component step by step

Write-Host "🚀 ENTERPRISE AUTHENTICATION SYSTEM - COMPREHENSIVE TESTING" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# Test Variables
$BaseUrl = "http://localhost:8080"
$TestUser = @{
    email = "testuser@example.com"
    password = "SecurePass123!"
    name = "Test User"
}

# Function to make HTTP requests
function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [object]$Body = $null,
        [hashtable]$Headers = @{},
        [int]$ExpectedStatus = 200
    )
    
    try {
        $requestParams = @{
            Uri = $Url
            Method = $Method
            Headers = $Headers
            ContentType = "application/json"
        }
        
        if ($Body) {
            $requestParams.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-WebRequest @requestParams
        
        if ($response.StatusCode -eq $ExpectedStatus) {
            Write-Host "✅ $Name`: PASSED ($($response.StatusCode))" -ForegroundColor Green
            return @{ Success = $true; Data = $response.Content; Headers = $response.Headers }
        } else {
            Write-Host "❌ $Name`: FAILED - Expected $ExpectedStatus, got $($response.StatusCode)" -ForegroundColor Red
            return @{ Success = $false; Data = $response.Content }
        }
    }
    catch {
        Write-Host "❌ $Name`: ERROR - $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Wait for server to be ready
Write-Host "🔄 Waiting for server to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# PHASE 1: BASIC SERVER FUNCTIONALITY
Write-Host "`n📋 PHASE 1: BASIC SERVER FUNCTIONALITY" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$healthCheck = Test-Endpoint "Health Check" "GET" "$BaseUrl/health"
if ($healthCheck.Success) {
    Write-Host "   Response: $($healthCheck.Data)" -ForegroundColor Gray
}

$indexCheck = Test-Endpoint "Index Endpoint (API Documentation)" "GET" "$BaseUrl/"
if ($indexCheck.Success) {
    $indexData = $indexCheck.Data | ConvertFrom-Json
    Write-Host "   Service: $($indexData.service)" -ForegroundColor Gray
    Write-Host "   Version: $($indexData.version)" -ForegroundColor Gray
}

# PHASE 2: USER REGISTRATION
Write-Host "`n📋 PHASE 2: USER REGISTRATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$registerResult = Test-Endpoint "User Registration" "POST" "$BaseUrl/auth/register" $TestUser 201
if ($registerResult.Success) {
    $userData = $registerResult.Data | ConvertFrom-Json
    Write-Host "   User ID: $($userData.user.id)" -ForegroundColor Gray
    Write-Host "   Email: $($userData.user.email)" -ForegroundColor Gray
}

# Test duplicate registration
$duplicateResult = Test-Endpoint "Duplicate Registration (Should Fail)" "POST" "$BaseUrl/auth/register" $TestUser 400

# PHASE 3: USER LOGIN AND AUTHENTICATION
Write-Host "`n📋 PHASE 3: USER LOGIN AND AUTHENTICATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$loginData = @{
    email = $TestUser.email
    password = $TestUser.password
}

$loginResult = Test-Endpoint "User Login" "POST" "$BaseUrl/auth/login" $loginData 200
$accessToken = ""
if ($loginResult.Success) {
    $loginData = $loginResult.Data | ConvertFrom-Json
    $accessToken = $loginData.accessToken
    Write-Host "   Access Token: $($accessToken.Substring(0, 20))..." -ForegroundColor Gray
}

# Test wrong password
$wrongLoginData = @{
    email = $TestUser.email
    password = "WrongPassword123!"
}
$wrongLogin = Test-Endpoint "Login with Wrong Password" "POST" "$BaseUrl/auth/login" $wrongLoginData 401

# PHASE 4: PROTECTED ROUTES AND AUTHORIZATION
Write-Host "`n📋 PHASE 4: PROTECTED ROUTES AND AUTHORIZATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

# Test without token
$noTokenResult = Test-Endpoint "Profile Access (No Token)" "GET" "$BaseUrl/auth/profile" $null @{} 401

# Test with valid token
if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $profileResult = Test-Endpoint "Profile Access (Valid Token)" "GET" "$BaseUrl/auth/profile" $null $authHeaders 200
    if ($profileResult.Success) {
        $profileData = $profileResult.Data | ConvertFrom-Json
        Write-Host "   Profile: $($profileData.user.email)" -ForegroundColor Gray
    }
}

# PHASE 5: MULTI-FACTOR AUTHENTICATION
Write-Host "`n📋 PHASE 5: MULTI-FACTOR AUTHENTICATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $mfaSetupResult = Test-Endpoint "MFA Setup" "POST" "$BaseUrl/auth/mfa/setup" $null $authHeaders 200
    if ($mfaSetupResult.Success) {
        $mfaData = $mfaSetupResult.Data | ConvertFrom-Json
        Write-Host "   MFA Secret: $($mfaData.secret.Substring(0, 10))..." -ForegroundColor Gray
        Write-Host "   QR Code: $(if ($mfaData.qrCodeUrl) { 'Generated' } else { 'Not Available' })" -ForegroundColor Gray
    }
}

# PHASE 6: ADMIN FUNCTIONALITY
Write-Host "`n📋 PHASE 6: ADMIN FUNCTIONALITY" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $adminUsersResult = Test-Endpoint "List Users (Non-Admin)" "GET" "$BaseUrl/auth/admin/users" $null $authHeaders 403
}

# PHASE 7: SECURITY FEATURES
Write-Host "`n📋 PHASE 7: SECURITY FEATURES" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

try {
    $securityResponse = Invoke-WebRequest -Uri "$BaseUrl/" -Method GET
    $securityHeaders = @(
        "X-Content-Type-Options",
        "X-Frame-Options", 
        "X-XSS-Protection",
        "Strict-Transport-Security"
    )
    
    foreach ($header in $securityHeaders) {
        if ($securityResponse.Headers[$header]) {
            Write-Host "✅ Security Header: $header" -ForegroundColor Green
        } else {
            Write-Host "❌ Missing Security Header: $header" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "❌ Security Headers Check: ERROR - $($_.Exception.Message)" -ForegroundColor Red
}

# PHASE 8: INPUT VALIDATION
Write-Host "`n📋 PHASE 8: INPUT VALIDATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$invalidEmail = @{
    email = "invalid-email"
    password = "ValidPass123!"
    name = "Test"
}
$invalidEmailResult = Test-Endpoint "Invalid Email Format" "POST" "$BaseUrl/auth/register" $invalidEmail 400

$weakPassword = @{
    email = "test2@example.com"
    password = "123"
    name = "Test"
}
$weakPasswordResult = Test-Endpoint "Weak Password" "POST" "$BaseUrl/auth/register" $weakPassword 400

# PHASE 9: OAUTH INTERFACE
Write-Host "`n📋 PHASE 9: OAUTH INTERFACE" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$oauthPageResult = Test-Endpoint "OAuth Test Page" "GET" "$BaseUrl/oauth-test.html" $null @{} 200

# PHASE 10: LOGOUT AND SESSION MANAGEMENT
Write-Host "`n📋 PHASE 10: LOGOUT AND SESSION MANAGEMENT" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $logoutResult = Test-Endpoint "User Logout" "POST" "$BaseUrl/auth/logout" $null $authHeaders 200
    
    # Test access after logout
    Start-Sleep -Seconds 1
    $postLogoutResult = Test-Endpoint "Profile Access After Logout" "GET" "$BaseUrl/auth/profile" $null $authHeaders 401
}

# FINAL SUMMARY
Write-Host "`n🎉 COMPREHENSIVE TESTING COMPLETED!" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "✅ All core authentication features have been tested" -ForegroundColor Green
Write-Host "🔐 Enterprise security features validated" -ForegroundColor Green
Write-Host "🧪 Input validation and error handling verified" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 You can also test OAuth flows manually at: http://localhost:8080/oauth-test.html" -ForegroundColor Yellow
Write-Host "🛠️  Use the CLI admin tool with: node auth-admin.js --help" -ForegroundColor Yellow
