# Permanent Machine PATH Modification Script
# Retrieve the current Machine PATH environment variable permanently.
$envPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

if (-not $envPath) {
    Write-Host "Machine PATH is empty or not set. Exiting." -ForegroundColor Yellow
    exit
}

# Split the PATH into individual folders.
$pathFolders = $envPath -split ';'

# Display the current Machine PATH folders with an index.
Write-Host "Current Machine PATH folders:" -ForegroundColor Cyan
for ($i = 0; $i -lt $pathFolders.Length; $i++) {
    Write-Host "$($i + 1): $($pathFolders[$i])"
}

# Prompt the user if they want to permanently remove any folder.
$removePrompt = Read-Host "Do you want to permanently remove any PATH folder? (Y/N)"
if ($removePrompt -match '^(Y|y)$') {
    $indexInput = Read-Host "Enter the index or indices (separated by commas) of the PATH folder(s) to remove"
    
    # Convert the input into zero-based indices.
    $indicesToRemove = $indexInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ - 1 }
    
    # Filter out invalid indices.
    $indicesToRemove = $indicesToRemove | Sort-Object -Unique | Where-Object { $_ -ge 0 -and $_ -lt $pathFolders.Length }
    
    if ($indicesToRemove.Count -eq 0) {
        Write-Host "No valid indices provided. No changes made." -ForegroundColor Yellow
    }
    else {
        # Build a new array that excludes the selected paths.
        $newPathFolders = for ($i = 0; $i -lt $pathFolders.Length; $i++) {
            if (-not ($indicesToRemove -contains $i)) {
                $pathFolders[$i]
            }
        }
        $newPath = $newPathFolders -join ';'
        
        # Permanently update the Machine PATH by setting the environment variable at the Machine level.
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        
        Write-Host "`nMachine PATH has been permanently updated. New PATH folders:" -ForegroundColor Green
        for ($i = 0; $i -lt $newPathFolders.Length; $i++) {
            Write-Host "$($i + 1): $($newPathFolders[$i])"
        }
    }
}
else {
    Write-Host "No changes made to the PATH."
}
