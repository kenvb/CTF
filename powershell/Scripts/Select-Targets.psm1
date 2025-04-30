function Select-RemoteServers {
    param (
        [Hashtable]$SessionMap
    )

    Write-Host "`n--- Connected Servers ---"
    $ServersCsv = Import-Csv -Path ".\\servers.csv"

    $i = 1
    $sessionList = $SessionMap.Keys | Sort-Object
    $numberedList = @()

    foreach ($name in $sessionList) {
        $serverCsv = $ServersCsv | Where-Object { $_.name -eq $name }
        $ip = if ($serverCsv) { $serverCsv.ipaddress } else { "Unknown IP" }

        $os = $SessionMap[$name].OS
        $build = $SessionMap[$name].Build
        $arch = $SessionMap[$name].Arch

        Write-Host ("  {0,2}. {1,-20} {2,-15} {3,-25} Build {4,-7} [{5}]" -f $i, $name, $ip, $os, $build, $arch)

        $numberedList += [pscustomobject]@{ Number = $i; Name = $name }
        $i++
    }

    Write-Host "  *  (Select all servers)"

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

function Select-ScriptsToRun {
    Write-Host "`n--- Available Scripts ---"
    $scripts = Get-ChildItem -Path ".\\Scripts" -Filter *.ps1 | Sort-Object Name
    if (-not $scripts) {
        Write-Warning "No scripts found."
        return $null
    }

    $i = 1
    foreach ($script in $scripts) {
        Write-Host "  $i. $($script.Name)"
        $i++
    }
    Write-Host "  *  (Select all scripts)"

    $selection = Read-Host "Select script numbers (e.g. 1,3,5) or * for all"

    if ($selection -eq '*') {
        return $scripts
    }

    $selectedIndices = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
    $selectedScripts = $selectedIndices | ForEach-Object {
        $index = [int]$_
        if ($index -ge 1 -and $index -le $scripts.Count) {
            $scripts[$index - 1]
        }
    }

    return $selectedScripts
}

function Show-ServerList {
    param (
        [Hashtable]$SessionMap
    )

    $ServersCsv = Import-Csv -Path ".\\servers.csv"

    $i = 1
    foreach ($name in ($SessionMap.Keys | Sort-Object)) {
        $serverCsv = $ServersCsv | Where-Object { $_.name -eq $name }
        $ip = if ($serverCsv) { $serverCsv.ipaddress } else { "Unknown IP" }

        $os = $SessionMap[$name].OS
        $build = $SessionMap[$name].Build
        $arch = $SessionMap[$name].Arch

        Write-Host ("  {0,2}. {1,-20} {2,-15} {3,-25} Build {4,-7} [{5}]" -f $i, $name, $ip, $os, $build, $arch)
        $i++
    }
}

function Test-SessionAlive {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    try {
        return ($Session.State -eq 'Opened')
    }
    catch {
        return $false
    }
}

function Get-ServerIP {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    $servers = Import-Csv -Path ".\\servers.csv"
    ($servers | Where-Object { $_.name -eq $Name }).ipaddress
}
