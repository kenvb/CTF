<#
.SYNOPSIS
    Retrieves running and stopped services on the system.
.DESCRIPTION
    Lists services with their name, display name, status, and start type.
    Returns results in CSV or JSON format, base64-encoded.
.PARAMETER OutputFormat
    Specifies the output format: CSV (raw text) or JSON (parsed objects). Defaults to CSV.
.EXAMPLE
    Get-ServiceList -Verbose
    Get-ServiceList -OutputFormat JSON -Verbose
#>
function Get-ServiceList {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV','JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        $services = Get-Service | Select-Object Name, DisplayName, Status, StartType

        if ($OutputFormat -eq 'JSON') {
            $outData = $services | ConvertTo-Json -Depth 3
        } else {
            $outData = $services | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve services: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example:
Get-ServiceList -Verbose
