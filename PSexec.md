# Quick Summary on Using PsExec

## 1. Download and Set Up PsExec
- Download **PsExec** from the [Sysinternals Suite](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec).
- Extract `PsExec.exe` to a convenient location (e.g., `C:\Tools\`).
- Open a **Command Prompt** as Administrator and navigate to the folder where `PsExec.exe` is located:

  ```cmd
  cd C:\Tools
  ```

## 2. Basic Usage
Run a command on a remote computer:

```cmd
psexec \\RemoteComputerName cmd
```

This opens a command prompt on the remote computer.

## 3. Running Commands Remotely
Execute a command remotely without opening an interactive session:

```cmd
psexec \\RemoteComputerName -u UserName -p Password ipconfig
```

This runs `ipconfig` on the remote machine.

## 4. Using Authentication with Domain Credentials
If the remote machine is in a domain, specify the domain with your credentials:

```cmd
psexec \\RemoteComputerName -u Domain\UserName -p Password cmd
```

For security reasons, avoid using plain-text passwords. Instead, use a secure method such as interactive authentication.

## 5. Example Commands for Popular Use Cases

### Check System Information on a Remote Machine
```cmd
psexec \\RemoteComputerName systeminfo
```

### Restart a Remote Machine
```cmd
psexec \\RemoteComputerName shutdown -r -t 0
```

### Run a Script on a Remote Machine
```cmd
psexec \\RemoteComputerName -u UserName -p Password -i -d C:\Scripts\example.bat
```

### Install Software Remotely
```cmd
psexec \\RemoteComputerName -u UserName -p Password -c "C:\Path\To\Setup.exe" /silent
```

### Enable Remote Desktop on a Remote Machine
```cmd
psexec \\RemoteComputerName reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
```

### Enable WinRM on a Remote Machine
```cmd
psexec \\RemoteComputerName winrm quickconfig -q
```

## 6. Running Programs as System
To run a command as **NT AUTHORITY\SYSTEM** on the local machine:

```cmd
psexec -s cmd
```

## 7. Copying Files to Remote Machines
Copy and execute a program on a remote machine:

```cmd
psexec \\RemoteComputerName -c C:\Path\To\Program.exe
```

## 8. Running Commands on Multiple Machines
Run a command on multiple remote machines:

```cmd
psexec @computers.txt ipconfig
```

`computers.txt` should contain a list of remote machine names (one per line).

## 9. Enabling Remote Execution (If Blocked)
If PsExec fails to connect, ensure **Admin Shares** are enabled and the remote machine allows SMB traffic:

```cmd
net use \\RemoteComputerName\IPC$ /u:Domain\Username
```

Ensure the Windows Firewall allows `File and Printer Sharing (SMB-In)`.

## 10. Terminating Remote Processes
Kill a process on a remote machine:

```cmd
psexec \\RemoteComputerName taskkill /IM notepad.exe /F
```

## 11. Exiting Remote Sessions
To exit a PsExec session, simply type:

```cmd
exit
```

## 12. Additional Help
For more options, run:

```cmd
psexec -h
```

This summary provides essential commands to use PsExec for remote administration and troubleshooting.

