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

Write-Host "Waiting for server to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host "`nPHASE 1: BASIC SERVER FUNCTIONALITY" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$healthCheck = Test-Endpoint "Health Check" "GET" "$BaseUrl/health"
$indexCheck = Test-Endpoint "Index Endpoint" "GET" "$BaseUrl/"

Write-Host "`nPHASE 2: USER REGISTRATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$registerResult = Test-Endpoint "User Registration" "POST" "$BaseUrl/auth/register" $TestUser 201
$duplicateResult = Test-Endpoint "Duplicate Registration (Should Fail)" "POST" "$BaseUrl/auth/register" $TestUser 400

Write-Host "`nPHASE 3: USER LOGIN" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$loginData = @{
    email = $TestUser.email
    password = $TestUser.password
}

$loginResult = Test-Endpoint "User Login" "POST" "$BaseUrl/auth/login" $loginData 200
$accessToken = ""
if ($loginResult.Success) {
    $loginResponseData = $loginResult.Data | ConvertFrom-Json
    $accessToken = $loginResponseData.accessToken
    Write-Host "   Access Token: $($accessToken.Substring(0, 20))..." -ForegroundColor Gray
}

$wrongLoginData = @{
    email = $TestUser.email
    password = "WrongPassword123!"
}
$wrongLogin = Test-Endpoint "Login with Wrong Password" "POST" "$BaseUrl/auth/login" $wrongLoginData 401

Write-Host "`nPHASE 4: PROTECTED ROUTES" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$noTokenResult = Test-Endpoint "Profile Access (No Token)" "GET" "$BaseUrl/auth/profile" $null @{} 401

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $profileResult = Test-Endpoint "Profile Access (Valid Token)" "GET" "$BaseUrl/auth/profile" $null $authHeaders 200
}

Write-Host "`nPHASE 5: MULTI-FACTOR AUTHENTICATION" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $mfaSetupResult = Test-Endpoint "MFA Setup" "POST" "$BaseUrl/auth/mfa/setup" $null $authHeaders 200
    if ($mfaSetupResult.Success) {
        $mfaData = $mfaSetupResult.Data | ConvertFrom-Json
        Write-Host "   MFA Secret Generated: YES" -ForegroundColor Gray
    }
}

Write-Host "`nPHASE 6: ADMIN FUNCTIONALITY" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $adminUsersResult = Test-Endpoint "List Users (Non-Admin Should Fail)" "GET" "$BaseUrl/auth/admin/users" $null $authHeaders 403
}

Write-Host "`nPHASE 7: SECURITY FEATURES" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

try {
    $securityResponse = Invoke-WebRequest -Uri "$BaseUrl/" -Method GET
    $securityHeaders = @(
        "X-Content-Type-Options",
        "X-Frame-Options", 
        "X-XSS-Protection"
    )
    
    foreach ($header in $securityHeaders) {
        if ($securityResponse.Headers[$header]) {
            Write-Host "PASS - Security Header: $header" -ForegroundColor Green
        } else {
            Write-Host "MISSING - Security Header: $header" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "ERROR - Security Headers Check: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPHASE 8: INPUT VALIDATION" -ForegroundColor Blue
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

Write-Host "`nPHASE 9: OAUTH INTERFACE" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

$oauthPageResult = Test-Endpoint "OAuth Test Page" "GET" "$BaseUrl/oauth-test.html" $null @{} 200

Write-Host "`nPHASE 10: LOGOUT" -ForegroundColor Blue
Write-Host ("-" * 50) -ForegroundColor Blue

if ($accessToken) {
    $authHeaders = @{ "Authorization" = "Bearer $accessToken" }
    $logoutResult = Test-Endpoint "User Logout" "POST" "$BaseUrl/auth/logout" $null $authHeaders 200
    
    Start-Sleep -Seconds 1
    $postLogoutResult = Test-Endpoint "Profile Access After Logout" "GET" "$BaseUrl/auth/profile" $null $authHeaders 401
}

Write-Host "`nCOMPREHENSIVE TESTING COMPLETED!" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "All core authentication features have been tested" -ForegroundColor Green
Write-Host "Test OAuth flows manually at: http://localhost:8080/oauth-test.html" -ForegroundColor Yellow
