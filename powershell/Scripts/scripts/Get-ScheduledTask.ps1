function Get-ScheduledTasks {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        $tasks = schtasks.exe /Query /FO CSV /V | ConvertFrom-Csv

        if ($OutputFormat -eq 'JSON') {
            $outData = $tasks | ConvertTo-Json -Depth 3
        } else {
            $outData = $tasks | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve scheduled tasks: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    if ($ShowConsole) {
        if ($OutputFormat -eq 'JSON') {
            $parsed = $outData | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsed) {
                $parsed | Format-Table -AutoSize
            } else {
                Write-Host $outData
            }
        } else {
            Write-Host ($outData -join "`n")
        }
        Write-Host "`n--- End of Preview ---`n"
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example usage:
Get-ScheduledTasks
