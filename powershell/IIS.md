# Secure IIS Server - Automated Hardening Script
# Author: [Your Name]
# Description: Applies security best practices to IIS

```Powershell
# Ensure the script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as an Administrator." -ForegroundColor Red
    exit
}

Write-Host "Starting IIS Security Hardening..." -ForegroundColor Cyan

# Disable Unused IIS Modules
Write-Host "Disabling unnecessary IIS modules..." -ForegroundColor Yellow
$modulesToDisable = @("WebDAVModule", "CGIModule", "ISAPIExtensions", "ISAPIFilter")
foreach ($module in $modulesToDisable) {
    Remove-WebGlobalModule -Name $module -ErrorAction SilentlyContinue
}

# Enforce TLS 1.2 and Disable Older Protocols
Write-Host "Configuring TLS settings..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Name "Enabled" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Name "DisabledByDefault" -Value 0

# Disable TLS 1.0 & 1.1
$protocols = @("SSL 2.0", "SSL 3.0", "TLS 1.0", "TLS 1.1")
foreach ($protocol in $protocols) {
    New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol\Server" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol\Server" -Name "Enabled" -Value 0
}

# Enable IIS Logging
Write-Host "Enabling IIS logging..." -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter "/system.applicationHost/sites/siteDefaults/logFile" -Name "enabled" -Value "True"

# Disable Directory Browsing
Write-Host "Disabling directory browsing..." -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -Name "enabled" -Value "False"

# Configure Request Filtering
Write-Host "Setting request filtering rules..." -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter "/system.webServer/security/requestFiltering" -Name "allowDoubleEscaping" -Value "False"
Set-WebConfigurationProperty -Filter "/system.webServer/security/requestFiltering/requestLimits" -Name "maxAllowedContentLength" -Value 10485760

# Enforce Windows Authentication & Disable Anonymous Access
Write-Host "Configuring authentication settings..." -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "enabled" -Value "False"
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name "enabled" -Value "True"

# Restrict IP Addresses (Example: Only Allow 192.168.1.100)
Write-Host "Configuring IP restrictions..." -ForegroundColor Yellow
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.webServer/security/ipSecurity" -name "." -value @{allowed="False";ipAddress="192.168.1.100"}

# Enable Dynamic IP Blocking
Set-WebConfigurationProperty -Filter "/system.webServer/security/dynamicIpSecurity" -Name "denyByConcurrentRequests" -Value "True"

# Configure URL Authorization
Write-Host "Configuring URL Authorization settings..." -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter "/system.webServer/security/authorization" -Name "OverrideModeDefault" -Value "Deny"

# Configure Application Pool Security
Write-Host "Setting up secure application pool..." -ForegroundColor Yellow
New-WebAppPool -Name "SecureAppPool"
Set-ItemProperty IIS:\AppPools\SecureAppPool -Name processModel.identityType -Value SpecificUser
Write-Host "IIS Security Hardening Completed!" -ForegroundColor Green
```

# Manual Security Enhancements (To be done separately)
* Configure IIS App Pool identities with low-privilege users
* Install a Web Application Firewall (e.g., Azure WAF, ModSecurity)
* Set security headers (HSTS, X-Content-Type-Options, X-Frame-Options)
* Move IIS logs to a secure storage location
* Implement a reverse proxy (ARR, NGINX) for additional security

# Apply IIS Crypto Best Practices (Requires IIS Crypto CLI)
[IIS Crypto](https://www.nartac.com/Products/IISCrypto/Download)
```Powershell
Write-Host "Applying IIS Crypto best practices..." -ForegroundColor Yellow
Start-Process -FilePath "C:\Program Files\Nartac Software\IIS Crypto\IISCryptoCLI.exe" -ArgumentList " /template best /reboot" -Wait
```

# Setting Up ModSecurity WAF for IIS
## Overview
ModSecurity is an open-source Web Application Firewall (WAF) that helps protect IIS from common web-based threats like SQL injection, cross-site scripting (XSS), and other malicious attacks.

## Install ModSecurity for IIS
### Download & Install
1. Download **ModSecurity for IIS** from:
   - [ModSecurity IIS Release](https://github.com/SpiderLabs/ModSecurity/releases)
   - [Official Guide](https://www.trustwave.com/en-us/resources/library/documents/modsecurity-iis-installation-guide/)
2. Extract the files and copy `modsecurity.dll` to:
   ```text
   C:\Program Files\ModSecurity\
   ```
3. Register the ModSecurity module in IIS:
   ```powershell
   regsvr32 C:\Program Files\ModSecurity\modsecurity.dll
   ```
4. Open **IIS Manager** → Select your site → Click **Modules** → Ensure `ModSecurity` is enabled.

## Configure ModSecurity Rules
### Edit the Main Configuration File
- Navigate to `C:\Program Files\ModSecurity\`
- Open `modsecurity.conf` and enable key settings:
  ```ini
  SecRuleEngine On
  SecRequestBodyAccess On
  SecResponseBodyAccess On
  ```

### Use OWASP Core Rule Set (CRS)
1. Download **OWASP ModSecurity Core Rule Set (CRS):**  
   - [GitHub OWASP CRS](https://github.com/coreruleset/coreruleset)
2. Extract the rules into:
   ```text
   C:\Program Files\ModSecurity\rules\
   ```
3. Modify `modsecurity.conf` to include CRS rules:
   ```ini
   Include "C:\Program Files\ModSecurity\rules\REQUEST-901-INITIALIZATION.conf"
   Include "C:\Program Files\ModSecurity\rules\REQUEST-911-METHOD-ENFORCEMENT.conf"
   Include "C:\Program Files\ModSecurity\rules\REQUEST-933-APPLICATION-ATTACK-PHP.conf"
   ```
## Enable ModSecurity Logging
To log blocked attacks and security events:
```ini
SecAuditEngine RelevantOnly
SecAuditLog C:\inetpub\logs\modsecurity.log
SecDebugLogLevel 3
```
Restart IIS for the changes to apply:
```powershell
iisreset
```
## Test ModSecurity
To verify that ModSecurity is working, try sending a simulated attack in a browser:
```text
http://yoursite.com/?param=<script>alert('XSS')</script>
```
- Check the log file in `C:\inetpub\logs\modsecurity.log` for a blocked request.

## Fine-Tune ModSecurity Rules
If false positives occur, disable specific rules in `modsecurity.conf`:
```ini
SecRuleRemoveById 949110
```
Then restart IIS:
```powershell
iisreset
```