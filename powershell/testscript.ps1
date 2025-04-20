foreach ($name in $Global:ServerSessions.Keys) {
    $session = $Global:ServerSessions[$name]
    Invoke-Command -Session $session -ScriptBlock {
        Get-ComputerInfo | Select-Object OSName, WindowsVersion
    }
}