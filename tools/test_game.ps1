param([Parameter(Mandatory=$true)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectPath = Join-Path $PSScriptRoot '..\godot'
& $GodotPath --headless --path $projectPath --editor --import --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
foreach ($suite in @('race_smoke', 'contact_test', 'duel_test', 'item_test', 'scenery_test', 'hazard_test', 'solo_results_test')) {
    & $GodotPath --headless --path $projectPath --fixed-fps 60 --script "res://tests/$suite.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
foreach ($course in 0..3) {
    foreach ($suite in @('drive_course', 'npc_race', 'duel_drive')) {
        & $GodotPath --headless --path $projectPath --fixed-fps 60 --script "res://tests/$suite.gd" -- "--course=$course"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}
exit 0
