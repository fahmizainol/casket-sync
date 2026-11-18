# Background watcher: while the Casket of Reveries modpack is running, sync a few seconds after each
# Minecraft autosave (every 5 min); when it closes, do one final sync, then idle until it starts again.
# Started hidden at logon by the scheduled task "Casket World Sync".
$Repo = $PSScriptRoot
$Log  = Join-Path $Repo 'sync.log'

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

$LevelDat = "$env:APPDATA\PrismLauncher\instances\The Casket of Reveries -2.2.9.8\minecraft\saves\rotters fixed\level.dat"
function Get-SaveTime { if (Test-Path $LevelDat) { (Get-Item $LevelDat).LastWriteTime } else { [datetime]::MinValue } }

$playing = $false
$lastSynced = Get-SaveTime
while ($true) {
    if (Test-Mc) {
        $playing = $true
        # Minecraft autosaves every 5 min and writes level.dat last; sync shortly after each new save
        $saved = Get-SaveTime
        if ($saved -gt $lastSynced -and ((Get-Date) - $saved).TotalSeconds -ge 5) {
            Invoke-Sync 'after autosave'
            $lastSynced = $saved
        }
        Start-Sleep 5
    } else {
        if ($playing) { $playing = $false; Start-Sleep 10; Invoke-Sync 'mc closed'; $lastSynced = Get-SaveTime }
        Start-Sleep 30
    }
}
