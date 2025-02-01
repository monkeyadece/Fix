$registryPath = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
$values = Get-ItemProperty -Path $registryPath
foreach ($value in $values.PSObject.Properties) {
    if ($value.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) {
        Remove-ItemProperty -Path $registryPath -Name $value.Name
    }
}
$authExePath = "C:\matcha\auth.exe"
if (Test-Path $authExePath) {
    Remove-Item -Path $authExePath -Force
    Write-Host "$authExePath has been deleted."
} else {
    Write-Host "$authExePath not found."
}
Write-Host "FIXED mATCHA FOLLOW THE INSTRUTIONS"

Write-Host "Delete All matacha files after | Made by monkeyadece :)" 
