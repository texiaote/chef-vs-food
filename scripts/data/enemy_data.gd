class_name EnemyData
extends Resource

## behavior: chase, split, ranged, boss.
## split_id / summon_id name other enemy resources. contact_damage stays in the 5-10 band.

@export var id: String = ""
@export var display_name: String = ""
@export var texture: Texture2D
@export var max_hp: float = 10.0
@export var speed: float = 30.0
@export var contact_damage: float = 6.0
@export var xp: int = 1
@export var radius: float = 12.0
@export var behavior: String = "chase"
@export var is_boss: bool = false
@export var split_id: String = ""
@export var split_count: int = 0
@export var preferred_range: float = 150.0
@export var range_band: float = 28.0
@export var shoot_cooldown: float = 2.0
@export var projectile_speed: float = 110.0
@export var projectile_damage: float = 8.0
@export var projectile_texture: Texture2D
@export var summon_id: String = ""
@export var summon_count: int = 0
@export var summon_cooldown: float = 5.0
@export var slam_cooldown: float = 4.5
@export var slam_radius: float = 72.0
@export var slam_duration: float = 2.6
@export var slam_slow: float = 0.5
@export var slam_windup: float = 0.45
