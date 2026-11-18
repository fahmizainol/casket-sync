# Copies the small, useful parts of the world into this repo, converts .dat to JSON, commits and pushes.
# Run after playing (Minecraft must be closed). Double-click sync.bat or run: powershell -File sync.ps1
$ErrorActionPreference = 'Stop'
$Repo  = $PSScriptRoot
$World = 'C:\Users\kny\AppData\Roaming\PrismLauncher\instances\The Casket of Reveries -2.2.9.8\minecraft\saves\rotters fixed'
$Dest  = Join-Path $Repo 'world'
$Json  = Join-Path $Repo 'readable'

# 1. Refuse to copy while the modpack is running (half-saved files)
$mc = Get-CimInstance Win32_Process -Filter "Name='javaw.exe' OR Name='java.exe'" |
      Where-Object { $_.CommandLine -like '*Casket of Reveries*' }
if ($mc) { Write-Host 'Minecraft (Casket of Reveries) is still running. Close it first.' -ForegroundColor Red; exit 1 }
if (-not (Test-Path $World)) { Write-Host "World not found: $World" -ForegroundColor Red; exit 1 }

# 2. Mirror the small folders/files (map region files are deliberately excluded)
$dirs  = 'playerdata','data','advancements','stats','ftbquests','ftbteams','ftbessentials','battletowers','serverconfig'
$files = 'level.dat'
foreach ($d in $dirs) {
    $s = Join-Path $World $d
    if (Test-Path $s) {
        robocopy $s (Join-Path $Dest $d) /MIR /NFL /NDL /NJH /NJS /NP /XF *.dat_old *.tmp | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy failed on $d ($LASTEXITCODE)" }
    }
}
foreach ($f in $files) { Copy-Item (Join-Path $World $f) (Join-Path $Dest $f) -Force }

# 3. Readable JSON copies of every .dat
if (Test-Path $Json) { Remove-Item $Json -Recurse -Force }
python -I (Join-Path $Repo 'tools\nbt2json.py') --tree $Dest $Json
if ($LASTEXITCODE -ne 0) { throw 'nbt2json failed' }

# 4. Commit and push
Set-Location $Repo
git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Write-Host 'No changes since last sync.' -ForegroundColor Yellow; exit 0 }
git commit -q -m ("sync " + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
git push -q
Write-Host 'Synced and pushed.' -ForegroundColor Green
