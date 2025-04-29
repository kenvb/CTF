function Invoke-Diff {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'JSON',

        [switch]$ShowConsole
    )

    $outputRoot = Join-Path $PSScriptRoot "..\Output"

    foreach ($serverFolder in Get-ChildItem -Path $outputRoot -Directory) {
        $serverName = $serverFolder.Name

        # Skip folders that are not in the current ServerSessions
        if (-not $Global:ServerSessions.ContainsKey($serverName)) {
            Write-Host "Skipping unrelated folder: $serverName" -ForegroundColor Yellow
            continue
        }

        Write-Host "`n[+] Processing server: $serverName" -ForegroundColor Cyan

        $scriptFolders = Get-ChildItem -Path $serverFolder.FullName -Directory | Where-Object { $_.Name -ne 'Invoke-Diff' }

        foreach ($scriptFolder in $scriptFolders) {
            $scriptName = $scriptFolder.Name
            $jsonFiles = Get-ChildItem -Path $scriptFolder.FullName -Filter *.json | Sort-Object LastWriteTime

            if ($jsonFiles.Count -lt 2) {
                Write-Host "  [!] Skipping $scriptName (not enough output files to diff)" -ForegroundColor Yellow
                continue
            }

            try {
                $previousContent = Get-Content -Path $jsonFiles[-2].FullName -Raw | ConvertFrom-Json
                $latestContent   = Get-Content -Path $jsonFiles[-1].FullName -Raw | ConvertFrom-Json
            } catch {
                Write-Warning "Failed to parse JSON for ${scriptName} on ${serverName}: $($_.Exception.Message)"
                continue
            }
          

            $diff = Compare-Object -ReferenceObject $previousContent -DifferenceObject $latestContent -Property * -PassThru

            if (-not $diff) {
                Write-Host "  [=] No differences found in $scriptName" -ForegroundColor DarkGray
                continue
            }

            # Save the diff
            $diffFolder = Join-Path -Path $serverFolder.FullName -ChildPath "Invoke-Diff\$scriptName"
            if (-not (Test-Path $diffFolder)) {
                New-Item -Path $diffFolder -ItemType Directory -Force | Out-Null
            }

            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $diffPath = Join-Path -Path $diffFolder -ChildPath "diff-$timestamp.json"

            if ($OutputFormat -eq 'CSV') {
                $outData = $diff | ConvertTo-Csv -NoTypeInformation
            } else {
                $outData = $diff | ConvertTo-Json -Depth 5
            }

            # Save as Base64-encoded file
            $encoded = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
            $base64 = [Convert]::ToBase64String($encoded)
            [System.IO.File]::WriteAllText($diffPath, $base64, [System.Text.Encoding]::UTF8)

            Write-Host "  [!] Differences saved: $diffPath" -ForegroundColor Green

            if ($ShowConsole) {
                Show-ConsolePreview -Data $outData -Format $OutputFormat
            }
        }
    }
}

# Example usage:
 Invoke-Diff
