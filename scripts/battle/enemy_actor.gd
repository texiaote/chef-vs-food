class_name EnemyActor
extends Node2D

var data: EnemyData
var hp: float = 1.0
var alive: bool = false
var burn_dps: float = 0.0
var burn_left: float = 0.0
var hit_flash: float = 0.0
var shoot_cd: float = 1.0
var summon_cd: float = 3.0
var slam_cd: float = 2.0

@onready var sprite: Sprite2D = $Sprite


func activate(next: EnemyData, pos: Vector2) -> void:
	data = next
	hp = next.max_hp
	alive = true
	visible = true
	global_position = pos
	burn_dps = 0.0
	burn_left = 0.0
	hit_flash = 0.0
	shoot_cd = next.shoot_cooldown * 0.75
	summon_cd = next.summon_cooldown * 0.6
	slam_cd = 1.6
	sprite.texture = next.texture
	sprite.modulate = Color.WHITE
	sprite.scale = Vector2.ONE
	if next.is_boss:
		z_as_relative = false
		z_index = 36
	else:
		z_as_relative = true
		z_index = 0
	queue_redraw()


func deactivate() -> void:
	alive = false
	visible = false
	data = null


func receive_damage(amount: float, burn: float = 0.0, burn_time: float = 0.0) -> void:
	if not alive or amount <= 0.0:
		return
	hp -= amount
	hit_flash = 0.07
	if burn > 0.0 and burn_time > 0.0:
		burn_dps = maxf(burn_dps, burn)
		burn_left = maxf(burn_left, burn_time)
	if hp <= 0.0:
		hp = 0.0
		alive = false


func refresh_visual(delta: float) -> void:
	if not alive:
		visible = false
		return
	visible = true
	hit_flash = maxf(0.0, hit_flash - delta)
	if hit_flash > 0.0:
		sprite.modulate = Color(2.6, 2.6, 2.6)
	elif burn_left > 0.0:
		sprite.modulate = Color(1.35, 0.62, 0.32)
	else:
		sprite.modulate = Color.WHITE
	if data != null and data.is_boss:
		queue_redraw()


func _draw() -> void:
	if data == null or not data.is_boss or not alive or data.max_hp <= 0.0:
		return
	var width := 52.0
	var y := -data.radius - 12.0
	var ratio := clampf(hp / data.max_hp, 0.0, 1.0)
	draw_rect(Rect2(-width * 0.5, y, width, 5.0), Color(0.08, 0.03, 0.04, 0.9))
	draw_rect(Rect2(-width * 0.5, y, width * ratio, 5.0), Color(0.92, 0.22, 0.28, 1.0))
