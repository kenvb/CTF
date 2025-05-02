<#
.SYNOPSIS
    Gathers network-related information and returns it as a base64-encoded CSV or JSON string.

.DESCRIPTION
    This script collects IP address configurations, routing table entries, and listening TCP ports.
    It outputs the results in a base64-encoded CSV or JSON format, suitable for transport or storage.

.PARAMETER OutputFormat
    Desired output format: CSV or JSON (default is CSV).

.PARAMETER ShowConsole
    Optionally prints the decoded output to the console.

.EXAMPLE
    .\Get-NetworkInfo.ps1 -OutputFormat CSV -ShowConsole
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
        # Gather data
        $ipAddresses = Get-NetIPAddress -AddressFamily IPv4, IPv6 -ErrorAction SilentlyContinue |
            Select-Object InterfaceAlias, IPAddress, AddressFamily

        $routes = Get-NetRoute -ErrorAction SilentlyContinue |
            Select-Object InterfaceAlias, DestinationPrefix, NextHop, RouteMetric

        $listeningPorts = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Select-Object LocalAddress, LocalPort, OwningProcess

        # Combine into unified CSV structure
        $combined = @()

        foreach ($entry in $ipAddresses) {
            $combined += [pscustomobject]@{
                InterfaceAlias    = $entry.InterfaceAlias
                IPAddress         = $entry.IPAddress
                AddressFamily     = $entry.AddressFamily
                DestinationPrefix = ""
                NextHop           = ""
                RouteMetric       = ""
                LocalAddress      = ""
                LocalPort         = ""
                OwningProcess     = ""
                Section           = "IPAddresses"
            }
        }

        foreach ($entry in $routes) {
            $combined += [pscustomobject]@{
                InterfaceAlias    = $entry.InterfaceAlias
                IPAddress         = ""
                AddressFamily     = ""
                DestinationPrefix = $entry.DestinationPrefix
                NextHop           = $entry.NextHop
                RouteMetric       = $entry.RouteMetric
                LocalAddress      = ""
                LocalPort         = ""
                OwningProcess     = ""
                Section           = "RoutingTable"
            }
        }

        foreach ($entry in $listeningPorts) {
            $combined += [pscustomobject]@{
                InterfaceAlias    = ""
                IPAddress         = ""
                AddressFamily     = ""
                DestinationPrefix = ""
                NextHop           = ""
                RouteMetric       = ""
                LocalAddress      = $entry.LocalAddress
                LocalPort         = $entry.LocalPort
                OwningProcess     = $entry.OwningProcess
                Section           = "ListeningPorts"
            }
        }

        # Format output
        if ($OutputFormat -eq 'JSON') {
            $networkInfo = [pscustomobject]@{
                IPAddresses    = $ipAddresses
                RoutingTable   = $routes
                ListeningPorts = $listeningPorts
            }

            $outData = $networkInfo | ConvertTo-Json -Depth 4 | Out-String
        }
        elseif ($OutputFormat -eq 'CSV') {
            $outData = $combined | ConvertTo-Csv -NoTypeInformation | Out-String
        }

        # Encode as base64
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($outData)
        $outData = [Convert]::ToBase64String($bytes)

        # Optionally show result
        if ($ShowConsole) {
            [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($outData))
        }

        return $outData
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

# Call the function
Get-NetworkInfo -Verbose