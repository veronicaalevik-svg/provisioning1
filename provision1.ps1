$API_KEY = "st-veronica-ramirez-levik-b4d5d9"
$URL = "https://provision.systementor.se/api/provision/advanced"
$FILE = "users.json"

# Läs in JSON-filen
$jsonContent = Get-Content -Path $FILE -Raw
$users = $jsonContent | ConvertFrom-Json

# VG-krav: Behåll endast aktiva användare
$activeUsers = $users | Where-Object { $_.IsActive -eq $true }

Write-Host "Hittade $($activeUsers.Count) aktiva användare att provisionera."

# Mappa om till den struktur API:et förväntar sig (liten startbokstav i fälten)
$payloadList = foreach ($u in $activeUsers) {
    [PSCustomObject]@{
        name       = "$($u.FirstName) $($u.LastName)"
        department = $u.Department
        isActive   = $u.IsActive
        email      = "$($u.FirstName.ToLower()).$($u.LastName.ToLower())@tssab.com"
    }
}

# Omvandla listan till JSON
Atoms: $body = $payloadList | ConvertTo-Json -Depth 5

# Förbered headers (inkluderar VG-kravet X-Integration-Level och auktorisering)
$headers = @{
    "Authorization"      = "Bearer $API_KEY"
    "X-Integration-Level" = "Advanced"
    "Content-Type"       = "application/json"
}

# Skicka anropet i ett och samma paket
try {
    $response = Invoke-RestMethod -Uri $URL -Method Post -Headers $headers -Body $body
    $response
}
catch {
    Write-Host "Ett fel uppstod vid anropet: $_" -ForegroundColor Red
}
