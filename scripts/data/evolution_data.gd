class_name EvolutionData
extends Resource

## Offered on the next level-up once weapon_id is max level and passive_id is owned.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var weapon_id: String = ""
@export var passive_id: String = ""
@export var pattern: String = ""
@export var texture: Texture2D
@export var damage_multiplier: float = 1.0
@export var radius_multiplier: float = 1.0
@export var count: int = 12
@export var burn_dps: float = 0.0
@export var burn_duration: float = 0.0
