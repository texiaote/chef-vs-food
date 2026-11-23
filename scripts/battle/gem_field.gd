class_name GemField
extends Node2D

const GEM_SCENE := preload("res://scenes/xp_gem.tscn")

var live: Array[XpGem] = []
var pool: Array[XpGem] = []
var battle = null


func spawn(pos: Vector2, value: int) -> void:
	var gem := _acquire()
	gem.activate(pos + Vector2(randf_range(-3, 3), randf_range(-3, 3)), value)


func tick(delta: float, chef_pos: Vector2, magnet: float, attract: float, collect_dist: float) -> void:
	if battle == null:
		return
	var i := live.size() - 1
	while i >= 0:
		var gem := live[i]
		if not gem.alive:
			_release_at(i)
			i -= 1
			continue
		var offset: Vector2 = chef_pos - gem.global_position
		var dist := offset.length()
		if dist <= collect_dist:
			battle.add_xp(gem.value)
			_release_at(i)
			if battle.level_up_open:
				break
			i -= 1
			continue
		if dist <= magnet and dist > 0.001:
			var pull := attract * (1.0 + (1.0 - dist / magnet) * 2.4)
			gem.global_position += offset / dist * pull * delta
		gem.tick_visual(delta)
		if battle.level_up_open:
			break
		i -= 1


func _acquire() -> XpGem:
	var gem: XpGem
	if pool.is_empty():
		gem = GEM_SCENE.instantiate()
		add_child(gem)
	else:
		gem = pool.pop_back()
	live.append(gem)
	return gem


func _release_at(index: int) -> void:
	var gem := live[index]
	live.remove_at(index)
	gem.deactivate()
	pool.append(gem)
