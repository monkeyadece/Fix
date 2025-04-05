$Host.UI.RawUI.WindowTitle = "Vector Bootstrapper - Divine Reselling | E"

function Write-Header {
    param ([string]$Title)
    Write-Host "`n" + ("=" * 80) -ForegroundColor DarkRed
    Write-Host " $Title" -ForegroundColor Red
    Write-Host ("=" * 80) + "`n" -ForegroundColor DarkRed
}
function Write-Info { param ([string]$Message); Write-Host "[INFO] $Message" -ForegroundColor Red }
function Write-Warning { param ([string]$Message); Write-Host "[WARNING] $Message" -ForegroundColor DarkYellow }
function Write-Error { param ([string]$Message); Write-Host "[ERROR] $Message" -ForegroundColor DarkRed }

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) {
    Write-Header "Admin Required"
    Write-Warning "Run this as administrator!"
    Write-Host "Press any key to exit..." -ForegroundColor DarkRed
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

function Test-Windows11_24H2 {
    $osInfo = Get-ComputerInfo -Property "OsName", "OsVersion"
    return ($osInfo.OsName -like "*Windows 11*" -and $osInfo.OsVersion -match "10\.0\.26[0-9]{3}")
}
if (Test-Windows11_24H2) {
    Write-Header "Unsupported Windows Version"
    Write-Error "You are on Windows 11 24H2. Please downgrade your Windows. Vector does not support 24H2."
    Write-Host "Press any key to exit..." -ForegroundColor DarkRed
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Header "Antivirus Warning"
Write-Warning "Make sure to turn off your anti-virus or any other third-party ones that you may not know of."
Write-Warning "You have to turn it off before using this fixer and Vector."
Write-Warning "Please DO NOT load Vector while playing kernal anti-cheat games | EAC, VAC, ETC"
Write-Warning "Message from: Divine Rselling."

Write-Header "Anti-Virus Disabler [Sordum]"
Write-Host "Do you want to permanently disable your anti-virus? (Y/N): " -ForegroundColor Green -NoNewline
$disableAVChoice = Read-Host
if ($disableAVChoice -eq 'Y' -or $disableAVChoice -eq 'y') {
    Write-Info "Downloading and extracting Sordum Defender Control..."
    $url = "https://github.com/monkeyadece/Fix/raw/refs/heads/main/Sordum-Defender.zip"
    $zip = "$env:TEMP\Sordum-Defender.zip"
    $out = "$env:TEMP\Sordum-Defender"

    try {
        Invoke-WebRequest -Uri $url -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $out -Force
        $exe = "$out\dControl.exe"
        if (Test-Path $exe) {
            Write-Info "Launching Sordum Defender Control..."
            Start-Process -FilePath $exe
        } else {
            Write-Error "dControl.exe not found."
        }
    } catch {
        Write-Error "Failed to fetch or run Sordum. $_"
    } finally {
        if (Test-Path $zip) { Remove-Item -Path $zip -Force }
    }
} else {
    Write-Info "Skipping AV disabler."
}

Write-Host "Press any key to continue..." -ForegroundColor DarkRed
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

do {
    Write-Header "Vector Bootstrapper - Divine Reselling | E"
    Write-Host "[+] (1) Download loader.exe [Main loader for Vector]" -ForegroundColor Red
    Write-Host "[+] (2) Download Vector-fixer.exe [Fix all your vector issues]" -ForegroundColor Red
    Write-Host "[+] (3) Close Bootstrapper" -ForegroundColor DarkRed
    Write-Host "Enter your choice (1, 2, or 3): " -ForegroundColor Red -NoNewline

    $choice = Read-Host
    if ($choice -eq "1" -or $choice -eq "2") {
        $fileName = if ($choice -eq "1") { "loader.exe" } else { "Vector-fixer.exe" }
        $url = if ($choice -eq "1") { "https://pub-ec4e1187d0204642b6f74f7abb41177c.r2.dev/loader.exe" } else { "https://github.com/monkeyadece/Fix/raw/refs/heads/main/Vector-fixer.exe" }
        
        Write-Host "[INFO] You are about to download $fileName."
        Write-Host "Do you want to continue? (Y/N): " -ForegroundColor Green -NoNewline
        $confirmDownload = Read-Host
        if ($confirmDownload -eq 'Y' -or $confirmDownload -eq 'y') {
            Write-Host "[INFO] Downloading $fileName..."
            $dest = Join-Path -Path (Get-Location) -ChildPath $fileName

            try {
                Write-Host "[INFO] Download starting at $dest"

                $startTime = Get-Date
                Start-BitsTransfer -Source $url -Destination $dest

                if (-Not (Test-Path $dest)) {
                    throw "Download failed. File not found."
                }

                $fileSize = (Get-Item $dest).Length
                if ($fileSize -lt 10000) {
                    throw "Downloaded file is too small or invalid."
                }

                $elapsedTime = (Get-Date) - $startTime
                $speed = $fileSize / $elapsedTime.TotalSeconds / 1MB
                Write-Host "[INFO] Download speed: $([math]::round($speed, 2)) MB/s"
                Write-Host "[INFO] File downloaded successfully."
                Write-Host "Downloaded to: $dest"

                Write-Host "Do you want to run the downloaded file? (Y/N): " -ForegroundColor Green -NoNewline
                $confirmRun = Read-Host
                if ($confirmRun -eq 'Y' -or $confirmRun -eq 'y') {
                    Write-Host "[INFO] Running $fileName..."
                    Start-Process -FilePath $dest
                } else {
                    Write-Host "[INFO] Skipping file execution."
                }

            } catch {
                Write-Error "Failed to download or run $fileName. $($_.Exception.Message)"
            }
        } else {
            Write-Host "[INFO] Download canceled."
        }
    } elseif ($choice -eq "3") {
        Write-Host "[INFO] Exiting..."
        break
    } else {
        Write-Host "[ERROR] Invalid choice. Please select option 1, 2, or 3." -ForegroundColor DarkRed
    }
} while ($choice -ne "3")

Write-Host "Press any key to exit..." -ForegroundColor DarkRed
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
