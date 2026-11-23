extends Node

var _logger: SmokeLogger
var _started_ms: int = 0
var _done: bool = false
var _failed: bool = false
var _boss_marked: bool = false


func _ready() -> void:
	_logger = SmokeLogger.new()
	OS.add_logger(_logger)
	_save_roundtrip()
	if _failed:
		return
	_assert_menu_locked()
	if _failed:
		return
	Game.auto_play = true
	Game.auto_chooser = Callable(self, "_choose")
	Game.auto_steer = func(battle): return AutoPlayer.steer(battle, 0.05)
	seed(12345)
	Engine.time_scale = 40.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var battle = load("res://scenes/battle.tscn").instantiate()
	battle.name = "Battle"
	add_child(battle)
	if battle.chef == null or battle.horde == null or battle.balance == null:
		_fail("battle failed to initialize")
		return
	_started_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _done:
		return
	var battle := get_node_or_null("Battle")
	if battle == null:
		return
	if battle.balance == null:
		if battle.finished:
			_fail("catalog failed to load")
		return
	if battle.horde.boss_spawned and not _boss_marked and battle.run_time >= float(battle.balance.boss_time) + 1.5:
		battle.horde.force_kill_boss()
		_boss_marked = true
	if battle.finished:
		_evaluate(battle)
		return
	if Time.get_ticks_msec() - _started_ms > 180000:
		_fail("timeout t=%.1f level=%s hp=%.0f enemies=%s" % [battle.run_time, battle.level, battle.chef.hp, battle.horde.active_count()])


func _choose(choices: Array) -> int:
	var best := 0
	var best_score := -999
	for i in choices.size():
		var score := _score(choices[i])
		if score > best_score:
			best_score = score
			best = i
	return best


func _score(choice: Dictionary) -> int:
	if str(choice.get("kind", "")) == "evolution":
		return 100
	match str(choice.get("id", "")):
		"frying_pan":
			return 90
		"kitchen_timer":
			return 86
		"apron":
			return 80
		"spatula":
			return 74
		"secret_sauce":
			return 70
		"flying_knife":
			return 66
		"rolling_pin":
			return 60
		"pepper_shaker":
			return 58
		"sneakers":
			return 40
		"big_ladle":
			return 36
		"hearty_snack":
			return 1
	return 10


func _evaluate(battle) -> void:
	_done = true
	Engine.time_scale = 1.0
	var result: Dictionary = Game.last_result
	if not battle.victory or not bool(result.get("victory", false)):
		_fail("expected a win, hp=%.0f t=%.1f level=%s xp=%s kills=%s enemies=%s" % [battle.chef.hp, battle.run_time, battle.level, battle.total_xp, battle.kills, battle.horde.active_count()])
		return
	if float(result.get("time", 0.0)) < 600.0 - 0.05:
		_fail("win time too small: %s" % result.get("time"))
		return
	if int(battle.level_ups) < 1 or int(battle.level) <= 1:
		_fail("no level-ups")
		return
	if int(battle.kills) <= 0:
		_fail("no kills")
		return
	if not battle.horde.boss_spawned:
		_fail("boss never spawned")
		return
	if not battle.cake_killed or not bool(result.get("cake_killed", false)):
		_fail("cake was not killed")
		return
	if battle.horde.overflowed or battle.horde.peak_count > 300:
		_fail("enemy cap exceeded peak=%s" % battle.horde.peak_count)
		return
	if int(battle.evolutions_taken) < 1:
		_fail("no evolution was offered/taken, level=%s" % battle.level)
		return
	var guard := 0
	while battle.horde.active_count() < battle.horde.cap and guard < 400:
		battle.horde.spawn_enemy("broccoli", Vector2(9000, 9000))
		guard += 1
	if battle.horde.active_count() != 300:
		_fail("could not fill cap, count=%s" % battle.horde.active_count())
		return
	var rejected_before := int(battle.horde.rejected_spawns)
	if battle.horde.spawn_enemy("broccoli", Vector2(9000, 9000)):
		_fail("spawn succeeded at cap")
		return
	if int(battle.horde.rejected_spawns) <= rejected_before:
		_fail("cap rejection was not counted")
		return
	SaveManager.load_game()
	if not SaveManager.cake_unlocked:
		_fail("cake unlock did not persist")
		return
	SaveManager.set_start_weapon("rolling_pin")
	SaveManager.start_weapon = "flying_knife"
	SaveManager.load_game()
	if SaveManager.start_weapon != "rolling_pin" or SaveManager.starting_weapon_id() != "rolling_pin":
		_fail("start weapon did not persist")
		return
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	var row = menu.find_child("WeaponRow", true, false)
	if row == null or not row.visible:
		_fail("weapon select hidden after unlock")
		return
	menu.queue_free()
	var screen = load("res://scenes/result.tscn").instantiate()
	add_child(screen)
	if not str(screen.time_label.text).contains("10:00"):
		_fail("result time label: %s" % screen.time_label.text)
		return
	if not str(screen.level_label.text).contains(str(battle.level)):
		_fail("result level label")
		return
	if not str(screen.kills_label.text).contains(str(battle.kills)):
		_fail("result kills label")
		return
	if not str(screen.cake_label.text).contains("已击败"):
		_fail("result cake label: %s" % screen.cake_label.text)
		return
	if not str(screen.title_label.text).contains("胜利"):
		_fail("result title: %s" % screen.title_label.text)
		return
	if not _logger.errors.is_empty():
		_fail("runtime errors: %s" % _logger.errors.size())
		return
	print(
		"SMOKE PASS level=%d kills=%d xp=%d evo=%d peak=%d minute10_enemies_logged"
		% [battle.level, battle.kills, battle.total_xp, battle.evolutions_taken, battle.horde.peak_count]
	)
	get_tree().quit(0)


func _save_roundtrip() -> void:
	SaveManager.reset_for_tests("user://smoke_save.cfg")
	if SaveManager.cake_unlocked:
		_fail("fresh save was unlocked")
		return
	SaveManager.mark_cake_defeated()
	SaveManager.set_start_weapon("spatula")
	SaveManager.cake_unlocked = false
	SaveManager.start_weapon = "flying_knife"
	SaveManager.load_game()
	if not SaveManager.cake_unlocked or SaveManager.start_weapon != "spatula":
		_fail("save roundtrip mismatch")
		return
	if SaveManager.starting_weapon_id() != "spatula":
		_fail("starting weapon helper mismatch")
		return
	SaveManager.reset_for_tests("user://smoke_save.cfg")
	if SaveManager.cake_unlocked or SaveManager.starting_weapon_id() != "flying_knife":
		_fail("reset did not lock flying knife")
		return
	print("SMOKE save roundtrip OK")


func _assert_menu_locked() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	add_child(menu)
	var row = menu.find_child("WeaponRow", true, false)
	if row == null or row.visible:
		_fail("weapon row visible before the first cake kill")
		return
	menu.queue_free()
	print("SMOKE menu locked OK")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	print("SMOKE FAIL ", message)
	if _logger != null:
		for err in _logger.errors:
			print("SMOKE ERR ", err)
	_done = true
	get_tree().quit(1)


class SmokeLogger extends Logger:
	var errors: Array[String] = []

	func _log_message(message: String, error: bool) -> void:
		if error:
			errors.append(message)

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		errors.append("%s:%d %s %s" % [file, line, function, rationale])
