extends Node

const OUT_DIR := "/opt/cursor/artifacts"

var _busy: bool = false
var _shot_minute: bool = false
var _shot_boss: bool = false
var _closing_on_boss: bool = false
var _started_ms: int = 0


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	SaveManager.reset_for_tests("user://capture_save.cfg")
	Game.auto_play = true
	Game.auto_chooser = Callable(self, "_choose")
	Game.auto_steer = func(battle): return AutoPlayer.steer(battle, 0.12)
	seed(42)
	Engine.time_scale = 16.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var battle = load("res://scenes/battle.tscn").instantiate()
	battle.name = "Battle"
	add_child(battle)
	if battle.chef == null or battle.horde == null:
		print("CAPTURE FAIL battle failed to initialize")
		get_tree().quit(1)
		return
	_started_ms = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if _busy:
		return
	var battle := get_node_or_null("Battle")
	if battle == null or battle.balance == null:
		return
	if battle.horde.boss_spawned and not _closing_on_boss:
		_closing_on_boss = true
		Game.auto_steer = func(current):
			var boss = current.horde.boss_actor()
			if boss == null:
				return AutoPlayer.steer(current, 0.12)
			var stand: Vector2 = boss.global_position + Vector2(110, 8)
			var move: Vector2 = stand - current.chef.global_position
			if move.length() < 10.0:
				return Vector2.ZERO
			return move.normalized()
	if not _shot_minute and battle.run_time >= 60.0:
		_shot_minute = true
		_capture(OUT_DIR.path_join("gameplay_swarm_minute.png"), false)
		return
	if not _shot_boss and battle.horde.boss_spawned:
		var boss = battle.horde.boss_actor()
		if boss != null and boss.global_position.distance_to(battle.chef.global_position) < 130.0:
			_shot_boss = true
			_capture(OUT_DIR.path_join("gameplay_with_cake.png"), true)
			return
	if battle.finished or battle.run_time > 560.0 or Time.get_ticks_msec() - _started_ms > 400000:
		if not _shot_boss:
			print("CAPTURE missed boss t=", battle.run_time, " spawned=", battle.horde.boss_spawned)
			_shot_boss = true
			_capture(OUT_DIR.path_join("gameplay_with_cake.png"), true)
		else:
			get_tree().quit(0)


func _capture(path: String, quit_after: bool) -> void:
	_busy = true
	var battle := get_node("Battle")
	battle.set_process(false)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image.get_width() > 0 and image.get_width() < 1000:
		image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	var err := image.save_png(path)
	print(
		"CAPTURE %s %dx%d err=%s t=%.1f level=%s kills=%s enemies=%s hp=%.0f"
		% [path, image.get_width(), image.get_height(), err, battle.run_time, battle.level, battle.kills, battle.horde.active_count(), battle.chef.hp]
	)
	if quit_after:
		get_tree().quit(0)
		return
	battle.set_process(true)
	_busy = false


func _choose(choices: Array) -> int:
	var best := 0
	var best_score := -999
	for i in choices.size():
		var score := 10
		if str(choices[i].get("kind", "")) == "evolution":
			score = 100
		else:
			match str(choices[i].get("id", "")):
				"frying_pan":
					score = 90
				"kitchen_timer":
					score = 86
				"apron":
					score = 80
				"spatula":
					score = 74
				"secret_sauce":
					score = 70
				"flying_knife":
					score = 66
				"rolling_pin":
					score = 60
				"pepper_shaker":
					score = 58
				"sneakers":
					score = 40
				"big_ladle":
					score = 36
		if score > best_score:
			best_score = score
			best = i
	return best
