function Copy-RemoteToolOnce {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [Parameter(Mandatory)]
        [string]$ToolName,

        [string]$LocalToolsPath = "$PSScriptRoot\Tools",
        [string]$RemoteToolsPath = "C:\Tools"
    )

    $remotePath = Join-Path $RemoteToolsPath $ToolName
    $localPath  = Join-Path $LocalToolsPath  $ToolName

    $toolExists = Invoke-Command -Session $Session -ScriptBlock {
        param($Path)
        Test-Path $Path
    } -ArgumentList $remotePath

    if (-not $toolExists) {
        Write-Host "Copying $ToolName to remote system..."

        Invoke-Command -Session $Session -ScriptBlock {
            param($Path)
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -ItemType Directory -Force | Out-Null
            }
        } -ArgumentList $RemoteToolsPath

        Copy-Item -Path $localPath -Destination $remotePath -ToSession $Session -Force
    } else {
        Write-Host "$ToolName already exists on remote system."
    }

    return $remotePath
}