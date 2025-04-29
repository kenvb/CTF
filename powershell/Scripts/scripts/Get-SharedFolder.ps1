function Get-SharedFolders {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        $shares = Get-WmiObject -Class Win32_Share | Select-Object `
            Name, Path, Description, Status, ShareType

        if ($OutputFormat -eq 'JSON') {
            $outData = $shares | ConvertTo-Json -Depth 3
        } else {
            $outData = $shares | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve shared folders: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
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
Get-SharedFolders
