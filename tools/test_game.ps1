param([Parameter(Mandatory=$true)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectPath = Join-Path $PSScriptRoot '..\godot'
& $GodotPath --headless --path $projectPath --editor --import --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
foreach ($suite in @('race_smoke', 'contact_test')) {
    & $GodotPath --headless --path $projectPath --script "res://tests/$suite.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
foreach ($course in 0..2) {
    foreach ($suite in @('drive_course', 'npc_race')) {
        & $GodotPath --headless --path $projectPath --script "res://tests/$suite.gd" -- "--course=$course"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}
exit 0
