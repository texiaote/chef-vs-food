class_name Chef
extends Node2D

signal died

var hp: float = 100.0
var max_hp: float = 100.0
var radius: float = 12.0
var base_speed: float = 100.0
var speed_mult: float = 1.0
var slow_mult: float = 1.0
var facing: Vector2 = Vector2.RIGHT
var move_dir: Vector2 = Vector2.ZERO
var invuln: float = 0.0
var use_external: bool = false
var external_dir: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func setup(balance: BalanceData) -> void:
	max_hp = balance.player_max_hp
	hp = max_hp
	radius = balance.player_radius
	base_speed = balance.player_speed
	invuln = 0.0
	facing = Vector2.RIGHT
	queue_redraw()


func tick(delta: float) -> void:
	var direction := external_dir if use_external else Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length() > 1.0:
		direction = direction.normalized()
	move_dir = direction
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	global_position += direction * base_speed * speed_mult * slow_mult * delta
	if invuln > 0.0:
		invuln = maxf(0.0, invuln - delta)
		sprite.modulate.a = 0.4 if fmod(invuln, 0.12) < 0.06 else 1.0
	else:
		sprite.modulate.a = 1.0
	queue_redraw()


func hurt(amount: float, invuln_time: float) -> void:
	if invuln > 0.0 or amount <= 0.0 or hp <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	invuln = invuln_time
	AudioManager.play("player_hurt")
	queue_redraw()
	if hp <= 0.0:
		died.emit()


func _draw() -> void:
	var width := 34.0
	var y := 26.0
	draw_rect(Rect2(-width * 0.5, y, width, 5.0), Color(0.12, 0.04, 0.04, 0.95))
	var ratio := 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5, y, width * ratio, 5.0), Color(0.9, 0.16, 0.14, 1.0))
