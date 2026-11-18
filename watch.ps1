# Background watcher: while the Casket of Reveries modpack is running, sync every 5 minutes;
# when it closes, do one final sync, then idle until it starts again.
# Started hidden at logon by the scheduled task "Casket World Sync".
$Repo = $PSScriptRoot
$Log  = Join-Path $Repo 'sync.log'
$Interval = 300   # seconds between syncs while playing

function Test-Mc {
    [bool](Get-CimInstance Win32_Process -Filter "Name='javaw.exe' OR Name='java.exe'" |
           Where-Object { $_.CommandLine -like '*Casket of Reveries*' })
}
function Invoke-Sync([string]$why) {
    if ((Test-Path $Log) -and (Get-Item $Log).Length -gt 1MB) { Remove-Item $Log }
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Repo 'sync.ps1') 2>&1 |
           Where-Object { $_ -notmatch 'LF will be replaced' }
    Add-Content $Log ("[{0}] {1}: {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $why, ($out -join ' | '))
}

$playing = $false
$next = Get-Date
while ($true) {
    if (Test-Mc) {
        if (-not $playing) { $playing = $true; $next = (Get-Date).AddSeconds($Interval) }
        elseif ((Get-Date) -ge $next) { Invoke-Sync 'periodic'; $next = (Get-Date).AddSeconds($Interval) }
        Start-Sleep 15
    } else {
        if ($playing) { $playing = $false; Start-Sleep 10; Invoke-Sync 'mc closed' }
        Start-Sleep 30
    }
}
