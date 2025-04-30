function Get-LocalUsers {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CSV', 'JSON')]
        [string]$OutputFormat = 'CSV',

        [switch]$ShowConsole
    )

    try {
        $users = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" | Select-Object `
            Name, Disabled, Lockout, PasswordRequired, PasswordExpires, LastLogon

        if ($OutputFormat -eq 'JSON') {
            $outData = $users | ConvertTo-Json -Depth 3
        } else {
            $outData = $users | ConvertTo-Csv -NoTypeInformation
        }
    }
    catch {
        $outData = (@{ Error = "Failed to retrieve local users: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    if ($ShowConsole) {
        Show-ConsolePreview -Data $outData -Format $OutputFormat
    }
    

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($outData -join "`n"))
    [Convert]::ToBase64String($bytes)
}

# Example usage for local testing:
Get-LocalUsers
