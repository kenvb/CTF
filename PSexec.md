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

## 4. Running Programs as System
To run a command as **NT AUTHORITY\SYSTEM** on the local machine:

```cmd
psexec -s cmd
```

## 5. Copying Files to Remote Machines
Copy and execute a program on a remote machine:

```cmd
psexec \\RemoteComputerName -c C:\Path\To\Program.exe
```

## 6. Running Commands on Multiple Machines
Run a command on multiple remote machines:

```cmd
psexec @computers.txt ipconfig
```

`computers.txt` should contain a list of remote machine names (one per line).

## 7. Enabling Remote Execution (If Blocked)
If PsExec fails to connect, ensure **Admin Shares** are enabled and the remote machine allows SMB traffic:

```cmd
net use \\RemoteComputerName\IPC$ /u:Domain\Username
```

Ensure the Windows Firewall allows `File and Printer Sharing (SMB-In)`.

## 8. Terminating Remote Processes
Kill a process on a remote machine:

```cmd
psexec \\RemoteComputerName taskkill /IM notepad.exe /F
```

## 9. Exiting Remote Sessions
To exit a PsExec session, simply type:

```cmd
exit
```

## 10. Additional Help
For more options, run:

```cmd
psexec -h
```

This summary provides essential commands to use PsExec for remote administration and troubleshooting.

