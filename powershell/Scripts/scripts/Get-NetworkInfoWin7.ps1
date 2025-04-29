function Get-NetworkInfo-Win7 {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV','JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        $ipInfo = ipconfig | Out-String
        $routesRaw = route print | Out-String
        $netstatOutput = netstat -ano -p tcp | Out-String

        $listeningPorts = foreach ($line in $netstatOutput -split "`n") {
            if ($line -match '^\s*TCP') {
                $parts = $line -split '\s+'
                if ($parts[3] -eq 'LISTENING') {
                    [pscustomobject]@{
                        LocalAddress = $parts[1]
                        State        = $parts[3]
                        PID          = $parts[4]
                    }
                }
            }
        }

        $networkInfo = [pscustomobject]@{
            IPConfiguration = $ipInfo.Trim()
            RoutingTable    = $routesRaw.Trim()
            ListeningPorts  = $listeningPorts
        }

        if ($ShowConsole) {
            Write-Host "`n--- IP Configuration ---"
            Write-Host $ipInfo.Trim()
            Write-Host "`n--- Routing Table ---"
            Write-Host $routesRaw.Trim()
            Write-Host "`n--- Listening TCP Ports ---"
            $listeningPorts | Format-Table -AutoSize
            Write-Host "----------------------------`n"
        }

        if ($OutputFormat -eq 'JSON') {
            $outData = $networkInfo | ConvertTo-Json -Depth 5
        } else {
            $outData = @()
            $outData += "# IPConfiguration"
            $outData += $ipInfo.Trim()
            $outData += "# RoutingTable"
            $outData += $routesRaw.Trim()
            $outData += "# ListeningPorts"
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
