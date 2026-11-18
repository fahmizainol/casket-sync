# Copies the small, useful parts of the world into this repo, converts .dat to JSON, commits and pushes.
# Safe to run while Minecraft is open: files are read without blocking the game's saves, and any file
# caught mid-save is skipped (the previous good copy is kept).
# Manual run: double-click sync.bat. Automatic: watch.ps1 (started at logon by a scheduled task).
$ErrorActionPreference = 'Stop'
$Repo  = $PSScriptRoot
$World = "$env:APPDATA\PrismLauncher\instances\The Casket of Reveries -2.2.9.8\minecraft\saves\rotters fixed"
$Stage = Join-Path $Repo '.staging'
$Dirs  = 'playerdata','data','advancements','stats','ftbquests','ftbteams','ftbessentials','battletowers','serverconfig'
$Files = 'level.dat'

# One sync at a time (watcher + manual shortcut)
$mutex = New-Object System.Threading.Mutex($false, 'Local\CasketWorldSync')
if (-not $mutex.WaitOne(0)) { Write-Host 'Another sync is running.'; exit 0 }
try {
    if (-not (Test-Path $World)) { Write-Host "World not found: $World" -ForegroundColor Red; exit 1 }

    # 1. Stage a copy, opening files with full sharing so Minecraft can still write/replace them
    if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
    $share = [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete
    $src = @()
    foreach ($d in $Dirs) { $p = Join-Path $World $d; if (Test-Path $p) { $src += Get-ChildItem $p -Recurse -File } }
    foreach ($f in $Files) { $p = Join-Path $World $f; if (Test-Path $p) { $src += Get-Item $p } }
    foreach ($item in $src) {
        if ($item.Name -like '*.dat_old' -or $item.Name -like '*.tmp') { continue }
        $rel = $item.FullName.Substring($World.Length + 1)
        $out = Join-Path $Stage $rel
        New-Item -ItemType Directory -Force (Split-Path $out) | Out-Null
        try {
            $in = [IO.File]::Open($item.FullName, 'Open', 'Read', $share)
            try { $o = [IO.File]::Create($out); try { $in.CopyTo($o) } finally { $o.Dispose() } } finally { $in.Dispose() }
        } catch { Write-Host "skip $rel ($($_.Exception.Message))" }
    }

    # 2. Validate and merge into world/ + readable/
    python -I (Join-Path $Repo 'tools\merge.py') $Stage (Join-Path $Repo 'world') (Join-Path $Repo 'readable')
    if ($LASTEXITCODE -ne 0) { throw 'merge failed' }
    Remove-Item $Stage -Recurse -Force

    # 3. Commit and push (only if something changed)
    Set-Location $Repo
    git add -A
    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) { Write-Host 'No changes since last sync.' -ForegroundColor Yellow; exit 0 }
    git commit -q -m ("sync " + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    git push -q -u origin main
    if ($LASTEXITCODE -ne 0) { Write-Host 'Push failed (committed locally; next sync will push it).' -ForegroundColor Red; exit 1 }
    Write-Host 'Synced and pushed.' -ForegroundColor Green
}
finally { $mutex.ReleaseMutex(); $mutex.Dispose() }
