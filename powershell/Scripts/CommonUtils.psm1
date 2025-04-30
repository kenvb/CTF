function Show-ConsolePreview {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$Data,

        [Parameter(Mandatory=$true)]
        [ValidateSet('CSV','JSON')]
        [string]$Format
    )

    if ($Format -eq 'JSON') {
        try {
            $parsed = $Data | ConvertFrom-Json -ErrorAction Stop
            if ($parsed -is [System.Collections.IEnumerable]) {
                $parsed | Format-Table -AutoSize
            } else {
                Write-Host $parsed
            }
        } catch {
            Write-Host ($Data -join "`n")
        }
    } else {
        Write-Host ($Data -join "`n")
    }

    Write-Host "`n--- End of Preview ---`n"
}
# region Utility functions

function Get-SafeTimestamp {
    [CmdletBinding()]
    param()

    return (Get-Date -Format "yyyyMMdd-HHmmss")
}

function Save-ResultToFile {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Result,
        [Parameter(Mandatory = $true)]
        [string]$ServerName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [Parameter(Mandatory = $true)]
        [string]$Timestamp,
        [Parameter()]
        [switch]$ShowConsole
    )

    $folderPath = ".\Output\$ServerName\$ScriptName"
    if (-not (Test-Path -Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }

    $filePath = Join-Path $folderPath "$($ScriptName)-$($Timestamp)"

    if ($Result -is [string] -and $Result.Trim().StartsWith('{')) {
        # JSON string detected
        $filePath += ".json"
    }
    elseif ($Result -is [string] -and $Result.Contains(",")) {
        # CSV detected
        $filePath += ".csv"
    }
    else {
        # Default fallback
        $filePath += ".txt"
    }

    $Result | Out-File -FilePath $filePath -Encoding UTF8

    if ($ShowConsole) {
        Write-Host "Saved output to $filePath\:" -ForegroundColor Yellow
        Get-Content $filePath
    }
}
