# Import the server list
$serverList = Import-Csv -Path ".\servers.csv"

# Prompt for credentials
$cred = Get-Credential

# Create a global variable to store sessions for reuse across scripts
$Global:ServerSessions = @{}

foreach ($server in $serverList) {
    $ip = $server.'ipaddress'
    $name = $server.name

    try {
        $session = New-PSSession -ComputerName $ip -Credential $cred -ErrorAction Stop
        $Global:ServerSessions[$name] = $session
        Write-Host "Session created for $name ($ip)"
    } catch {
        Write-Warning "Could not connect to $name ($ip): $_"
    }
}
