function Get-PsInfo {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'CSV',

        [switch]$ShowConsole
    )

    $toolPath = "C:\Tools\PsInfo.exe"

    if (-not (Test-Path -Path $toolPath)) {
        $errorMsg = "PsInfo.exe not found at '$toolPath'."
        Write-Warning $errorMsg
        $payload = @{ Error = $errorMsg } | ConvertTo-Json -Depth 2
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        return [Convert]::ToBase64String($bytes)
    }

    try {
        $rawOutput = & $toolPath /accepteula | Out-String
        $lines = $rawOutput -split "`r?`n" | Where-Object { $_ -match ":" }

        $parsed = foreach ($line in $lines) {
            $parts = $line -split ":", 2
            [pscustomobject]@{
                Property = $parts[0].Trim()
                Value    = $parts[1].Trim()
            }
        }

        if ($OutputFormat -eq 'CSV') {
            $outData = $parsed | ConvertTo-Csv -NoTypeInformation
        } else {
            $outData = $parsed | ConvertTo-Json -Depth 3
        }
    }
    catch {
        $outData = (@{ Error = "Failed to run PsInfo: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example local test:
 Get-PsInfo
