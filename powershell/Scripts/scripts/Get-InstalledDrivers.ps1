
function Get-InstalledDrivers {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'CSV',

        [switch]$ShowConsole
    )

    try {
        $drivers = Get-WmiObject Win32_SystemDriver | Select-Object `
            DisplayName, Name, State, StartMode, PathName

        # Mark drivers that are suspicious (non-Microsoft)
        $drivers = $drivers | Select-Object *, @{
            Name = "Suspicious";
            Expression = {
                if ($_.PathName -and $_.PathName -notmatch "Microsoft|Windows|System32") { $true } else { $false }
            }
        }

        if ($OutputFormat -eq 'JSON') {
            $outData = $drivers | ConvertTo-Json -Depth 3
        } else {
            $outData = $drivers | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve drivers: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }
    
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example usage:
# Get-InstalledDrivers -ShowConsole
Get-InstalledDrivers
