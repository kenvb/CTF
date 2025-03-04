# Using Velociraptor on a Windows Core System
## 1. Download and Install Velociraptor

Since Windows Core lacks a GUI, all actions will be done via PowerShell or CMD.
### Download Velociraptor

1. Open PowerShell and navigate to a working directory:
   ```powershell
   cd C:\IncidentResponse
   ```
2. Download the latest Velociraptor release:
   ```powershell
   Invoke-WebRequest -Uri "https://github.com/Velocidex/velociraptor/releases/latest/download/velociraptor-v0.7.0-windows-amd64.exe" -OutFile "velociraptor.exe"
   ```
   *(Ensure you replace the version number with the latest available.)*

## 2. Running Velociraptor in Standalone Mode

If you just need to collect forensic artifacts from the system, you can run Velociraptor as a standalone executable.

### Check System Compatibility

Ensure the tool runs correctly by executing:
```powershell
.\velociraptor.exe --version
```

### Collecting Forensic Artifacts

To quickly gather forensic data, run:
```powershell
.\velociraptor.exe artifacts collect Windows.EventLogs --output eventlogs.json
```

This will extract Windows event logs into `eventlogs.json`.

Other useful artifact collections:
```powershell
.\velociraptor.exe artifacts collect Windows.SystemInformation --output systeminfo.json
.\velociraptor.exe artifacts collect Windows.Detection.EDRIndicators --output edr_indicators.json
.\velociraptor.exe artifacts collect Windows.Timeline --output timeline.json
```

You can explore available artifacts with:
```powershell
.\velociraptor.exe artifacts list
```

## 3. Running Velociraptor as a Client (Connected to a Server)

For enterprise monitoring, you can deploy Velociraptor as an agent that communicates with a Velociraptor server.

### Generate a Client Configuration

If you have a Velociraptor server, you need a client configuration file (`client.config.yaml`).

1. On your Velociraptor server, generate the client config:
   ```bash
   velociraptor config generate --role client > client.config.yaml
   ```
2. Transfer this file securely to your Windows Core machine.

### Start Velociraptor as a Client

Once you have `client.config.yaml`, install and start the client service:
```powershell
.\velociraptor.exe service install --config client.config.yaml
.\velociraptor.exe service start --config client.config.yaml
```

To verify it's running:
```powershell
Get-Service Velociraptor
```

To stop the service:
```powershell
Stop-Service Velociraptor
```

To uninstall:
```powershell
.\velociraptor.exe service uninstall
```

## 4. Live Querying the System

If the Velociraptor client is connected to a server, you can perform live queries from the Velociraptor GUI or through the Velociraptor API.

Example query to list running processes:
```sql
SELECT * FROM pslist()
```

Query to check recent network connections:
```sql
SELECT * FROM netstat()
```
## 5. Memory and Disk Acquisition

For live memory acquisition:
```powershell
.\velociraptor.exe artifacts collect Windows.Memory.Acquisition --output memory_dump.raw
```

For disk imaging (ensure you have sufficient space):
```powershell
.\velociraptor.exe artifacts collect Windows.Disk.Forensics --output disk_image.dd
```
## 6. Automating Collection with a Hunt

If connected to a Velociraptor server, you can automate artifact collection using a "Hunt."

1. Define a hunt in the Velociraptor web UI.
2. Deploy it to multiple systems.
3. Collect and analyze results centrally.

## 7. Troubleshooting

- **Check logs:** If something isn’t working, view logs with:
  ```powershell
  Get-Content C:\ProgramData\Velociraptor\logs\velociraptor.log -Tail 50
  ```
- **Verify network connectivity:** Ensure the client can reach the Velociraptor server.
- **Ensure the service is running:** Restart if necessary:
  ```powershell
  Restart-Service Velociraptor
  ```
## Useful artifacts

* Windows.Process.List
* Windows.Process.Tree
* Windows.Sysmon.ProcessCreate _(or a Sysmon Logs Artifact)_
* Windows.Registry.Run
* Windows.ScheduledTasks
* Windows.Services
* Windows.NetworkConnections
* Yara Scan Artifacts
* File and Hash Artifacts (e.g., Windows.FileScan)
* Custom Memory Analysis Artifacts
