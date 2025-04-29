function Select-RemoteServers {
    param (
        [Hashtable]$SessionMap
    )

    Write-Host "`n--- Connected Servers ---"
    Show-ServerList -SessionMap $SessionMap

    $sessionList = $SessionMap.Keys | Sort-Object
    $numberedList = @()
    $i = 1
    foreach ($name in $sessionList) {
        $numberedList += [pscustomobject]@{ Number = $i; Name = $name }
        $i++
    }

    $selection = Read-Host "Select server numbers (e.g. 1,3,5) or * for all"

    if ($selection -eq '*') {
        return $sessionList
    }

    $selectedIndices = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    $selectedNames = $selectedIndices | ForEach-Object {
        $index = [int]$_
        $numberedList[$index - 1].Name
    }

    return $selectedNames
}

function Select-ScriptToRun {
    $scripts = Get-ChildItem -Path ".\Scripts" -Filter *.ps1 | Sort-Object Name
    $i = 1
    foreach ($script in $scripts) {
        Write-Host "  $i. $($script.Name)"
        $i++
    }
    Write-Host "  C. Custom inline script"

    $choice = Read-Host "Select script to run (number or C)"
    if ($choice -eq 'C' -or $choice -eq 'c') {
        return 'C'
    }

    $index = [int]$choice - 1
    if ($index -ge 0 -and $index -lt $scripts.Count) {
        return $scripts[$index].FullName
    } else {
        Write-Warning "Invalid script selection. Returning to menu."
        return $null
    }
}

function Show-ServerList {
    param (
        [Hashtable]$SessionMap
    )

    $i = 1
    foreach ($name in ($SessionMap.Keys | Sort-Object)) {
        $os = $SessionMap[$name].OS
        $build = $SessionMap[$name].Build
        $arch = $SessionMap[$name].Arch
        Write-Host "  $i. $name - $os (Build $build, $arch)"
        $i++
    }
}

function Test-SessionAlive {
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    try {
        if ($Session.State -eq 'Opened') {
            return $true
        } else {
            return $false
        }
    }
    catch {
        return $false
    }
}

function Get-ServerIP {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    $servers = Import-Csv -Path ".\servers.csv"
    ($servers | Where-Object { $_.name -eq $Name }).ipaddress
}
