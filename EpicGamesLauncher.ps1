$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

[console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Checking for updates (Summer)..." -ForegroundColor Cyan

$apiUrl = "https://api.github.com/repos/GRILLYje/Fishing_Summer_Public/releases/latest"

try {
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Method Get
    
    $version = $releaseInfo.tag_name
    $publishedAt = [datetime]$releaseInfo.published_at
    $localTime = $publishedAt.ToLocalTime().ToString("dd/MM/yyyy HH:mm:ss")

    $downloadUrl = ($releaseInfo.assets | Where-Object { $_.name -eq "EpicGamesLauncher.exe" }).browser_download_url
    $templatesZipUrl = ($releaseInfo.assets | Where-Object { $_.name -eq "templates.zip" }).browser_download_url

    if (-not $downloadUrl) {
        Write-Host "Error: Could not find 'EpicGamesLauncher.exe' in the latest release!" -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        Exit
    }

    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "New Update Available!" -ForegroundColor Green
    Write-Host "Version: $version" -ForegroundColor White
    Write-Host "Date & Time: $localTime" -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "Downloading files... Please wait." -ForegroundColor White

} catch {
    Write-Host "Failed to fetch update info from GitHub." -ForegroundColor Red
    Write-Host "API Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    Exit
}

$baseTemp = [System.IO.Path]::GetTempPath()
$folderPath = Join-Path -Path $baseTemp -ChildPath "Summer"

if (-not (Test-Path -LiteralPath $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
}

$tempPath = Join-Path -Path $folderPath -ChildPath "EpicGamesLauncher.exe"
$tempZipPath = Join-Path -Path $folderPath -ChildPath "templates.zip"

try {
    $processName = [System.IO.Path]::GetFileNameWithoutExtension($tempPath)
    Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 500
} catch {}

try {
    if (Test-Path -LiteralPath $tempPath) {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction Stop
    }
} catch {
    Write-Host "Error: Cannot delete old file. Please make sure the bot is closed." -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    Exit
}

try {
    $webClient = New-Object System.Net.WebClient
    
    Write-Host "Downloading EpicGamesLauncher.exe..." -ForegroundColor White
    $webClient.DownloadFile($downloadUrl, $tempPath)
    
    if ($templatesZipUrl) {
        Write-Host "Downloading templates.zip..." -ForegroundColor White
        $webClient.DownloadFile($templatesZipUrl, $tempZipPath)
        
        Write-Host "Extracting templates..." -ForegroundColor White
        Expand-Archive -Path $tempZipPath -DestinationPath $folderPath -Force
        Remove-Item -LiteralPath $tempZipPath -Force
    } else {
        Write-Warning "Warning: 'templates.zip' not found in this release. Skipping templates download."
    }

    Write-Host "Download & Extraction Complete!" -ForegroundColor Green
} catch {
    Write-Host "Error downloading or extracting files." -ForegroundColor Red
    Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    Exit
}

try {
    $historyPath = (Get-PSReadLineOption).HistorySavePath
    if (Test-Path -LiteralPath $historyPath) { Clear-Content -LiteralPath $historyPath -Force }
    Clear-History
} catch {}

Write-Host "Launching Summer..." -ForegroundColor Green

# เช็คว่าไฟล์ exe มีอยู่จริงไหมก่อนรัน (กันแอนตี้ไวรัสลบ)
if (Test-Path -LiteralPath $tempPath) {
    Start-Process -FilePath $tempPath -WorkingDirectory $folderPath
    Start-Sleep -Seconds 2 # หน่วงเวลาให้โปรแกรมเด้งขึ้นมาก่อน PowerShell ปิด
} else {
    Write-Host "Error: The file was downloaded but disappeared! Windows Defender might have deleted it." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}
