class_name WeaponData
extends Resource

## One attack pattern. Per-level arrays are the tuning surface.
##
## knife:   counts = shots, extras = pierce
## spatula: areas = arc degrees, extras = reach px
## orbit:   counts = pans, areas = hit radius, extras = orbit radius,
##          cooldowns = per-target hit interval
## cloud:   counts = clouds per cast, areas = drop distance, extras = cloud radius
## bounce:  counts = pins per cast, extras = enemies hit per pin, areas = hit radius

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var texture: Texture2D
@export var effect_texture: Texture2D
@export var pattern: String = "knife"
@export var max_level: int = 5
@export var damages: PackedFloat32Array = PackedFloat32Array()
@export var cooldowns: PackedFloat32Array = PackedFloat32Array()
@export var counts: PackedInt32Array = PackedInt32Array()
@export var areas: PackedFloat32Array = PackedFloat32Array()
@export var extras: PackedFloat32Array = PackedFloat32Array()
@export var projectile_speed: float = 260.0
@export var duration: float = 2.5
@export var tick_rate: float = 0.4
@export var orbit_speed: float = 2.4
@export var chain_range: float = 180.0
@export var tint: Color = Color.WHITE


func damage_at(level: int) -> float:
	return _float_at(damages, level, 10.0)


func cooldown_at(level: int) -> float:
	return _float_at(cooldowns, level, 1.0)


func count_at(level: int) -> int:
	if counts.is_empty():
		return 1
	return int(counts[clampi(level - 1, 0, counts.size() - 1)])


func area_at(level: int) -> float:
	return _float_at(areas, level, 24.0)


func extra_at(level: int) -> float:
	return _float_at(extras, level, 1.0)


func _float_at(arr: PackedFloat32Array, level: int, fallback: float) -> float:
	if arr.is_empty():
		return fallback
	return float(arr[clampi(level - 1, 0, arr.size() - 1)])
