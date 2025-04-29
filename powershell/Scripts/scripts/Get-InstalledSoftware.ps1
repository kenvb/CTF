<#
.SYNOPSIS
    Retrieves installed software from the system.
.DESCRIPTION
    Reads uninstall registry keys and returns a list of installed applications
    including name, version, publisher, install date, and install location.
.PARAMETER OutputFormat
    Specifies the output format: CSV (raw text) or JSON (parsed objects). Defaults to CSV.
.EXAMPLE
    Get-InstalledSoftware -Verbose
    Get-InstalledSoftware -OutputFormat JSON -Verbose
#>
function Get-InstalledSoftware {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV','JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    try {
        $paths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )

        $apps = foreach ($path in $paths) {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | ForEach-Object {
                [pscustomobject]@{
                    Name            = $_.DisplayName
                    Version         = $_.DisplayVersion
                    Publisher       = $_.Publisher
                    InstallLocation = $_.InstallLocation
                    InstallDate     = if ($_.InstallDate -match '^\d{8}$') {
                        # Format InstallDate if it's in YYYYMMDD
                        [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null).ToString('yyyy-MM-dd')
                    } else {
                        $null
                    }
                }
            }
        }

        if ($OutputFormat -eq 'JSON') {
            $outData = $apps | ConvertTo-Json -Depth 3
        } else {
            $outData = $apps | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve installed software: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }
    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }
    

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example:
Get-InstalledSoftware -Verbose
