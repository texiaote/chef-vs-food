extends Node2D

const STEP := 1.0 / 60.0
const MAX_STEPS := 90

var balance: BalanceData
var run_time: float = 0.0
var level: int = 1
var xp: int = 0
var total_xp: int = 0
var kills: int = 0
var level_ups: int = 0
var evolutions_taken: int = 0
var cake_killed: bool = false
var cake_announced: bool = false
var finished: bool = false
var victory: bool = false
var level_up_open: bool = false
var passive_levels: Dictionary = {}
var current_choices: Array = []

var _acc: float = 0.0
var _logged_minute: int = -1

@onready var ground: Sprite2D = $Ground
@onready var gems: GemField = $Gems
@onready var horde: Horde = $World
@onready var chef: Chef = $Chef
@onready var arsenal: Arsenal = $Arsenal
@onready var camera: Camera2D = $Camera
@onready var hud: Hud = $HUD
@onready var level_ui: LevelUpUI = $LevelUp


func _ready() -> void:
	if not Game.auto_play:
		randomize()
	if not Game.catalog_ready:
		push_error("Battle started without a complete data catalog")
		finished = true
		return
	balance = Game.balance
	gems.battle = self
	horde.battle = self
	arsenal.battle = self
	arsenal.horde = horde
	horde.setup(balance.enemy_cap)
	chef.setup(balance)
	chef.died.connect(_on_chef_died)
	gems.z_index = 4
	horde.z_index = 10
	chef.z_index = 40
	arsenal.z_index = 30
	_apply_passives()
	var start_id := SaveManager.starting_weapon_id()
	var start_weapon: WeaponData = Game.weapons.get(start_id)
	if start_weapon == null:
		start_weapon = Game.weapons.get("flying_knife")
	arsenal.add_weapon(start_weapon)
	camera.make_current()
	camera.position_smoothing_enabled = false
	level_ui.picked.connect(_on_level_picked)
	level_ui.dismiss()
	_sync_camera()


func _process(delta: float) -> void:
	if finished or level_up_open or balance == null:
		_sync_camera()
		return
	_acc += delta
	var budget := STEP * float(MAX_STEPS)
	if _acc > budget:
		_acc = budget
	var steps := 0
	while _acc >= STEP and steps < MAX_STEPS:
		_simulate(STEP)
		_acc -= STEP
		steps += 1
		if finished or level_up_open:
			_acc = 0.0
			break
	_sync_camera()
	_log_pace()


func _simulate(delta: float) -> void:
	run_time += delta
	if run_time >= balance.win_time:
		_finish(true)
		return
	horde.player_pos = chef.global_position
	if Game.auto_play and Game.auto_steer.is_valid():
		chef.use_external = true
		chef.external_dir = Game.auto_steer.call(self)
	chef.slow_mult = arsenal.slow_at(chef.global_position)
	chef.tick(delta)
	if finished:
		return
	horde.player_pos = chef.global_position
	horde.tick_spawn(delta, run_time)
	horde.tick_ai(delta, chef.global_position)
	horde.separate()
	horde.build_hash()
	arsenal.tick(delta)
	if finished:
		return
	horde.apply_contact(chef, balance.invuln_duration)
	if finished:
		return
	horde.tick_attacks(delta, chef.global_position, arsenal)
	horde.leash(chef.global_position)
	horde.sweep()
	if finished:
		return
	gems.tick(delta, chef.global_position, pickup_radius(), balance.gem_attract_speed, balance.gem_collect_distance)


func add_xp(amount: int) -> void:
	if finished or amount <= 0:
		return
	xp += amount
	total_xp += amount
	AudioManager.play("xp_pickup")
	_consume_levels()


func _consume_levels() -> void:
	if balance == null:
		return
	while not finished and not level_up_open and xp >= balance.xp_to_next(level):
		xp -= balance.xp_to_next(level)
		level += 1
		level_ups += 1
		_open_level_up()


func _open_level_up() -> void:
	current_choices = _roll_choices()
	level_ui.present(current_choices)
	AudioManager.play("level_up")
	if Game.auto_play:
		var index := 0
		if Game.auto_chooser.is_valid():
			index = int(Game.auto_chooser.call(current_choices))
		index = clampi(index, 0, current_choices.size() - 1)
		level_ui.dismiss()
		_apply_choice(current_choices[index])
		return
	level_up_open = true
	get_tree().paused = true


func _on_level_picked(index: int) -> void:
	if not level_up_open:
		return
	level_up_open = false
	get_tree().paused = false
	level_ui.dismiss()
	if index >= 0 and index < current_choices.size():
		_apply_choice(current_choices[index])
	AudioManager.play("ui_confirm")
	_consume_levels()


func _apply_choice(choice: Dictionary) -> void:
	var kind := str(choice.get("kind", ""))
	var id := str(choice.get("id", ""))
	match kind:
		"new_weapon":
			arsenal.add_weapon(Game.weapons.get(id))
		"upgrade_weapon":
			arsenal.upgrade(id)
		"new_passive", "upgrade_passive":
			passive_levels[id] = int(passive_levels.get(id, 0)) + 1
			_apply_passives()
		"evolution":
			var evo := _find_evolution(id)
			if evo != null:
				arsenal.evolve(evo)
				evolutions_taken += 1
				AudioManager.play("evolution")
		"heal":
			chef.hp = minf(chef.max_hp, chef.hp + chef.max_hp * 0.3)
	chef.queue_redraw()


func _roll_choices() -> Array:
	var pool: Array = []
	var evos: Array = []
	for id in Game.WEAPON_ORDER:
		var data: WeaponData = Game.weapons.get(String(id))
		if data == null:
			continue
		var runtime = arsenal.find(String(id))
		if runtime == null:
			pool.append(_weapon_choice(data, 0, "new_weapon", "新武器"))
		elif not runtime.evolved and runtime.level < data.max_level:
			pool.append(_weapon_choice(data, runtime.level, "upgrade_weapon", "升级"))
	for id in Game.PASSIVE_ORDER:
		var data: PassiveData = Game.passives.get(String(id))
		if data == null:
			continue
		var current := int(passive_levels.get(String(id), 0))
		if current <= 0:
			pool.append(_passive_choice(data, 0, "new_passive", "被动"))
		elif current < data.max_level:
			pool.append(_passive_choice(data, current, "upgrade_passive", "升级"))
	for evo in Game.evolutions:
		if _can_evolve(evo):
			evos.append(_evolution_choice(evo))
	pool.shuffle()
	var picks: Array = []
	for evo_choice in evos:
		if picks.size() < 3:
			picks.append(evo_choice)
	for item in pool:
		if picks.size() >= 3:
			break
		picks.append(item)
	if picks.size() < 3:
		var gem_tex: Texture2D = load("res://assets/textures/gem.png")
		while picks.size() < 3:
			picks.append({
				"kind": "heal",
				"id": "hearty_snack",
				"title": "加餐 Hearty Snack",
				"body": "回复 30% 生命。只在升级项不足三项时出现。",
				"tag": "恢复",
				"texture": gem_tex,
			})
	picks.shuffle()
	return picks


func _can_evolve(evo: EvolutionData) -> bool:
	var runtime = arsenal.find(evo.weapon_id)
	if runtime == null or runtime.evolved:
		return false
	if runtime.level < runtime.data.max_level:
		return false
	return int(passive_levels.get(evo.passive_id, 0)) >= 1


func _weapon_choice(data: WeaponData, current_level: int, kind: String, tag: String) -> Dictionary:
	var body := data.description
	if kind == "new_weapon":
		body += "\nLv 1   伤害 %d   冷却 %.2fs" % [int(round(data.damage_at(1))), data.cooldown_at(1)]
	else:
		var nxt := current_level + 1
		body += "\nLv %d → %d\n伤害 %d → %d   冷却 %.2f → %.2fs" % [
			current_level,
			nxt,
			int(round(data.damage_at(current_level))),
			int(round(data.damage_at(nxt))),
			data.cooldown_at(current_level),
			data.cooldown_at(nxt),
		]
	return {
		"kind": kind,
		"id": data.id,
		"title": data.display_name,
		"body": body,
		"tag": tag,
		"texture": data.texture,
	}


func _passive_choice(data: PassiveData, current_level: int, kind: String, tag: String) -> Dictionary:
	var body := data.description
	if kind == "new_passive":
		body += "\nLv 1"
	else:
		body += "\nLv %d → %d" % [current_level, current_level + 1]
	return {
		"kind": kind,
		"id": data.id,
		"title": data.display_name,
		"body": body,
		"tag": tag,
		"texture": data.texture,
	}


func _evolution_choice(evo: EvolutionData) -> Dictionary:
	return {
		"kind": "evolution",
		"id": evo.id,
		"title": evo.display_name,
		"body": evo.description,
		"tag": "进化",
		"texture": evo.texture,
	}


func _find_evolution(id: String) -> EvolutionData:
	for evo in Game.evolutions:
		if evo.id == id:
			return evo
	return null


func _apply_passives() -> void:
	var apron: PassiveData = Game.passives.get("apron")
	var sneakers: PassiveData = Game.passives.get("sneakers")
	var apron_lvl := int(passive_levels.get("apron", 0))
	var hp_per := 0.0 if apron == null else apron.per_level
	var new_max := balance.player_max_hp + hp_per * float(apron_lvl)
	var delta := new_max - chef.max_hp
	chef.max_hp = new_max
	if delta > 0.0:
		chef.hp += delta
	chef.hp = minf(chef.hp, chef.max_hp)
	var speed_per := 0.0 if sneakers == null else sneakers.per_level
	chef.speed_mult = 1.0 + speed_per * float(passive_levels.get("sneakers", 0))


func damage_multiplier() -> float:
	var data: PassiveData = Game.passives.get("secret_sauce")
	var per := 0.0 if data == null else data.per_level
	return 1.0 + per * float(passive_levels.get("secret_sauce", 0))


func cooldown_multiplier() -> float:
	var data: PassiveData = Game.passives.get("kitchen_timer")
	var per := 0.0 if data == null else data.per_level
	return maxf(0.45, 1.0 - per * float(passive_levels.get("kitchen_timer", 0)))


func pickup_radius() -> float:
	var data: PassiveData = Game.passives.get("big_ladle")
	var per := 0.0 if data == null else data.per_level
	return balance.base_pickup_radius + per * float(passive_levels.get("big_ladle", 0))


func has_melee_defense() -> bool:
	return arsenal.has_pattern(["orbit", "hot_oil", "spatula"])


func register_kill(_enemy: EnemyActor) -> void:
	kills += 1
	AudioManager.play("enemy_death")


func on_boss_spawned() -> void:
	if cake_announced:
		return
	cake_announced = true
	AudioManager.play("boss_spawn")
	hud.show_banner("巨型生日蛋糕出现了！")


func on_boss_killed() -> void:
	if cake_killed:
		return
	cake_killed = true
	SaveManager.mark_cake_defeated()
	AudioManager.play("boss_death")
	hud.show_banner("巨型生日蛋糕被击败了！")


func _on_chef_died() -> void:
	_finish(false)


func _finish(did_win: bool) -> void:
	if finished:
		return
	finished = true
	victory = did_win
	level_up_open = false
	get_tree().paused = false
	AudioManager.play("win" if did_win else "lose")
	var shown_time := run_time
	if did_win:
		shown_time = minf(run_time, balance.win_time)
	Game.last_result = {
		"victory": did_win,
		"time": shown_time,
		"level": level,
		"kills": kills,
		"cake_killed": cake_killed,
	}
	if Game.auto_play:
		return
	Engine.time_scale = 1.0
	Game.go_result()


func _sync_camera() -> void:
	if chef == null or camera == null:
		return
	camera.global_position = chef.global_position.round()
	var view := get_viewport().get_visible_rect().size
	if view.x < 10.0:
		view = Vector2(640, 360)
	ground.sync_to(camera.global_position, view)


func _log_pace() -> void:
	if not Game.auto_play:
		return
	var minute := int(floor(run_time / 60.0))
	if minute == _logged_minute or minute > 10:
		return
	_logged_minute = minute
	print(
		"PACE minute=%d t=%.1f level=%d xp=%d kills=%d enemies=%d peak=%d hp=%.0f evo=%d cake=%s"
		% [
			minute,
			run_time,
			level,
			total_xp,
			kills,
			horde.active_count(),
			horde.peak_count,
			chef.hp,
			evolutions_taken,
			cake_killed,
		]
	)
