function Get-PsLoggedOn {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'CSV',

        [switch]$ShowConsole
    )

    $toolPath = "C:\Tools\PsLoggedOn.exe"

    if (-not (Test-Path -Path $toolPath)) {
        $errorMsg = "PsLoggedOn.exe not found at '$toolPath'."
        Write-Warning $errorMsg
        $payload = @{ Error = $errorMsg } | ConvertTo-Json -Depth 2
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        return [Convert]::ToBase64String($bytes)
    }

    try {
        $rawOutput = & $toolPath /accepteula /nobanner | Out-String
        $lines = $rawOutput -split "`r?`n" | Where-Object { $_ -match "^\s*\S" }

        $parsed = foreach ($line in $lines) {
            [pscustomobject]@{ LoggedOn = $line.Trim() }
        }

        if ($OutputFormat -eq 'CSV') {
            $outData = $parsed | ConvertTo-Csv -NoTypeInformation
        } else {
            $outData = $parsed | ConvertTo-Json -Depth 3
        }
    }
    catch {
        $outData = (@{ Error = "Failed to run PsLoggedOn: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example usage:
 Get-PsLoggedOn
