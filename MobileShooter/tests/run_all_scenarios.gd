extends Node

## Automated gameplay scenario runner — exercises all 20 levels and edge cases.

var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("\n========== MobileShooter Scenario Tests ==========\n")
	await get_tree().create_timer(0.8).timeout

	await _scenario_all_levels_normal()
	await _scenario_level6_coin_continue()
	await _scenario_escape_during_game_over()
	await _scenario_pause_resume()
	await _scenario_boss_levels()
	await _scenario_full_campaign_to_level_20()

	_print_summary()
	get_tree().quit(0 if _failed == 0 else 1)


func _scenario_all_levels_normal() -> void:
	print("--- Scenario: Normal level completion (levels 1-3) ---")
	_reset_run()
	for level in [1, 2, 3]:
		await _wait_level_start(level)
		await _complete_current_level()
		if GameManager.current_level == level and not GameManager.level_active:
			_pass("Level %d completed" % level)
		else:
			_fail("Level %d completed" % level, "state level=%d active=%s" % [
				GameManager.current_level, GameManager.level_active
			])
		if level < 3:
			GameManager.set_paused(false)
			GameManager.advance_to_next_level()
			await get_tree().create_timer(0.1).timeout


func _scenario_level6_coin_continue() -> void:
	print("--- Scenario: Level 6 death + coin continue + finish ---")
	_reset_run()
	GameManager.add_coins(100)
	await _jump_to_level(6)
	await _wait_level_start(6)

	var required := GameManager.enemies_required_this_level
	for i in required - 1:
		GameManager.on_enemy_killed()
	await get_tree().create_timer(0.05).timeout

	GameManager.lives = 1
	GameManager.lose_life()
	if not GameManager.is_game_over:
		_fail("Level 6 game over", "expected is_game_over")
	else:
		_pass("Level 6 game over triggered")

	GameManager.add_coins(50)
	if not GameManager.spend_coins(20):
		_fail("Spend coins continue", "not enough coins")
	else:
		_pass("Spend 20 coins for continue")

	GameManager.resume_after_continue()
	await get_tree().create_timer(0.15).timeout

	if GameManager.is_game_over:
		_fail("After continue", "still game over")
	else:
		_pass("Resumed after continue")

	GameManager.on_enemy_killed()
	await get_tree().create_timer(0.15).timeout

	if not GameManager.level_active and GameManager.enemies_killed_this_level >= required:
		_pass("Level 6 finished after continue")
	else:
		_fail("Level 6 finish after continue", "killed=%d/%d active=%s" % [
			GameManager.enemies_killed_this_level, required, GameManager.level_active
		])

	GameManager.set_paused(false)
	GameManager.advance_to_next_level()
	await get_tree().create_timer(0.1).timeout
	if GameManager.current_level == 7:
		_pass("Advanced to level 7 after continue scenario")
	else:
		_fail("Advance to level 7", "at level %d" % GameManager.current_level)


func _scenario_escape_during_game_over() -> void:
	print("--- Scenario: Enemy escape counted during game over ---")
	_reset_run()
	await _jump_to_level(6)
	await _wait_level_start(6)

	var required := GameManager.enemies_required_this_level
	for i in required - 1:
		GameManager.on_enemy_killed()

	GameManager.lives = 1
	GameManager.lose_life()
	GameManager.on_enemy_escaped()
	await get_tree().create_timer(0.05).timeout

	if GameManager.enemies_killed_this_level < required:
		_fail("Escape during game over", "progress %d/%d" % [
			GameManager.enemies_killed_this_level, required
		])
	else:
		_pass("Escape counted during game over (%d/%d)" % [
			GameManager.enemies_killed_this_level, required
		])

	GameManager.resume_after_continue()
	await get_tree().create_timer(0.15).timeout

	if not GameManager.level_active and GameManager.enemies_killed_this_level >= required:
		_pass("Level auto-completed on continue after escape")
	else:
		_fail("Auto-complete on continue", "active=%s killed=%d/%d" % [
			GameManager.level_active,
			GameManager.enemies_killed_this_level,
			required,
		])


func _scenario_pause_resume() -> void:
	print("--- Scenario: Pause and resume mid-level ---")
	_reset_run()
	await _jump_to_level(4)
	await _wait_level_start(4)

	GameManager.toggle_pause()
	await get_tree().create_timer(0.05).timeout
	if not GameManager.is_paused:
		_fail("Pause", "is_paused false")
	else:
		_pass("Game paused")

	GameManager.set_paused(false)
	await get_tree().create_timer(0.05).timeout
	if GameManager.is_paused:
		_fail("Resume", "still paused")
	else:
		_pass("Game resumed")

	await _complete_current_level()
	if not GameManager.level_active:
		_pass("Level 4 completed after pause/resume")
	else:
		_fail("Level 4 after pause", "still active")


func _scenario_boss_levels() -> void:
	print("--- Scenario: Boss levels (5, 10, 15, 20) ---")
	for boss_level in [5, 10, 15, 20]:
		_reset_run()
		await _jump_to_level(boss_level)
		await _wait_level_start(boss_level)
		var data := LevelData.get_level(boss_level)
		if not data["boss"]:
			_fail("Boss level %d data" % boss_level, "boss flag false")
			continue
		_pass("Boss level %d started (hp=%d)" % [boss_level, data["boss_hp"]])
		await _complete_current_level()
		if not GameManager.level_active:
			_pass("Boss level %d completed" % boss_level)
		else:
			_fail("Boss level %d complete" % boss_level, "still active")


func _scenario_full_campaign_to_level_20() -> void:
	print("--- Scenario: Full campaign levels 1 → 20 ---")
	_reset_run()
	GameManager.start_level(1)
	await _wait_level_start(1)

	var completed := 0
	while GameManager.current_level <= LevelData.MAX_LEVEL:
		var level := GameManager.current_level
		await _complete_current_level()
		await get_tree().create_timer(0.05).timeout
		if GameManager.level_active:
			_fail("Campaign level %d" % level, "did not complete")
			break
		completed += 1
		if level >= LevelData.MAX_LEVEL:
			break
		GameManager.set_paused(false)
		GameManager.advance_to_next_level()
		await _wait_level_start(level + 1)

	if completed == LevelData.MAX_LEVEL:
		_pass("All %d levels completed in full campaign" % LevelData.MAX_LEVEL)
	else:
		_fail("Full campaign", "only completed %d levels" % completed)

	GameManager.advance_to_next_level()
	await get_tree().create_timer(0.1).timeout
	if GameManager.current_level == LevelData.MAX_LEVEL:
		_pass("Reached max level cap correctly")
	else:
		_fail("Max level cap", "level=%d" % GameManager.current_level)


func _reset_run() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	GameManager.start_level(1)
	await get_tree().create_timer(0.1).timeout


func _jump_to_level(level: int) -> void:
	get_tree().paused = false
	GameManager.reset_game()
	GameManager.start_level(level)
	await get_tree().create_timer(0.15).timeout


func _wait_level_start(expected: int) -> void:
	var tries := 0
	while GameManager.current_level != expected and tries < 30:
		await get_tree().create_timer(0.05).timeout
		tries += 1
	if not GameManager.level_active:
		await get_tree().create_timer(0.05).timeout


func _complete_current_level() -> void:
	var needed := GameManager.enemies_required_this_level - GameManager.enemies_killed_this_level
	for i in needed:
		GameManager.on_enemy_killed()
	await get_tree().create_timer(0.1).timeout


func _pass(name: String) -> void:
	_passed += 1
	print("  [PASS] ", name)


func _fail(name: String, detail: String) -> void:
	_failed += 1
	push_error("[FAIL] %s — %s" % [name, detail])
	print("  [FAIL] ", name, " — ", detail)


func _print_summary() -> void:
	print("\n========== Results: %d passed, %d failed ==========\n" % [_passed, _failed])
