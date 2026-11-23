extends Node

## Unlock-only meta progression. No stat carryover between runs.
## Before the first cake kill, every run starts with Flying Knife.
## After it, the chosen start weapon is persisted.

const DEFAULT_PATH := "user://save.cfg"
const WEAPON_IDS: PackedStringArray = [
	"flying_knife",
	"spatula",
	"frying_pan",
	"pepper_shaker",
	"rolling_pin",
]

var path: String = DEFAULT_PATH
var cake_unlocked: bool = false
var start_weapon: String = "flying_knife"


func _ready() -> void:
	load_game()


func load_game() -> void:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		cake_unlocked = false
		start_weapon = "flying_knife"
		return
	cake_unlocked = bool(config.get_value("meta", "cake_unlocked", false))
	start_weapon = str(config.get_value("meta", "start_weapon", "flying_knife"))
	if not WEAPON_IDS.has(start_weapon):
		start_weapon = "flying_knife"


func save_game() -> int:
	var config := ConfigFile.new()
	config.set_value("meta", "cake_unlocked", cake_unlocked)
	config.set_value("meta", "start_weapon", start_weapon)
	var err := config.save(path)
	if err != OK:
		push_error("Save failed for %s (%s)" % [path, err])
	return err


func mark_cake_defeated() -> void:
	cake_unlocked = true
	save_game()


func set_start_weapon(id: String) -> void:
	if not cake_unlocked:
		return
	if not WEAPON_IDS.has(id):
		return
	start_weapon = id
	save_game()


func starting_weapon_id() -> String:
	if not cake_unlocked:
		return "flying_knife"
	if WEAPON_IDS.has(start_weapon):
		return start_weapon
	return "flying_knife"


func reset_for_tests(temp_path: String) -> void:
	path = temp_path
	cake_unlocked = false
	start_weapon = "flying_knife"
	var absolute := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(absolute)
	save_game()
