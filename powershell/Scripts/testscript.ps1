$basePath = ".\Output"
$scriptSubfolderName = "Get-Date"  # Change this if running a different script

foreach ($entry in $Global:ServerSessions.GetEnumerator()) {
    $name = $entry.Key
    $session = $entry.Value
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

    # Paths
    $serverFolder = Join-Path -Path $basePath -ChildPath $name
    $scriptFolder = Join-Path -Path $serverFolder -ChildPath $scriptSubfolderName
    $fileName = "output-$timestamp.txt"
    $fullPath = Join-Path -Path $scriptFolder -ChildPath $fileName

    # Ensure folders exist
    New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null

    Write-Host "Running command on $name..."
    try {
        $result = Invoke-Command -Session $session -ScriptBlock {
            Get-Date
        }

        # Save output
        $result | Out-File -FilePath $fullPath -Encoding UTF8
        Write-Host "Saved output to $fullPath"
    } catch {
        Write-Warning "Failed to run command on $name : $_"
    }
}
