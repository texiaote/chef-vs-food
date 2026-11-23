class_name Projectile
extends Node2D

var vel: Vector2 = Vector2.ZERO
var speed: float = 200.0
var damage: float = 1.0
var ttl: float = 1.0
var radius: float = 6.0
var pierce: int = 1
var bounces: int = 0
var chain_range: float = 160.0
var burn_dps: float = 0.0
var burn_time: float = 0.0
var alive: bool = false
var hostile: bool = false
var kind: String = "knife"
var hits: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite


func launch(params: Dictionary) -> void:
	alive = true
	visible = true
	global_position = params.get("pos", Vector2.ZERO)
	vel = params.get("vel", Vector2.RIGHT)
	speed = maxf(vel.length(), 1.0)
	damage = float(params.get("damage", 1.0))
	ttl = float(params.get("ttl", 1.2))
	radius = float(params.get("radius", 6.0))
	pierce = int(params.get("pierce", 1))
	bounces = int(params.get("bounces", 0))
	chain_range = float(params.get("chain_range", 160.0))
	burn_dps = float(params.get("burn_dps", 0.0))
	burn_time = float(params.get("burn_time", 0.0))
	hostile = bool(params.get("hostile", false))
	kind = str(params.get("kind", "knife"))
	hits = {}
	var tex: Texture2D = params.get("texture")
	if tex != null:
		sprite.texture = tex
	sprite.modulate = params.get("tint", Color.WHITE)
	var scl := float(params.get("scale", 0.65))
	sprite.scale = Vector2(scl, scl)
	rotation = vel.angle()


func deactivate() -> void:
	alive = false
	visible = false
	hits.clear()
