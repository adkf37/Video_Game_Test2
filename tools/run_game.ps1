param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath) {
    $command = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $GodotPath = $command.Source }
}
if (-not $GodotPath) {
    $candidate = Get-ChildItem -LiteralPath "$env:USERPROFILE\Downloads" -Filter '*Godot*' -Directory -ErrorAction SilentlyContinue |
        Get-ChildItem -Filter 'Godot*_console.exe' | Select-Object -First 1
    if ($candidate) { $GodotPath = $candidate.FullName }
}
if (-not $GodotPath) { throw 'Pass -GodotPath with the path to your Godot 4 executable.' }
$projectPath = Join-Path $PSScriptRoot '..\godot'
& $GodotPath --path $projectPath
