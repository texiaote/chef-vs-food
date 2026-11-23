class_name CreamRing
extends Node2D

var radius: float = 70.0
var ttl: float = 2.5
var delay: float = 0.45
var slow: float = 0.5
var alive: bool = false


func activate(pos: Vector2, ring_radius: float, duration: float, slow_factor: float, windup: float) -> void:
	global_position = pos
	radius = ring_radius
	ttl = duration
	slow = slow_factor
	delay = windup
	alive = true
	visible = true
	z_as_relative = false
	z_index = 6
	queue_redraw()


func deactivate() -> void:
	alive = false
	visible = false


func tick(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
	else:
		ttl -= delta
	queue_redraw()


func slows_at(pos: Vector2) -> bool:
	return alive and delay <= 0.0 and ttl > 0.0 and global_position.distance_to(pos) <= radius


func _draw() -> void:
	if not alive:
		return
	var warning := delay > 0.0
	var shown := radius * (0.72 if warning else 1.0)
	var fill := Color(1.0, 0.82, 0.35, 0.22) if warning else Color(1.0, 0.98, 0.92, 0.22)
	draw_circle(Vector2.ZERO, shown, fill)
	draw_arc(Vector2.ZERO, shown, 0.0, TAU, 36, Color(1, 1, 1, 0.75), 2.0)
