class_name SwingFx
extends Node2D

var arc_deg: float = 90.0
var reach: float = 48.0
var life: float = 0.0
var facing: Vector2 = Vector2.RIGHT


func trigger(face: Vector2, arc: float, distance: float) -> void:
	facing = face if face.length_squared() > 0.01 else Vector2.RIGHT
	arc_deg = arc
	reach = distance
	life = 0.12
	visible = true
	queue_redraw()


func tick(delta: float) -> void:
	if life <= 0.0:
		visible = false
		return
	life -= delta
	queue_redraw()


func _draw() -> void:
	if life <= 0.0:
		return
	var angle := facing.angle()
	var half := deg_to_rad(arc_deg) * 0.5
	var alpha := clampf(life / 0.12, 0.0, 1.0)
	draw_arc(Vector2.ZERO, reach * 0.72, angle - half, angle + half, 14, Color(0.9, 0.92, 0.96, 0.55 * alpha), 5.0)
	draw_arc(Vector2.ZERO, reach, angle - half, angle + half, 14, Color(1, 1, 1, 0.35 * alpha), 2.0)
