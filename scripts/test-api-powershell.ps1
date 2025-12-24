Write-Host "=== TESTING ESHELF API ===" -ForegroundColor Cyan

# Base URL
$baseUrl = "http://localhost:3000"

# Test 1: Health Check
Write-Host "`n1. Testing Health Check..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "✓ Health Check OK" -ForegroundColor Green
    $response | ConvertTo-Json
} catch {
    Write-Host "✗ Health Check Failed: $_" -ForegroundColor Red
}

# Test 2: Login Admin
Write-Host "`n2. Testing Admin Login..." -ForegroundColor Yellow
try {
    $loginBody = @{
        email = "admin@eshelf.com"
        password = "Admin123!"
    } | ConvertTo-Json

    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
        -Method Post `
        -Body $loginBody `
        -ContentType "application/json"
    
    Write-Host "✓ Login Successful" -ForegroundColor Green
    $token = $loginResponse.data.accessToken
    Write-Host "Access Token: $($token.Substring(0,50))..." -ForegroundColor Gray
} catch {
    Write-Host "✗ Login Failed: $_" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}

# Test 3: Get Books
Write-Host "`n3. Testing Get Books..." -ForegroundColor Yellow
try {
    $booksResponse = Invoke-RestMethod -Uri "$baseUrl/api/books?page=1&limit=5" -Method Get
    Write-Host "✓ Books Retrieved: $($booksResponse.data.books.Count) books" -ForegroundColor Green
    $booksResponse.data.books | Select-Object -First 2 -Property title, authors | ConvertTo-Json
} catch {
    Write-Host "✗ Get Books Failed: $_" -ForegroundColor Red
}

# Test 4: Get Users (Admin)
Write-Host "`n4. Testing Get Users (Admin)..." -ForegroundColor Yellow
try {
    $headers = @{
        Authorization = "Bearer $token"
    }
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/api/users?page=1&limit=10" `
        -Method Get `
        -Headers $headers
    
    Write-Host "✓ Users Retrieved: $($usersResponse.data.pagination.total) users" -ForegroundColor Green
    $usersResponse.data.users | Select-Object -Property email, username, role | ConvertTo-Json
} catch {
    Write-Host "✗ Get Users Failed: $_" -ForegroundColor Red
}

# Test 5: Get Genres
Write-Host "`n5. Testing Get Genres..." -ForegroundColor Yellow
try {
    $genresResponse = Invoke-RestMethod -Uri "$baseUrl/api/genres" -Method Get
    Write-Host "✓ Genres Retrieved: $($genresResponse.data.Count) genres" -ForegroundColor Green
    $genresResponse.data | Select-Object -First 5 -Property name | ConvertTo-Json
} catch {
    Write-Host "✗ Get Genres Failed: $_" -ForegroundColor Red
}

# Test 6: Add Favorite (User)
Write-Host "`n6. Testing Add Favorite..." -ForegroundColor Yellow
try {
    # Get first book ISBN
    $firstBook = $booksResponse.data.books[0]
    $bookId = if ($firstBook.id) { $firstBook.id } else { $firstBook.isbn }
    
    $favResponse = Invoke-RestMethod -Uri "$baseUrl/api/favorites/$bookId" `
        -Method Post `
        -Headers $headers
    
    Write-Host "✓ Favorite Added: $($favResponse.message)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "⚠ Already in favorites (OK)" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Add Favorite Failed: $_" -ForegroundColor Red
    }
}

# Test 7: Get Favorites
Write-Host "`n7. Testing Get Favorites..." -ForegroundColor Yellow
try {
    $favListResponse = Invoke-RestMethod -Uri "$baseUrl/api/favorites" `
        -Method Get `
        -Headers $headers
    
    Write-Host "✓ Favorites Retrieved: $($favListResponse.data.Count) items" -ForegroundColor Green
} catch {
    Write-Host "✗ Get Favorites Failed: $_" -ForegroundColor Red
}

Write-Host "`n=== TESTING COMPLETE ===" -ForegroundColor Cyan
