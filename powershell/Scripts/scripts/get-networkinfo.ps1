<#
.SYNOPSIS
    Retrieves basic network information: IP addresses, routing table, and listening TCP ports.
.DESCRIPTION
    Captures network adapter IPs, current routing table, and open/listening TCP ports.
    Returns results in CSV or JSON format, base64-encoded.
.PARAMETER OutputFormat
    Specifies the output format: CSV (raw text) or JSON (parsed objects). Defaults to CSV.
.EXAMPLE
    Get-NetworkInfo -Verbose
    Get-NetworkInfo -OutputFormat JSON -Verbose
#>
function Get-NetworkInfo {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV','JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        # Get IP addresses (IPv4 and IPv6)
        $ipAddresses = Get-NetIPAddress -AddressFamily IPv4, IPv6 -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, IPAddress, AddressFamily

        # Get routing table
        $routes = Get-NetRoute -ErrorAction SilentlyContinue | Select-Object InterfaceAlias, DestinationPrefix, NextHop, RouteMetric

        # Get listening TCP ports
        $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess

        # Structure into a single object
        $networkInfo = [pscustomobject]@{
            IPAddresses    = $ipAddresses
            RoutingTable   = $routes
            ListeningPorts = $listeningPorts
        }

        if ($OutputFormat -eq 'JSON') {
            $outData = $networkInfo | ConvertTo-Json -Depth 5
        } else {
            # For CSV, flatten data into sections
            $outData = @()
            $outData += "IPAddresses"
            $outData += ($ipAddresses | ConvertTo-Csv -NoTypeInformation)
            $outData += "RoutingTable"
            $outData += ($routes | ConvertTo-Csv -NoTypeInformation)
            $outData += "ListeningPorts"
            $outData += ($listeningPorts | ConvertTo-Csv -NoTypeInformation)
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve network info: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }
    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }
    

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example:
Get-NetworkInfo -Verbose
