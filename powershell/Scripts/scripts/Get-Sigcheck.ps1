[CmdletBinding()]
param (
    [string]$ToolName = "sigcheck.exe",
    [string]$TargetPath = "C:\Windows"
)

$Script:OutputFormat = 'csv'

try {
    $toolPath = "C:\Tools\$ToolName"
    if (-not (Test-Path $toolPath)) {
        Write-Warning "$ToolName not found at $toolPath"
        return
    }

    $cmd = "$toolPath -accepteula -nobanner -h -c `"$TargetPath`""
    $output = Invoke-Expression $cmd

    if (-not $output) {
        Write-Warning "No output from sigcheck."
        return
    }

    $outputString = $output -join "`n"

    if ($ShowConsole) {
        Show-ConsolePreview -Label "$ToolName output" -Content $outputString
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($outputString)
    $encoded = [System.Convert]::ToBase64String($bytes)
    return $encoded
}
catch {
    Write-Warning "Error running $ToolName\: $_"
}
