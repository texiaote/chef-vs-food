class_name BalanceData
extends Resource

## All starting numbers that playtests are expected to retune live here.

@export var player_max_hp: float = 100.0
@export var player_speed: float = 100.0
@export var player_radius: float = 12.0
@export var invuln_duration: float = 0.55
@export var base_pickup_radius: float = 52.0
@export var gem_attract_speed: float = 280.0
@export var gem_collect_distance: float = 12.0
@export var enemy_cap: int = 300
@export var win_time: float = 600.0
@export var boss_time: float = 480.0
@export var boss_id: String = "cake"
@export var spawn_margin: float = 28.0
@export var leash_distance: float = 920.0
@export var separation_scale: float = 0.82
@export var xp_base: float = 12.0
@export var xp_exponent: float = 1.28
@export var contact_damage_min: float = 5.0
@export var contact_damage_max: float = 10.0
## Spawn interval in seconds at each whole minute (index 0 = 0:00). Lerped between minutes.
@export var spawn_interval_at_minute: PackedFloat32Array = PackedFloat32Array()
@export var spawn_ids: PackedStringArray = PackedStringArray()
@export var spawn_from: PackedFloat32Array = PackedFloat32Array()
@export var spawn_weight: PackedFloat32Array = PackedFloat32Array()


func xp_to_next(level: int) -> int:
	var lvl := maxi(level, 1)
	return maxi(1, int(round(xp_base * pow(float(lvl), xp_exponent))))


func spawn_interval(time_sec: float) -> float:
	var arr := spawn_interval_at_minute
	if arr.is_empty():
		return 0.25
	if arr.size() == 1:
		return float(arr[0])
	var minutes := time_sec / 60.0
	var i := int(floor(minutes))
	if i < 0:
		return float(arr[0])
	if i >= arr.size() - 1:
		return float(arr[arr.size() - 1])
	var f := minutes - float(i)
	return lerpf(float(arr[i]), float(arr[i + 1]), f)


func pick_enemy_id(time_sec: float) -> String:
	var total := 0.0
	for i in spawn_ids.size():
		if i < spawn_from.size() and time_sec + 0.001 >= float(spawn_from[i]):
			var w := float(spawn_weight[i]) if i < spawn_weight.size() else 0.0
			total += w
	if total <= 0.0:
		return "broccoli" if spawn_ids.is_empty() else String(spawn_ids[0])
	var roll := randf() * total
	for i in spawn_ids.size():
		if i < spawn_from.size() and time_sec + 0.001 >= float(spawn_from[i]):
			var w := float(spawn_weight[i]) if i < spawn_weight.size() else 0.0
			roll -= w
			if roll <= 0.0:
				return String(spawn_ids[i])
	return String(spawn_ids[spawn_ids.size() - 1])
