# Run-PrivescCheckWrapper.ps1
# thi sis just a wrapper around https://github.com/itm4n/PrivescCheck

param (
    [ValidateSet("json", "csv")]
    [string]$OutputFormat = "csv"
)

$privescPath = "C:\Tools\PrivescCheck.ps1"
$reportFolder = "C:\Tools\Reports"
$reportBasePath = Join-Path $reportFolder "Privesc_$($env:COMPUTERNAME)"
$reportPath = "$reportBasePath.csv"  # Actual file that will be created

# Ensure the report directory exists
if (-not (Test-Path $reportFolder)) {
    New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
}

# Check for presence of PrivescCheck
if (-not (Test-Path $privescPath)) {
    $errorMsg = "PrivescCheck.ps1 not found at '$privescPath'."
    Write-Warning $errorMsg
    $payload = @{ Tool = "PrivescCheck"; Error = $errorMsg } | ConvertTo-Json -Depth 2
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    return [Convert]::ToBase64String($bytes)
}

try {
    # Import PrivescCheck
    . $privescPath

    # Run the scan and output CSV report to disk (without adding .csv twice)
    $null = Invoke-PrivescCheck -Extended -Audit -Format CSV -Report $reportBasePath

    # Read and return the contents of the report
    if (Test-Path $reportPath) {
        return Get-Content $reportPath -Raw
    } else {
        $errorMsg = "Expected report file not found at $reportPath after running PrivescCheck."
        Write-Warning $errorMsg
        $payload = @{ Tool = "PrivescCheck"; Error = $errorMsg } | ConvertTo-Json -Depth 2
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        return [Convert]::ToBase64String($bytes)
    }

} catch {
    $payload = @{
        Tool  = "PrivescCheck"
        Error = $_.Exception.Message
    } | ConvertTo-Json -Depth 2
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    return [Convert]::ToBase64String($bytes)
}