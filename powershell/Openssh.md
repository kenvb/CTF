# Stop OpenSSH services if running
Get-Service -Name sshd, ssh-agent -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue

# Uninstall existing OpenSSH server
Write-Host "Uninstalling OpenSSH Server..."
Remove-WindowsFeature -Name OpenSSH-Server -ErrorAction SilentlyContinue

# Remove any existing SSH directory
$sshDir = "$env:ProgramData\ssh"
if (Test-Path $sshDir) {
    Write-Host "Removing old OpenSSH configuration..."
    Remove-Item -Path $sshDir -Recurse -Force
}

# Download the latest OpenSSH
$downloadUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip"
$downloadPath = "$env:TEMP\OpenSSH-Win64.zip"
$installPath = "C:\Program Files\OpenSSH"

Write-Host "Downloading latest OpenSSH version..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath

# Extract OpenSSH
Write-Host "Extracting OpenSSH..."
Expand-Archive -Path $downloadPath -DestinationPath $installPath -Force

# Install OpenSSH service
Set-Location $installPath
Write-Host "Installing OpenSSH Service..."
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File .\install-sshd.ps1" -Wait -NoNewWindow

# Configure and start OpenSSH
Write-Host "Setting OpenSSH to start automatically..."
Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd

Write-Host "OpenSSH installation complete!"
