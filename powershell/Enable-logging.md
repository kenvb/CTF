## 1. Enable PowerShell Module Logging

Module Logging records the modules loaded during a session. This configuration logs all modules by using a wildcard (`*`).

```powershell
# Create the registry key for Module Logging if it doesn't exist.
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Force

# Enable module logging.
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1 -PropertyType DWORD -Force

# Create (or use) the ModuleNames key.
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Force

# Add a wildcard to log all modules.
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Name "*" -Value "*" -PropertyType String -Force
# Create the registry key for ScriptBlock Logging.
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force

# Enable script block logging.
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -PropertyType DWORD -Force

# Optional: Enable verbose logging to capture script block invocation metadata.
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockInvocationLogging" -Value 1 -PropertyType DWORD -Force
# Enable success and failure auditing for Process Creation.
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
```
# PowerShell Enhanced Logging and Audit Setup

This document provides the PowerShell commands to enable enhanced logging settings that are useful for forensic investigations. It covers:

- **Module Logging:** Tracks which PowerShell modules are loaded.
- **Script Block Logging:** Logs detailed content of executed script blocks.
- **Transcription Logging:** Captures full session transcripts.
- **Process Creation Auditing:** Logs events for new process creation.

> **Note:** Run these commands in an elevated PowerShell session (as an administrator).
