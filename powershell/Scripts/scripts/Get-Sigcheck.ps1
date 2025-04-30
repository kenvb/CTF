# Get-Sigcheck.ps1
param (
    [string]$TargetPath = "C:\Windows\System32"
)

$ToolPath = "C:\Tools\sigcheck.exe"

if (-Not (Test-Path $ToolPath)) {
    Write-Warning "$ToolPath not found on remote system."
    return ""
}

try {
    # Flags:
    # -nobanner : suppress Sysinternals banner
    # -s        : recurse into subdirectories
    # -e        : scan executable images only
    # -c        : output in CSV format
    # -h        : calculate and show file hashes
    $output = & $ToolPath -nobanner -s -e -c -h $TargetPath
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($output))

    return @{
        OutputFormat = 'csv'
        Data         = $encoded
    }
} catch {
    Write-Warning "Sigcheck execution failed: $_"
    return ""
}
