$USER = "admin"
$PASS = "12985654"
$IP = "192.168.60.1"

Write-Host "=== Тест авторизации Keenetic RCI ($IP) ==="

# 1. Получение challenge и cookies
Write-Host "Step 1: Get challenge and session (cookies)..."
$cookie_file = "cookies.txt"
if (Test-Path $cookie_file) { Remove-Item $cookie_file }

$resp = curl.exe -s -i -c $cookie_file "http://$IP/auth"
$realm = ($resp | Select-String "X-NDM-Realm: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
$challenge = ($resp | Select-String "X-NDM-Challenge: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() })

if (-not $challenge) {
    Write-Host "Error: Challenge not found in headers." -ForegroundColor Red
    exit 1
}

Write-Host "  Realm: $realm"
Write-Host "  Challenge: $challenge"

# 2. Вычисление MD5
$md5 = [System.Security.Cryptography.MD5]::Create()
$h1_str = "${USER}:${realm}:${PASS}"
$h1_bytes = [System.Text.Encoding]::UTF8.GetBytes($h1_str)
$h1 = [System.BitConverter]::ToString($md5.ComputeHash($h1_bytes)).Replace("-", "").ToLower()

# 5. Перебор вариантов хеширования
Write-Host "Step 2: Brute-forcing Hash variants..."
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$sha512 = [System.Security.Cryptography.SHA512]::Create()

$variants = @{
    "SHA256(challenge + MD5)" = [System.BitConverter]::ToString($sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("${challenge}${h1}"))).Replace("-", "").ToLower()
    "SHA256(MD5 + challenge)" = [System.BitConverter]::ToString($sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("${h1}${challenge}"))).Replace("-", "").ToLower()
    "SHA512(challenge + MD5)" = [System.BitConverter]::ToString($sha512.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("${challenge}${h1}"))).Replace("-", "").ToLower()
    "SHA512(MD5 + challenge)" = [System.BitConverter]::ToString($sha512.ComputeHash([System.Text.Encoding]::UTF8.GetBytes("${h1}${challenge}"))).Replace("-", "").ToLower()
}

$rci_success = $false

foreach ($v_name in $variants.Keys) {
    $v_hash = $variants[$v_name]
    Write-Host "`n--- Testing Variant: $v_name ($v_hash) ---"
    
    $json_payload = @{
        login = $USER
        password = $v_hash
    } | ConvertTo-Json -Compress
    
    $payload_file = "payload.json"
    $json_payload | Out-File -FilePath $payload_file -Encoding utf8
    
    Write-Host "  Sending JSON POST to /auth..."
    # Используем -b и -c для работы с куками, -d @file для JSON
    $auth_resp = curl.exe -s -i -b $cookie_file -c $cookie_file -X POST -H "Content-Type: application/json" -d "@$payload_file" "http://$IP/auth"
    $status = ($auth_resp | Select-String "HTTP/")
    Write-Host "  Status: $status"
    
    if ($status -match "200 OK") {
        Write-Host "  SUCCESS! Auth accepted via JSON POST." -ForegroundColor Green
        Write-Host "  Testing RCI access..."
        $rci = curl.exe -s -b $cookie_file "http://$IP/rci/system/hostname"
        Write-Host "  RCI Response: $rci"
        if ($rci -match "hostname") { 
            $rci_success = $true
            break 
        }
    } else {
        Write-Host "  Failed with status: $status" -ForegroundColor Yellow
        $auth_resp | Select-String "{" | ForEach-Object { Write-Host "  Server response: $_" }
    }
}

if ($rci_success) {
    Write-Host "`nFINAL SUCCESS!" -ForegroundColor Green
} else {
    Write-Host "`nFINAL FAILURE." -ForegroundColor Red
    exit 1
}
