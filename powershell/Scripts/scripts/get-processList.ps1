<#
.SYNOPSIS
    Retrieves running processes on the system.
.DESCRIPTION
    Captures a list of running processes and returns it in either CSV or JSON format, base64-encoded.
.PARAMETER OutputFormat
    Specifies the output format: CSV (raw text) or JSON (parsed objects). Defaults to CSV.
.EXAMPLE
    Get-ProcessList -Verbose
    Get-ProcessList -OutputFormat JSON -Verbose
#>
function Get-ProcessList {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV','JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        $processes = Get-Process | Select-Object Name, Id, CPU, WorkingSet, StartTime -ErrorAction SilentlyContinue

        if ($OutputFormat -eq 'JSON') {
            $outData = $processes | ConvertTo-Json -Depth 3
        } else {
            $outData = $processes | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve processes: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }
    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example:
Get-ProcessList -Verbose
