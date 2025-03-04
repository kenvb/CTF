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





# Windows OpenSSH Certificate Authentication Guide
## 1. Check if OpenSSH is installed

Before setting up certificate authentication, ensure OpenSSH is installed and running on your Windows Server.

### Check if OpenSSH is Installed
Run the following command to check if OpenSSH is installed using **Windows** powershell:
```powershell
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
```
### Start and Enable OpenSSH Service
Ensure the OpenSSH service is running and set to start automatically:
```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

## 2. Generate a Certificate Authority (CA) Key

On the **CA machine** (Linux or another Windows machine with OpenSSH installed), generate an SSH key pair to act as the CA:
```sh
ssh-keygen -t rsa -b 4096 -f ca-key
```
This creates:
- **ca-key** → Private key (keep this secure)
- **ca-key.pub** → Public key (used for signing certificates)

## 3. Sign a User’s SSH Key with the CA

Each user should generate their own SSH key:
```sh
ssh-keygen -t rsa -b 4096 -f user-key
```
The CA signs the user's public key to create a certificate:
```sh
ssh-keygen -s ca-key -I "user-cert" -n username -V +52w user-key.pub
```
- `-s ca-key` → Uses the CA private key to sign  
- `-I "user-cert"` → Certificate identity  
- `-n username` → Restricts this certificate to a specific user  
- `-V +52w` → Valid for 52 weeks  

This process generates **`user-key-cert.pub`**, which is the **signed certificate**.

## 4. Configure Windows SSH Server to Trust the CA

On the **Windows SSH server**, configure it to trust the CA:

1. Copy the **CA public key (`ca-key.pub`)** to the server.
2. Add the key to the trusted CA keys file.

For **administrators**, add it to:
```
C:\ProgramData\ssh\administrators_authorized_keys
```
For **non-admin users**, add it to:
```
C:\Users\username\.ssh\authorized_keys
```

3. Modify the OpenSSH server configuration (`C:\ProgramData\ssh\sshd_config`) and add:
```
TrustedUserCAKeys C:\ProgramData\ssh\ca-key.pub
```

4. Restart the SSH service to apply changes:
```powershell
Restart-Service sshd
```
## 5. Authenticate Using the Signed Certificate

After the setup, users can authenticate using the **signed certificate**.

1. Copy the **signed certificate (`user-key-cert.pub`)** and private key (`user-key`) to the client machine.
2. Edit the SSH client configuration (`~/.ssh/config`):

```
Host windows-server
    HostName 192.168.1.100
    User username
    IdentityFile ~/user-key
    CertificateFile ~/user-key-cert.pub
```

3. Connect using:
```sh
ssh windows-server
```

## 6. PowerShell Script to Automate Setup

The following PowerShell script automates:
1. **Installing OpenSSH**
2. **Starting the SSH service**
3. **Configuring the CA key on Windows**
4. **Restarting OpenSSH**

```powershell
# Define the CA Public Key Path
$CAKeyPath = "C:\ProgramData\ssh\ca-key.pub"
$SSHDConfigPath = "C:\ProgramData\ssh\sshd_config"

# Ensure SSHD service is running
Write-Host "Starting SSHD Service..."
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Configure TrustedUserCAKeys in sshd_config
if (!(Test-Path $CAKeyPath)) {
    Write-Host "CA Key not found at $CAKeyPath. Please copy your CA public key here."
    exit
}

Write-Host "Configuring OpenSSH to trust CA..."
Add-Content -Path $SSHDConfigPath -Value "`nTrustedUserCAKeys $CAKeyPath"

# Restart SSHD service
Write-Host "Restarting SSHD to apply changes..."
Restart-Service sshd

Write-Host "Setup complete! Ensure your CA public key is in $CAKeyPath."
```

[Microsoft OpenSSH Docs](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_overview)  
[OpenSSH Certificate Authentication](https://man.openbsd.org/ssh-keygen#CERTIFICATES)
