extends Node

const MENU_SCENE := "res://scenes/main_menu.tscn"
const BATTLE_SCENE := "res://scenes/battle.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

const WEAPON_ORDER: PackedStringArray = [
	"flying_knife",
	"spatula",
	"frying_pan",
	"pepper_shaker",
	"rolling_pin",
]
const PASSIVE_ORDER: PackedStringArray = [
	"apron",
	"sneakers",
	"big_ladle",
	"secret_sauce",
	"kitchen_timer",
]

var balance: BalanceData
var weapons: Dictionary = {}
var passives: Dictionary = {}
var evolutions: Array[EvolutionData] = []
var enemies: Dictionary = {}
var catalog_ready: bool = false

var auto_play: bool = false
var auto_chooser: Callable = Callable()
var auto_steer: Callable = Callable()
var last_result: Dictionary = {}


func _ready() -> void:
	_setup_input()
	load_catalog()


func load_catalog() -> void:
	weapons.clear()
	passives.clear()
	evolutions.clear()
	enemies.clear()
	catalog_ready = false
	if not ResourceLoader.exists("res://data/balance.tres"):
		push_warning("data/balance.tres is missing; run tools/build_data.tscn")
		return
	var loaded_balance = load("res://data/balance.tres")
	if not loaded_balance is BalanceData:
		push_error("balance.tres is not BalanceData")
		return
	balance = loaded_balance
	for res in _load_dir("res://data/weapons"):
		if res is WeaponData:
			weapons[res.id] = res
	for res in _load_dir("res://data/passives"):
		if res is PassiveData:
			passives[res.id] = res
	for res in _load_dir("res://data/evolutions"):
		if res is EvolutionData:
			evolutions.append(res)
	for res in _load_dir("res://data/enemies"):
		if res is EnemyData:
			enemies[res.id] = res
	evolutions.sort_custom(func(a: EvolutionData, b: EvolutionData) -> bool: return a.id < b.id)
	catalog_ready = (
		balance != null
		and weapons.size() >= 5
		and passives.size() >= 5
		and evolutions.size() >= 2
		and enemies.size() >= 8
	)
	if not catalog_ready:
		push_error(
			"Catalog incomplete weapons=%s passives=%s evolutions=%s enemies=%s"
			% [weapons.size(), passives.size(), evolutions.size(), enemies.size()]
		)


func go_menu() -> void:
	auto_play = false
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func go_battle() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(BATTLE_SCENE)


func go_result() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file(RESULT_SCENE)


func _load_dir(dir_path: String) -> Array:
	var out: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Cannot open %s" % dir_path)
		return out
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for fname in names:
		var load_name := String(fname)
		if load_name.ends_with(".remap"):
			load_name = load_name.trim_suffix(".remap")
		if not load_name.ends_with(".tres"):
			continue
		var res = load(dir_path.path_join(load_name))
		if res != null:
			out.append(res)
	return out


func _setup_input() -> void:
	_move_action("move_left", KEY_A, KEY_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_move_action("move_right", KEY_D, KEY_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_move_action("move_up", KEY_W, KEY_UP, JOY_AXIS_LEFT_Y, -1.0)
	_move_action("move_down", KEY_S, KEY_DOWN, JOY_AXIS_LEFT_Y, 1.0)


func _move_action(action: String, key_a: Key, key_b: Key, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
	else:
		InputMap.action_set_deadzone(action, 0.25)
	if InputMap.action_get_events(action).size() > 0:
		return
	var first := InputEventKey.new()
	first.physical_keycode = key_a
	InputMap.action_add_event(action, first)
	var second := InputEventKey.new()
	second.physical_keycode = key_b
	InputMap.action_add_event(action, second)
	var stick := InputEventJoypadMotion.new()
	stick.axis = axis
	stick.axis_value = axis_value
	InputMap.action_add_event(action, stick)
