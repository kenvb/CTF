$services = @(
    "Spooler", "Fax", "UmRdpService", "WerSvc", "bthserv", "WMPNetworkSvc",
    "WbioSrvc", "xsd", "RemoteRegistry", "seclogon", "SSDPSRV", "wcncsvc",
    "CSC", "XblAuthManager", "XblGameSave", "XboxNetApiSvc", "SharedAccess", "SCardSvr"
)

$results = foreach ($svc in $services) {
    try {
        Stop-Service -Name $svc -Force -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        [pscustomobject]@{ Service = $svc; Status = "Disabled and stopped successfully" }
    } catch {
        [pscustomobject]@{ Service = $svc; Status = "Failed: $($_.Exception.Message)" }
    }
}
$json = $results | ConvertTo-Json -Depth 2
[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))