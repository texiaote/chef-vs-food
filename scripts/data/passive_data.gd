class_name PassiveData
extends Resource

## stat is one of: max_hp, move_speed, pickup_radius, damage, cooldown.
## per_level is a flat amount for max_hp and pickup_radius, and a fraction
## (0.10 = +10%) for move_speed, damage, and cooldown reduction.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var stat: String = "damage"
@export var per_level: float = 0.1
@export var max_level: int = 5
@export var texture: Texture2D
