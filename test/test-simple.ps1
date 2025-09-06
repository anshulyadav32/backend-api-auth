# COMPREHENSIVE AUTHENTICATION SYSTEM MANUAL TESTS
Write-Host "ENTERPRISE AUTHENTICATION SYSTEM - COMPREHENSIVE TESTING" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host ""

# Test Variables
$BaseUrl = "http://localhost:8080"
$TestUser = @{
    email = "testuser@example.com"
    password = "SecurePass123!"
    name = "Test User"
}

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
            Write-Host "PASS - $Name - ($($response.StatusCode))" -ForegroundColor Green
            return @{ Success = $true; Data = $response.Content; Headers = $response.Headers }
        } else {
            Write-Host "FAIL - $Name - Expected $ExpectedStatus, got $($response.StatusCode)" -ForegroundColor Red
            return @{ Success = $false; Data = $response.Content }
        }
    }
    catch {
        Write-Host "ERROR - $Name - $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Main Test Function
function Run-TestSuite {
    # First, check if server is running
    Write-Host "Waiting for server to be ready..."
    $ready = $false
    $attempts = 0
    
    while (-not $ready -and $attempts -lt 5) {
        try {
            $healthCheck = Invoke-WebRequest -Uri "$BaseUrl/health" -Method GET -ErrorAction SilentlyContinue
            if ($healthCheck.StatusCode -eq 200) {
                $ready = $true
                Write-Host "Server is ready!" -ForegroundColor Green
            }
        }
        catch {
            $attempts++
            Write-Host "Waiting for server... (Attempt $attempts/5)" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
    
    if (-not $ready) {
        Write-Host "Server is not responding. Make sure it's running on $BaseUrl" -ForegroundColor Red
        return
    }
    
    # SECTION 1: BASIC AUTHENTICATION
    Write-Host "`n[SECTION 1: BASIC AUTHENTICATION]" -ForegroundColor Cyan
    
    # Test 1.1: Health Check
    $healthCheck = Test-Endpoint -Name "Health Check" -Method "GET" -Url "$BaseUrl/health" -ExpectedStatus 200
    
    # Test 1.2: Registration
    $uniqueEmail = "test$(Get-Random)@example.com"
    $registration = Test-Endpoint -Name "User Registration" -Method "POST" -Url "$BaseUrl/auth/register" -Body @{
        email = $uniqueEmail
        password = $TestUser.password
        name = $TestUser.name
    } -ExpectedStatus 201
    
    if ($registration.Success) {
        $registrationData = $registration.Data | ConvertFrom-Json
        $userId = $registrationData.userId
        Write-Host "Registered user ID: $userId" -ForegroundColor Cyan
    }
    
    # Test 1.3: Login
    $login = Test-Endpoint -Name "User Login" -Method "POST" -Url "$BaseUrl/auth/login" -Body @{
        email = $uniqueEmail
        password = $TestUser.password
    } -ExpectedStatus 200
    
    $token = $null
    $refreshToken = $null
    
    if ($login.Success) {
        $loginData = $login.Data | ConvertFrom-Json
        $token = $loginData.token
        $refreshToken = $loginData.refreshToken
        Write-Host "Auth Token: $($token.Substring(0, 10))..." -ForegroundColor Cyan
    }
    
    # SECTION 2: PROTECTED ENDPOINTS
    if ($token) {
        Write-Host "`n[SECTION 2: PROTECTED ENDPOINTS]" -ForegroundColor Cyan
        
        # Test 2.1: Get Profile
        $headers = @{
            "Authorization" = "Bearer $token"
        }
        
        $profile = Test-Endpoint -Name "Get User Profile" -Method "GET" -Url "$BaseUrl/auth/profile" -Headers $headers -ExpectedStatus 200
        
        # Test 2.2: Update Profile
        $updateProfile = Test-Endpoint -Name "Update User Profile" -Method "PUT" -Url "$BaseUrl/auth/profile" -Body @{
            name = "Updated Name"
        } -Headers $headers -ExpectedStatus 200
    }
    
    # SECTION 3: OAUTH FLOWS
    Write-Host "`n[SECTION 3: OAUTH FLOWS]" -ForegroundColor Cyan
    
    # Test 3.1: Get OAuth Providers
    $oauthProviders = Test-Endpoint -Name "Get OAuth Providers" -Method "GET" -Url "$BaseUrl/auth/oauth/providers" -ExpectedStatus 200
    
    # SECTION 4: SECURITY FEATURES
    Write-Host "`n[SECTION 4: SECURITY FEATURES]" -ForegroundColor Cyan
    
    # Test 4.1: Get CSRF Token
    if ($token) {
        $csrfToken = Test-Endpoint -Name "Get CSRF Token" -Method "GET" -Url "$BaseUrl/auth/csrf-token" -Headers $headers -ExpectedStatus 200
    }
    
    # SECTION 5: TOKEN MANAGEMENT
    Write-Host "`n[SECTION 5: TOKEN MANAGEMENT]" -ForegroundColor Cyan
    
    # Test 5.1: Token Refresh
    if ($refreshToken) {
        $tokenRefresh = Test-Endpoint -Name "Token Refresh" -Method "POST" -Url "$BaseUrl/auth/token" -Body @{
            refreshToken = $refreshToken
        } -ExpectedStatus 200
        
        if ($tokenRefresh.Success) {
            $refreshData = $tokenRefresh.Data | ConvertFrom-Json
            $token = $refreshData.token
            Write-Host "New Token: $($token.Substring(0, 10))..." -ForegroundColor Cyan
        }
    }
    
    # SECTION 6: ERROR HANDLING
    Write-Host "`n[SECTION 6: ERROR HANDLING]" -ForegroundColor Cyan
    
    # Test 6.1: Invalid Login
    $invalidLogin = Test-Endpoint -Name "Invalid Login" -Method "POST" -Url "$BaseUrl/auth/login" -Body @{
        email = "nonexistent@example.com"
        password = "WrongPassword123"
    } -ExpectedStatus 401
    
    Write-Host "`n✅ Test Suite Complete" -ForegroundColor Green
}

# Run the test suite
Run-TestSuite
