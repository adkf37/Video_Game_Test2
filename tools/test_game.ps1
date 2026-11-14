param([Parameter(Mandatory=$true)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectPath = Join-Path $PSScriptRoot '..\godot'
& $GodotPath --headless --path $projectPath --editor --import --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path $projectPath --script res://tests/race_smoke.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path $projectPath --script res://tests/drive_course.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path $projectPath --script res://tests/npc_race.gd
exit $LASTEXITCODE
