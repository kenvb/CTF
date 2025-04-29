<#
.SYNOPSIS
    Runs the Sysinternals Autoruns scanner and returns output in CSV or JSON format.
.DESCRIPTION
    This function invokes autorunsc.exe with a set of flags, captures its output,
    filters out the banner lines, and returns a Base64-encoded string containing either
    raw CSV or JSON data.
.PARAMETER ToolPath
    Full path to autorunsc.exe. Defaults to 'C:\Tools\autorunsc.exe'.
.PARAMETER OutputFormat
    Specifies the output format: CSV (raw text) or JSON (parsed objects). Defaults to CSV.
.EXAMPLE
    # Get raw CSV (default)
    Invoke-AutorunSC -Verbose

    # Get parsed JSON
    Invoke-AutorunSC -OutputFormat JSON -Verbose
#>
function Invoke-AutorunSC {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$ToolPath = 'C:\Tools\autorunsc.exe',

        [Parameter()]
        [ValidateSet('CSV','JSON')]
        [string]$OutputFormat = 'CSV',
        [switch]$ShowConsole
    )

    # Verify the tool exists
    if (-not (Test-Path -Path $ToolPath)) {
        $errorMsg = "Tool not found at '$ToolPath'."
        Write-Warning $errorMsg
        $payload = @{ Error = $errorMsg } | ConvertTo-Json -Depth 2
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        return [Convert]::ToBase64String($bytes)
    }

    # Build argument list with inline comments
    $argumentList = @(
        '-accepteula',       # Accept Sysinternals license
        '-a', '*',           # All auto-start locations
        '-c',                # CSV output
        '-m',                # Hide Microsoft entries
        '-s',                # Verify digital signatures
        '-t',                # UTC timestamps
        '-u',                # Unsigned/VT-detected items
        '-vt',               # Pre-approve VT queries
        '-h'                 # Include file hashes
    )
    $argumentString = $argumentList -join ' '
    Write-Verbose "Executing: $ToolPath $argumentString"

    try {
        # Invoke and capture all output (including banner)
        $lines = & $ToolPath @argumentList 2>&1

        # Filter only CSV lines (lines containing commas)
        $csvLines = $lines | Where-Object { $_ -match ',' }
        $csvContent = $csvLines -join "`n"

        if ($OutputFormat -eq 'JSON') {
            try {
                $records = $csvContent | ConvertFrom-Csv
                $outData = $records | ConvertTo-Json -Depth 3
            } catch {
                $outData = (@{ Error = "CSV to JSON conversion failed: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
            }
        } else {
            $outData = $csvContent
        }
    }
    catch {
        $outData = (@{ Error = "Execution failed: $($_.Exception.Message)" } | ConvertTo-Json -Depth 2)
    }

    # Encode and return
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($outData)
    [Convert]::ToBase64String($bytes)
}

# Example usage:
Invoke-AutorunSC -Verbose
# Invoke-AutorunSC -OutputFormat JSON -Verbose
