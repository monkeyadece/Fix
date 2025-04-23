$directories = @(
    "$env:USERPROFILE\AppData\Local\Bloxstrap\Roblox",
    "$env:USERPROFILE\AppData\Local\Bloxstrap\Logs",
    "$env:USERPROFILE\AppData\Local\Bloxstrap\Downloads",
    "$env:USERPROFILE\AppData\Local\Roblox\OTAPatchBackups",
    "$env:USERPROFILE\AppData\Local\Roblox\logs",
    "$env:USERPROFILE\AppData\Local\Roblox\LocalStorage",
    "$env:USERPROFILE\AppData\Local\Fishstrap\Versions",
    "$env:USERPROFILE\AppData\Local\Fishstrap\Logs",
    "$env:USERPROFILE\AppData\Local\Fishstrap\Downloads"
)

$tempDirs = @(
    $env:TEMP,                                       
    $env:TMP,                                         
    "C:\Windows\Temp",                               
    "C:\Windows\Prefetch",                            
    "C:\Windows\SoftwareDistribution\Download",      
    "C:\Windows\SoftwareDistribution\DeliveryOptimization", 
    "C:\ProgramData\Microsoft\Windows\WER",           
    "C:\Windows\Logs",                               
    "$env:LocalAppData\Microsoft\Windows\INetCache",  
    "$env:LocalAppData\Microsoft\Edge\User Data\Default\Cache", 
    "$env:LocalAppData\Google\Chrome\User Data\Default\Cache"  
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        try {
            Remove-Item -Path $dir -Recurse -Force
            Write-Host "Deleted: $dir" -ForegroundColor Green
        } catch {
            Write-Host "Failed to delete: $dir" -ForegroundColor Red
        }
    } else {
        Write-Host "Directory not found: $dir" -ForegroundColor Yellow
    }
}

function Delete-TempFiles {
    param (
        [string]$Path
    )
    Write-Host "Cleaning: $Path" -ForegroundColor Cyan

    if (Test-Path -Path $Path) {
        try {
            Get-ChildItem -Path $Path -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

            Get-ChildItem -Path $Path -Directory -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

            Write-Host "Successfully cleaned: $Path" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to clean: $Path. Error: $_"
        }
    } else {
        Write-Warning "Path does not exist: $Path"
    }
}

function Clear-RecycleBin-Safely {
    Write-Host "Cleaning Recycle Bin..." -ForegroundColor Cyan
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Host "Recycle Bin cleaned successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to clean Recycle Bin. Error: $_"
    }
}

function Flush-DNSCache {
    Write-Host "Flushing DNS cache..." -ForegroundColor Cyan
    try {
        ipconfig /flushdns
        Write-Host "DNS cache flushed successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to flush DNS cache. Error: $_"
    }
}

function Execute-NetworkCommands {
    Write-Host "Executing network reset commands..." -ForegroundColor Cyan
    try {
        Write-Host "Flushing DNS..." -ForegroundColor Cyan
        ipconfig /flushdns

        Write-Host "Registering DNS..." -ForegroundColor Cyan
        ipconfig /registerdns

        Write-Host "Releasing IP..." -ForegroundColor Cyan
        ipconfig /release

        Write-Host "Renewing IP..." -ForegroundColor Cyan
        ipconfig /renew

        Write-Host "Resetting Winsock..." -ForegroundColor Cyan
        netsh winsock reset
        Write-Host "Network commands executed successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Error executing network commands."
    }
}

foreach ($dir in $tempDirs) {
    Delete-TempFiles -Path $dir
}

Clear-RecycleBin-Safely
Flush-DNSCache
Execute-NetworkCommands

Write-Host "Finished cleaning and network reset. Your system is now ready for Roblox." -ForegroundColor Red
