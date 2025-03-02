# WinRM Setup for Remote PowerShell Access

## 1. Enable WinRM on the Remote Machine
Run the following command in an elevated (Administrator) PowerShell prompt:

```powershell
winrm quickconfig
```

- Starts the WinRM service.
- Creates a listener for incoming connections.
- Configures the firewall to allow WinRM traffic.

## 2. Configure Authentication Settings

### Kerberos (Default in a Domain)
- Kerberos authentication is used by default in domain environments.
- No extra configuration is necessary if the target machine is part of a domain.

### CredSSP (For Multi-Hop Scenarios)
- CredSSP allows credential delegation, which is useful if the remote session needs to access additional network resources.
- To enable CredSSP, configure it on both the client and the server.

On the server, ensure Kerberos authentication is enabled:

```powershell
Set-Item WSMan:\localhost\Service\Auth\Kerberos $true
```

## 3. (Optional) Configure WinRM over HTTPS
Using HTTPS provides full transport-level encryption.

### a. Generate a Self-Signed Certificate
Replace `"yourserver.domain.com"` with your server’s fully qualified domain name:

```powershell
$cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName "yourserver.domain.com" -KeyUsage DigitalSignature, KeyEncipherment -Type SSLServerAuthentication
$thumbprint = $cert.Thumbprint
```

### b. Bind the Certificate to the WinRM HTTPS Listener

```powershell
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=\"yourserver.domain.com\"; CertificateThumbprint=\"$thumbprint\"}"
```

### c. Configure the Firewall

```powershell
Enable-NetFirewallRule -Name "WINRM-HTTPS-In-TCP"
```

Or create a new rule if necessary:

```powershell
New-NetFirewallRule -Name "WinRM HTTPS" -DisplayName "WinRM HTTPS" -Protocol TCP -LocalPort 5986 -Direction Inbound -Action Allow
```

## 4. Test the Configuration

### a. Verify WinRM Listeners

```powershell
winrm enumerate winrm/config/Listener
```

### b. Establish a Remote Session from the Client

#### Using Kerberos (HTTP or HTTPS)

```powershell
Enter-PSSession -ComputerName yourserver.domain.com -Authentication Kerberos
```

#### Using CredSSP (If configured for multi-hop)

```powershell
Enter-PSSession -ComputerName yourserver.domain.com -Authentication CredSSP -Credential (Get-Credential)
```

## 5. Additional Considerations

- **Client Configuration:** Ensure the WinRM service is enabled and configured appropriately on the client if managing local settings.
- **Security Best Practices:**
  - Use HTTPS for sensitive data or untrusted networks.
  - Enable logging and auditing for remote sessions.
  - Regularly update certificates and review WinRM configuration settings.

