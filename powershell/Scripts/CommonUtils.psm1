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
