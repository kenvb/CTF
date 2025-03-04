# BleachBit
## Introduction
BleachBit is an open-source disk cleaning and privacy tool designed to free up disk space, remove unwanted files, and securely delete sensitive data. It supports both **GUI** and **command-line interface (CLI)** operations, making it a powerful tool for automation.

# Tracking BleachBit Usage
If you suspect BleachBit is being used to cover tracks, here’s how to detect it.

### Windows

#### 1. Check If BleachBit Is Installed
```powershell
Get-Command -Name bleachbit* -ErrorAction SilentlyContinue
```

#### 2. Check for Recent Execution of BleachBit
```powershell
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4688} | Where-Object { $_.Message -match "bleachbit.exe" }
```

#### **3. Check for Recent File Deletions**
```powershell
wevtutil qe Microsoft-Windows-Security-Auditing/Operational /q:"*[System[(EventID=4663)]]" /f:text | Select-String "bleachbit"
```

#### **4. Look for BleachBit Logs**
```powershell
Get-ChildItem -Path "$env:APPDATA\BleachBit\log" -Recurse
```

---

### **Linux**

#### **1. Check If BleachBit Is Installed**
```bash
which bleachbit
dpkg -l | grep bleachbit  # Debian-based (Ubuntu)
rpm -qa | grep bleachbit  # RedHat-based (Fedora, CentOS)
```

#### **2. Check for Recent Execution**
```bash
grep "bleachbit" ~/.bash_history
```

#### **3. Check System Logs**
```bash
journalctl -xe | grep bleachbit
sudo cat /var/log/syslog | grep bleachbit
```

#### **4. Monitor BleachBit with Audit Logs**
```bash
sudo auditctl -w /usr/bin/bleachbit -p x -k bleachbit_activity
```
To view logs:
```bash
sudo ausearch -k bleachbit_activity
```

---

## **Real-Time Monitoring**
To actively monitor BleachBit usage, set up real-time alerts:

### **Windows (PowerShell - Real-Time Process Monitoring)**
```powershell
$filter = @{"EventID"=4688; "Message"="bleachbit.exe" }
Get-WinEvent -FilterHashtable $filter -MaxEvents 10
```

### **Linux (Bash - Live Process Monitoring)**
```bash
sudo lsof -c bleachbit
```
or continuously monitor logs:
```bash
tail -f /var/log/syslog | grep bleachbit
```

## **Main Features**
- Deletes temporary files, cache, logs, cookies, and more from various applications (e.g., Firefox, Chrome, LibreOffice, system utilities).
- Shreds files to prevent data recovery.
- Wipes free disk space to remove traces of deleted files.
- Offers a **command-line interface (CLI)** for automation and scripting.
- Cleans specific applications and system files.

## **BleachBit Command Line Interface (CLI)**
BleachBit provides a powerful **CLI** that allows users to automate cleaning tasks and integrate them into scripts.

### **Basic Syntax**
```sh
bleachbit [options] [cleaners...]
```
or, in Windows:
```cmd
bleachbit.exe [options] [cleaners...]
```
### **Common CLI Options**
| Command | Description |
|---------|-------------|
| `--help` | Displays the help menu with available commands. |
| `--list` | Lists all available cleaning options (categories like browsers, system files, etc.). |
| `--preview` | Shows what files would be deleted without actually deleting them. |
| `--clean` | Executes cleaning for specified options. |
| `--delete` | Deletes specific files or folders securely. |
| `--overwrite` | Overwrites free disk space to prevent recovery of deleted files. |
| `--shred` | Securely deletes and overwrites specific files. |

## **Examples of CLI Usage**
### **1. List Available Cleaning Options**
```sh
bleachbit --list
```
This will return a list of all available cleaning categories, such as:
```plaintext
firefox.cache
firefox.cookies
system.tmp
chrome.history
```
### **2. Preview What Will Be Cleaned (No Deletion)**
```sh
bleachbit --preview firefox.cache firefox.cookies
```
This will show the files that would be deleted but does not remove them.

### **3. Clean Specific Applications or Categories**
```sh
bleachbit --clean firefox.cache firefox.cookies system.tmp
```
This command **deletes** the Firefox cache, cookies, and temporary system files.

### **4. Clean Everything Available**
```sh
bleachbit --clean --all
```
**Warning:** This removes all available categories without confirmation.

### **5. Shred a Specific File**
```sh
bleachbit --shred /path/to/sensitive_file.txt
```
This securely deletes and overwrites the file to prevent recovery.

### **6. Shred a Directory**
```sh
bleachbit --shred /home/user/Documents/private_folder
```
This securely deletes an entire folder.

### **7. Overwrite Free Space to Prevent Data Recovery**
```sh
bleachbit --overwrite
```
This ensures deleted files are **not recoverable** by forensic tools.

### **8. Delete Specific Files or Folders**
```sh
bleachbit --delete /path/to/file_or_folder
```
This removes a file or folder permanently without additional cleaning.

