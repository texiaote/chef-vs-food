class_name PepperCloud
extends Node2D

var radius: float = 28.0
var ttl: float = 2.0
var tick_rate: float = 0.4
var tick_acc: float = 0.0
var damage: float = 1.0
var alive: bool = false

@onready var sprite: Sprite2D = $Sprite


func activate(pos: Vector2, cloud_radius: float, duration: float, rate: float, dps_tick: float, tex: Texture2D) -> void:
	global_position = pos
	radius = cloud_radius
	ttl = duration
	tick_rate = maxf(rate, 0.05)
	tick_acc = tick_rate * 0.5
	damage = dps_tick
	alive = true
	visible = true
	z_as_relative = false
	z_index = 7
	if tex != null:
		sprite.texture = tex
	var tex_size := 32.0
	if sprite.texture != null:
		tex_size = maxf(float(sprite.texture.get_width()), 1.0)
	var scl := (radius * 2.2) / tex_size
	sprite.scale = Vector2(scl, scl)
	sprite.modulate = Color(1, 1, 1, 0.8)
	queue_redraw()


func deactivate() -> void:
	alive = false
	visible = false


func _draw() -> void:
	if not alive:
		return
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.42, 0.22, 0.18))
