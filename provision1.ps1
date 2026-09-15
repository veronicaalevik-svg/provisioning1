# ==========================================
# Konfiguration & Variabler
# ==========================================
# Hämtar API-nyckel från miljövariabel om den finns, annars fallback till din nyckel
$API_KEY = $env:API_KEY
if ([string]::IsNullOrEmpty($API_KEY)) {
    $API_KEY = "st-veronica-ramirez-levik-b4d5d9" 
}

$URL  = "https://provision.systementor.se/api/provision/advanced"
$FILE = "users.json"

# ==========================================
# Datainläsning & Filtrering
# ==========================================
if (-not (Test-Path $FILE)) {
    Write-Error "Hittade inte filen $FILE"
    exit
}

$jsonContent = Get-Content -Path $FILE -Raw
$users       = $jsonContent | ConvertFrom-Json

# VG-krav: Villkorlig provisionering (endast aktiva användare)
$activeUsers = $users | Where-Object { $_.IsActive -eq $true }

Write-Host "Hittade $($activeUsers.Count) aktiva användare att provisionera." -ForegroundColor Green

# ==========================================
# Datamappning & Transformering
# ==========================================
$payloadList = foreach ($u in $activeUsers) {
    # Hantera svenska tecken i e-post
    $cleanFirstName = $u.FirstName.ToLower() -replace 'å|ä','a' -replace 'ö','o'
    $cleanLastName  = $u.LastName.ToLower()  -replace 'å|ä','a' -replace 'ö','o'
    
    [PSCustomObject]@{
        name       = "$($u.FirstName) $($u.LastName)"
        department = $u.Department
        isActive   = $u.IsActive
        email      = "$cleanFirstName.$cleanLastName@tssab.com"
    }
}

# Omvandla objektlistan till JSON
$body = $payloadList | ConvertTo-Json -Depth 5

# ==========================================
# HTTP-Headers & API-anrop
# ==========================================
$headers = @{
    "Authorization"       = "Bearer $API_KEY"
    "X-Integration-Level" = "Advanced"
    "Content-Type"        = "application/json; charset=utf-8"
}

try {
    $response = Invoke-RestMethod -Uri $URL -Method Post -Headers $headers -Body $body
    Write-Host "Provisionering lyckades!" -ForegroundColor Green
    $response
}
catch {
    Write-Host "Ett fel uppstod vid anropet: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        # Skriv ut detaljerat svar från API:et om det finns (t.ex. 401 eller 400 fel)
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $errBody = $streamReader.ReadToEnd()
        Write-Host "API-svar: $errBody" -ForegroundColor Yellow
    }
}
