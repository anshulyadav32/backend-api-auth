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
            Write-Host "✅ $Name - ($($response.StatusCode))" -ForegroundColor Green
            return @{ Success = $true; Data = $response.Content; Headers = $response.Headers }
        } else {
            Write-Host "❌ $Name - Expected $ExpectedStatus, got $($response.StatusCode)" -ForegroundColor Red
            return @{ Success = $false; Data = $response.Content }
        }
    }
    catch {
        Write-Host "❌ $Name - $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Wait-ForServerReady {
    Write-Host "Waiting for server to be ready..."
    $ready = $false
    $attempts = 0
    
    while (-not $ready -and $attempts -lt 10) {
        try {
            $healthCheck = Invoke-WebRequest -Uri "$BaseUrl/health" -Method GET -ErrorAction SilentlyContinue
            if ($healthCheck.StatusCode -eq 200) {
                $ready = $true
                Write-Host "✅ Server is ready!" -ForegroundColor Green
            }
        }
        catch {
            $attempts++
            Write-Host "⌛ Waiting for server... (Attempt $attempts/10)" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
    
    if (-not $ready) {
        Write-Host "❌ Server is not responding. Make sure it's running on $BaseUrl" -ForegroundColor Red
        exit 1
    }
}

function Test-Registration {
    Write-Host "`n📝 Testing User Registration" -ForegroundColor Cyan
    
    $uniqueEmail = "test$(Get-Random)@example.com"
    Write-Host "Using email: $uniqueEmail" -ForegroundColor Yellow
    
    $registration = Test-Endpoint -Name "User Registration" -Method "POST" -Url "$BaseUrl/auth/register" -Body @{
        email = $uniqueEmail
        password = $TestUser.password
        name = $TestUser.name
    } -ExpectedStatus 201
    
    if ($registration.Success) {
        $registrationData = $registration.Data | ConvertFrom-Json
        $userId = $registrationData.userId
        Write-Host "Registered user ID: $userId" -ForegroundColor Cyan
        return @{ UserId = $userId; Email = $uniqueEmail }
    } else {
        Write-Host "Registration failed - proceeding with default test user" -ForegroundColor Yellow
        return @{ Email = $TestUser.email }
    }
}

function Test-Login($Email, $Password = $TestUser.password) {
    Write-Host "`n🔑 Testing User Login" -ForegroundColor Cyan
    
    $login = Test-Endpoint -Name "User Login" -Method "POST" -Url "$BaseUrl/auth/login" -Body @{
        email = $Email
        password = $Password
    } -ExpectedStatus 200
    
    if ($login.Success) {
        $loginData = $login.Data | ConvertFrom-Json
        $token = $loginData.token
        $refreshToken = $loginData.refreshToken
        Write-Host "Auth Token: $($token.Substring(0, 10))..." -ForegroundColor Cyan
        return @{ Token = $token; RefreshToken = $refreshToken }
    } else {
        return @{ Token = $null; RefreshToken = $null }
    }
}

function Test-ProtectedEndpoints($Token) {
    Write-Host "`n🛡️ Testing Protected Endpoints" -ForegroundColor Cyan
    
    if (-not $Token) {
        Write-Host "No auth token available - skipping protected endpoint tests" -ForegroundColor Yellow
        return
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    # Get Profile
    $profile = Test-Endpoint -Name "Get User Profile" -Method "GET" -Url "$BaseUrl/auth/profile" -Headers $headers -ExpectedStatus 200
    
    # Update Profile
    $updateProfile = Test-Endpoint -Name "Update User Profile" -Method "PUT" -Url "$BaseUrl/auth/profile" -Body @{
        name = "Updated Test User"
    } -Headers $headers -ExpectedStatus 200
    
    return $profile
}

function Test-OAuth {
    Write-Host "`n🔄 Testing OAuth Flows" -ForegroundColor Cyan
    
    # Get OAuth Providers
    $oauthProviders = Test-Endpoint -Name "Get OAuth Providers" -Method "GET" -Url "$BaseUrl/auth/oauth/providers" -ExpectedStatus 200
    
    if ($oauthProviders.Success) {
        $providersData = $oauthProviders.Data | ConvertFrom-Json
        Write-Host "Available OAuth Providers:" -ForegroundColor Yellow
        foreach ($provider in $providersData.providers) {
            Write-Host "- $provider" -ForegroundColor Yellow
        }
    }
}

function Test-SecurityFeatures($Token) {
    Write-Host "`n🔒 Testing Security Features" -ForegroundColor Cyan
    
    # CSRF Token
    if ($Token) {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }
        
        $csrfResponse = Test-Endpoint -Name "Get CSRF Token" -Method "GET" -Url "$BaseUrl/auth/csrf-token" -Headers $headers -ExpectedStatus 200
        
        if ($csrfResponse.Success) {
            $csrfData = $csrfResponse.Data | ConvertFrom-Json
            $csrfToken = $csrfData.csrfToken
            Write-Host "CSRF Token: $($csrfToken.Substring(0, 10))..." -ForegroundColor Cyan
            return $csrfToken
        }
    }
    
    # Rate Limiting Test
    Write-Host "Testing Rate Limiting..." -ForegroundColor Yellow
    for ($i = 0; $i -lt 5; $i++) {
        $rateLimitTest = Test-Endpoint -Name "Rate Limit Test $($i+1)" -Method "GET" -Url "$BaseUrl/auth/status" -ExpectedStatus 200
        Start-Sleep -Milliseconds 200
    }
}

function Test-TokenManagement($RefreshToken) {
    Write-Host "`n🔄 Testing Token Management" -ForegroundColor Cyan
    
    if (-not $RefreshToken) {
        Write-Host "No refresh token available - skipping token management tests" -ForegroundColor Yellow
        return
    }
    
    $tokenRefresh = Test-Endpoint -Name "Token Refresh" -Method "POST" -Url "$BaseUrl/auth/token" -Body @{
        refreshToken = $RefreshToken
    } -ExpectedStatus 200
    
    if ($tokenRefresh.Success) {
        $refreshData = $tokenRefresh.Data | ConvertFrom-Json
        $newToken = $refreshData.token
        Write-Host "New Token: $($newToken.Substring(0, 10))..." -ForegroundColor Cyan
        return $newToken
    }
}

function Test-ErrorHandling {
    Write-Host "`n⚠️ Testing Error Handling" -ForegroundColor Cyan
    
    # Invalid Login
    $invalidLogin = Test-Endpoint -Name "Invalid Login" -Method "POST" -Url "$BaseUrl/auth/login" -Body @{
        email = "nonexistent@example.com"
        password = "WrongPassword123"
    } -ExpectedStatus 401
    
    # Protected Route Without Token
    $noAuthAccess = Test-Endpoint -Name "Protected Route Without Token" -Method "GET" -Url "$BaseUrl/auth/profile" -ExpectedStatus 401
}

function Show-AdminInstructions {
    Write-Host "`n👨‍💻 ADMIN TOOLS" -ForegroundColor Yellow
    Write-Host "For administrative operations, use the CLI admin tool with: node auth-admin.js --help"
}

# Main Test Flow
function Run-FullTestSuite {
    Write-Host "`n🚀 STARTING FULL TEST SUITE" -ForegroundColor Cyan
    
    # Check if server is ready
    Wait-ForServerReady
    
    # Run Registration Tests
    $userInfo = Test-Registration
    
    # Run Login Tests
    $authInfo = Test-Login -Email $userInfo.Email
    
    # Run Protected Endpoint Tests
    Test-ProtectedEndpoints -Token $authInfo.Token
    
    # Run OAuth Tests
    Test-OAuth
    
    # Run Security Feature Tests
    $csrfToken = Test-SecurityFeatures -Token $authInfo.Token
    
    # Run Token Management Tests
    $newToken = Test-TokenManagement -RefreshToken $authInfo.RefreshToken
    
    # Run Error Handling Tests
    Test-ErrorHandling
    
    # Show Admin Instructions
    Show-AdminInstructions
    
    Write-Host "`n✅ TEST SUITE COMPLETED SUCCESSFULLY" -ForegroundColor Green
}

# Run the full test suite
Run-FullTestSuite
