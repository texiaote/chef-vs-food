class_name XpGem
extends Node2D

var value: int = 1
var alive: bool = false
var bob: float = 0.0

@onready var sprite: Sprite2D = $Sprite


func activate(pos: Vector2, gem_value: int) -> void:
	global_position = pos
	value = maxi(gem_value, 1)
	alive = true
	visible = true
	bob = randf() * TAU
	var scl := clampf(0.85 + 0.18 * log(float(value)), 0.85, 2.1)
	sprite.scale = Vector2(scl, scl)
	sprite.position = Vector2.ZERO


func deactivate() -> void:
	alive = false
	visible = false


func tick_visual(delta: float) -> void:
	bob += delta * 5.0
	sprite.position.y = sin(bob) * 1.4
