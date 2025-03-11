$Host.UI.RawUI.WindowTitle = "Vector Fixer - Divine Reselling | E"

function Write-Header {
    param (
        [string]$Title
    )
    Write-Host "`n" + ("=" * 80) -ForegroundColor DarkRed
    Write-Host " $Title" -ForegroundColor Red
    Write-Host ("=" * 80) + "`n" -ForegroundColor DarkRed
}

function Write-Info {
    param (
        [string]$Message
    )
    Write-Host "[INFO] $Message" -ForegroundColor Red
}

function Write-Warning {
    param (
        [string]$Message
    )
    Write-Host "[WARNING] $Message" -ForegroundColor DarkYellow
}

function Write-Error {
    param (
        [string]$Message
    )
    Write-Host "[ERROR] $Message" -ForegroundColor DarkRed
}

function Test-Windows11_24H2 {
    $osInfo = Get-ComputerInfo -Property "OsName", "OsVersion"
    if ($osInfo.OsName -like "*Windows 11*" -and $osInfo.OsVersion -match "10\.0\.26[0-9]{3}") {
        return $true
    }
    return $false
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
Write-Host "Press any key to continue..." -ForegroundColor DarkRed
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

function Clear-TempFiles {
    Write-Info "Deleting TEMP files, please wait..."
    $tempPath = [System.IO.Path]::GetTempPath()
    try {
        Get-ChildItem -Path $tempPath -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Info "TEMP files have been deleted (some files may still be in use and were not deleted)."
    } catch {
        Write-Error "Failed to delete TEMP files. Error: $_"
    }
}

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Header "Administrator Privileges Required"
    Write-Warning "Please rerun this script as an administrator!"
    Write-Info "Right-click on the file, then select 'Run as Administrator', and then run this script again."
    Write-Host "Press any key to exit..." -ForegroundColor DarkRed
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Clear-TempFiles

function Is-DirectXInstalled {
    $directxDllPath = "$env:SystemRoot\System32\d3dx9_43.dll"
    return (Test-Path $directxDllPath)
}

function Is-SoftwareInstalled($displayNames) {
    foreach ($name in $displayNames) {
        $installed = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*$name*" }
        if ($installed) {
            return $true
        }
    }
    return $false
}

function Install-Software {
    param (
        [string]$Name,
        [string]$Url
    )
    Write-Info "Installing $Name..."
    $installerPath = "$env:TEMP\$($Name.Replace(' ', '_')).exe"
    try {
        Invoke-WebRequest -Uri $Url -OutFile $installerPath
        Start-Process -FilePath $installerPath -Wait
        Write-Info "$Name has been installed."
    } catch {
        Write-Error "Failed to install $Name. Error: $_"
    } finally {
        if (Test-Path $installerPath) {
            Remove-Item $installerPath
        }
    }
}

function Set-VulnerableDriverBlocklistEnable {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config"
    $regKey = "VulnerableDriverBlocklistEnable"

    try {
        if (-not (Test-Path $regPath)) {
            Write-Info "Creating registry path: $regPath"
            New-Item -Path $regPath -Force | Out-Null
        }

        $currentValue = Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue

        if (-not $currentValue -or $currentValue.$regKey -ne 0) {
            Write-Info "Setting registry key '$regKey' to 0..."
            Set-ItemProperty -Path $regPath -Name $regKey -Value 0 -ErrorAction Stop
            return $true
        } else {
            Write-Info "Registry key '$regKey' is already set to 0."
        }
    } catch {
        Write-Error "Failed to modify the registry key '$regKey'. Error: $_"
        return $false
    }

    return $false
}

function Get-CoreIsolationStatus {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    $regKey = "Enabled"

    try {
        $coreIsolationStatus = Get-ItemProperty -Path $regPath -Name $regKey -ErrorAction SilentlyContinue
        if ($coreIsolationStatus -and $coreIsolationStatus.$regKey -eq 1) {
            return "Enabled"
        } else {
            return "Disabled"
        }
    } catch {
        Write-Error "Failed to retrieve Core Isolation status. Error: $_"
        return "Unknown"
    }
}

function Disable-CoreIsolation {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    $regKey = "Enabled"

    try {
        if (-not (Test-Path $regPath)) {
            Write-Info "Creating registry path: $regPath"
            New-Item -Path $regPath -Force | Out-Null
        }

        Write-Info "Disabling Core Isolation (Memory Integrity)..."
        Set-ItemProperty -Path $regPath -Name $regKey -Value 0 -ErrorAction Stop
        Write-Info "Core Isolation has been disabled. A system restart is required for the changes to take effect."
        return $true
    } catch {
        Write-Error "Failed to disable Core Isolation. Error: $_"
        return $false
    }
}

$softwareList = @(
    @{ 
        Names = @("Microsoft Visual C++ 2015-2022 Redistributable (x64)", "Microsoft Visual C++ 2015 Redistributable (x64)", "Microsoft Visual C++ 2017 Redistributable (x64)", "Microsoft Visual C++ 2019 Redistributable (x64)"); 
        URL = "https://aka.ms/vs/17/release/vc_redist.x64.exe" 
    },
    @{ 
        Names = @("Microsoft Visual C++ 2015-2022 Redistributable (x86)", "Microsoft Visual C++ 2015 Redistributable (x86)", "Microsoft Visual C++ 2017 Redistributable (x86)", "Microsoft Visual C++ 2019 Redistributable (x86)"); 
        URL = "https://aka.ms/vs/17/release/vc_redist.x86.exe" 
    },
    @{ 
        Names = @("DirectX End-User Runtime Web Installer", "DirectX End-User Runtime"); 
        URL = "https://download.microsoft.com/download/1/7/1/1718ccc4-6315-4d8e-9543-8e28a4e18c4c/dxwebsetup.exe" 
    }
)

Write-Header "Vector Fixer - Divine Reselling | E"

foreach ($software in $softwareList) {
    $displayNames = $software.Names
    $url = $software.URL

    if ($displayNames[0] -like "*DirectX*") {
        if (Is-DirectXInstalled) {
            Write-Info "$($displayNames[0]) is already installed."
        } else {
            Write-Warning "$($displayNames[0]) is not installed."
            Install-Software -Name $displayNames[0] -Url $url
        }
    } else {
        if (Is-SoftwareInstalled $displayNames) {
            Write-Info "$($displayNames[0]) is installed."
            $choice = Read-Host "Do you want to (1) Repair or (2) Do nothing? Enter 1 or 2"
            if ($choice -eq 1) {
                Write-Info "Repairing $($displayNames[0])..."
            } elseif ($choice -eq 2) {
                Write-Info "Skipping $($displayNames[0])."
            } else {
                Write-Warning "Invalid choice. Skipping $($displayNames[0])."
            }
        } else {
            Write-Warning "$($displayNames[0]) is not installed."
            Install-Software -Name $displayNames[0] -Url $url
        }
    }
}

Write-Header "Registry Configuration"
Write-Info "Checking and modifying the registry key 'VulnerableDriverBlocklistEnable'..."
$restartRequired = Set-VulnerableDriverBlocklistEnable

$coreIsolationStatus = Get-CoreIsolationStatus
Write-Info "Core Isolation (Memory Integrity) is currently: $coreIsolationStatus"

if ($coreIsolationStatus -eq "Enabled") {
    Write-Warning "Core Isolation is enabled. Disabling it now..."
    $disableSuccess = Disable-CoreIsolation
    if ($disableSuccess) {
        Write-Info "Core Isolation has been disabled. A system restart is required."
        $restartRequired = $true
    } else {
        Write-Error "Failed to disable Core Isolation. Please disable it manually from Windows Security > Device Security > Core Isolation."
    }
}

if ($restartRequired) {
    Write-Info "You need to restart your PC to use Vector."
    $restartChoice = Read-Host "Do you want to restart your PC now? (Y/N)"
    if ($restartChoice -eq 'Y' -or $restartChoice -eq 'y') {
        Write-Info "Restarting the computer..."
        Restart-Computer -Force
    } else {
        Write-Info "Please restart your PC later to apply the changes."
    }
} else {
    Write-Info "No Changes"
}

Write-Header "Script Execution Complete"
Write-Host "Press any key to exit..." -ForegroundColor DarkRed
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
