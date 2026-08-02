param(
    [string]$GodotPath = $env:GODOT_BIN,
    [switch]$Full
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -eq $command) { throw 'Set GODOT_BIN or pass -GodotPath to a Godot executable.' }
    $GodotPath = $command.Source
}

& $GodotPath --headless --path . --editor --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_runtime_foundation.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_game_session.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_command_flow.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_data_registry.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_scene_ui_flow.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_platform_foundation.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $GodotPath --headless --path . --script res://Tools/validate_sandbox_status.gd
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ($Full) {
	& $GodotPath --headless --path . --script res://Tools/run_tests.gd
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
