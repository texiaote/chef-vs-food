class_name Horde
extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const CELL := 48.0

var battle = null
var cap: int = 300
var active: Array[EnemyActor] = []
var pool: Array[EnemyActor] = []
var peak_count: int = 0
var overflowed: bool = false
var rejected_spawns: int = 0
var boss_spawned: bool = false
var spawn_acc: float = 0.0
var player_pos: Vector2 = Vector2.ZERO
var _cells: Dictionary = {}


func setup(enemy_cap: int) -> void:
	cap = enemy_cap
	boss_spawned = false
	peak_count = 0
	overflowed = false
	rejected_spawns = 0
	spawn_acc = 0.0


func active_count() -> int:
	return active.size()


func boss_actor() -> EnemyActor:
	for enemy in active:
		if enemy.alive and enemy.data != null and enemy.data.is_boss:
			return enemy
	return null


func nearest(origin: Vector2, skip_boss: bool = false) -> EnemyActor:
	var best: EnemyActor = null
	var best_d := INF
	for enemy in active:
		if not enemy.alive or enemy.data == null:
			continue
		if skip_boss and enemy.data.is_boss:
			continue
		var d := origin.distance_squared_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	return best


func build_hash() -> void:
	_cells.clear()
	for enemy in active:
		if not enemy.alive:
			continue
		var key := _key(enemy.global_position)
		if not _cells.has(key):
			_cells[key] = []
		_cells[key].append(enemy)


func query(pos: Vector2, radius: float) -> Array[EnemyActor]:
	var out: Array[EnemyActor] = []
	var reach := int(ceil(radius / CELL))
	var center := _key(pos)
	for y in range(center.y - reach, center.y + reach + 1):
		for x in range(center.x - reach, center.x + reach + 1):
			var bucket = _cells.get(Vector2i(x, y))
			if bucket == null:
				continue
			for enemy in bucket:
				out.append(enemy)
	return out


func tick_spawn(delta: float, time_sec: float) -> void:
	var balance: BalanceData = battle.balance
	if not boss_spawned and time_sec >= balance.boss_time:
		spawn_boss()
		battle.on_boss_spawned()
	spawn_acc += delta
	var interval := balance.spawn_interval(time_sec)
	var guard := 0
	while spawn_acc >= interval and guard < 40:
		spawn_acc -= interval
		guard += 1
		if active.size() >= cap:
			rejected_spawns += 1
			spawn_acc = 0.0
			break
		var id := balance.pick_enemy_id(time_sec)
		spawn_enemy(id, spawn_point(balance.spawn_margin))


func tick_ai(delta: float, chef_pos: Vector2) -> void:
	player_pos = chef_pos
	for enemy in active:
		if not enemy.alive or enemy.data == null:
			continue
		if enemy.burn_left > 0.0:
			enemy.hp -= enemy.burn_dps * delta
			enemy.burn_left -= delta
			if enemy.hp <= 0.0:
				enemy.alive = false
				continue
		var to := chef_pos - enemy.global_position
		var dist := to.length()
		var dir := Vector2.RIGHT if dist < 0.001 else to / dist
		if enemy.data.behavior == "ranged":
			var preferred := enemy.data.preferred_range
			var band := enemy.data.range_band
			if dist < preferred - band:
				dir = -dir
			elif dist <= preferred + band:
				dir = dir.rotated(PI * 0.5 if int(enemy.get_instance_id()) % 2 == 0 else -PI * 0.5)
		enemy.global_position += dir * enemy.data.speed * delta
		enemy.refresh_visual(delta)


func separate() -> void:
	build_hash()
	var balance: BalanceData = battle.balance
	for enemy in active:
		if not enemy.alive or enemy.data == null or enemy.data.is_boss:
			continue
		var nearby: Array = query(enemy.global_position, enemy.data.radius + 18.0)
		for other in nearby:
			if other == enemy or not other.alive or other.data == null:
				continue
			if other.get_instance_id() <= enemy.get_instance_id() and not other.data.is_boss:
				continue
			var delta: Vector2 = enemy.global_position - other.global_position
			var dist := delta.length()
			var min_d: float = (enemy.data.radius + other.data.radius) * balance.separation_scale
			if dist < 0.001:
				delta = Vector2.RIGHT
				dist = 0.001
			if dist >= min_d:
				continue
			var push: float = (min_d - dist) * 0.5
			var dir := delta / dist
			if other.data.is_boss:
				enemy.global_position += dir * push * 2.0
			else:
				enemy.global_position += dir * push
				other.global_position -= dir * push


func apply_contact(chef: Chef, invuln_time: float) -> void:
	if chef.invuln > 0.0 or chef.hp <= 0.0:
		return
	var reach := chef.radius + 36.0
	var nearby: Array = query(chef.global_position, reach)
	var best: EnemyActor = null
	var best_d := INF
	for enemy in nearby:
		if not enemy.alive or enemy.data == null:
			continue
		var dist := chef.global_position.distance_to(enemy.global_position)
		var hit: float = chef.radius + enemy.data.radius
		if dist <= hit and dist < best_d:
			best = enemy
			best_d = dist
	if best != null:
		var amount := clampf(
			best.data.contact_damage,
			battle.balance.contact_damage_min,
			battle.balance.contact_damage_max
		)
		chef.hurt(amount, invuln_time)


func tick_attacks(delta: float, chef_pos: Vector2, arsenal) -> void:
	for enemy in active:
		if not enemy.alive or enemy.data == null:
			continue
		if enemy.data.behavior == "ranged":
			enemy.shoot_cd -= delta
			if enemy.shoot_cd <= 0.0:
				enemy.shoot_cd = enemy.data.shoot_cooldown
				var dir := chef_pos - enemy.global_position
				if dir.length_squared() < 0.01:
					dir = Vector2.RIGHT
				else:
					dir = dir.normalized()
				var origin := enemy.global_position + dir * (enemy.data.radius + 6.0)
				arsenal.spawn_popcorn(origin, dir * enemy.data.projectile_speed, enemy.data.projectile_damage, enemy.data.projectile_texture)
		if enemy.data.is_boss:
			enemy.summon_cd -= delta
			enemy.slam_cd -= delta
			if enemy.summon_cd <= 0.0:
				enemy.summon_cd = enemy.data.summon_cooldown
				_summon(enemy)
			if enemy.slam_cd <= 0.0:
				enemy.slam_cd = enemy.data.slam_cooldown
				arsenal.spawn_cream(
					chef_pos,
					enemy.data.slam_radius,
					enemy.data.slam_duration,
					enemy.data.slam_slow,
					enemy.data.slam_windup
				)


func leash(chef_pos: Vector2) -> void:
	var balance: BalanceData = battle.balance
	var limit: float = balance.leash_distance
	var limit_sq: float = limit * limit
	for enemy in active:
		if not enemy.alive or enemy.data == null or enemy.data.is_boss:
			continue
		if enemy.global_position.distance_squared_to(chef_pos) > limit_sq:
			enemy.global_position = spawn_point(battle.balance.spawn_margin)


func sweep() -> void:
	var dead: Array[EnemyActor] = []
	for enemy in active:
		if not enemy.alive:
			dead.append(enemy)
	for enemy in dead:
		active.erase(enemy)
		if enemy.data != null:
			battle.register_kill(enemy)
			if enemy.data.xp > 0 and battle.gems != null:
				battle.gems.spawn(enemy.global_position, enemy.data.xp)
			if enemy.data.is_boss:
				battle.on_boss_killed()
			if enemy.data.split_count > 0 and enemy.data.split_id != "":
				_spawn_splits(enemy)
		_release(enemy)
	_note_count()


func spawn_enemy(id: String, pos: Vector2) -> bool:
	if active.size() >= cap:
		rejected_spawns += 1
		return false
	var data: EnemyData = Game.enemies.get(id)
	if data == null:
		push_error("Unknown enemy id %s" % id)
		return false
	var enemy := _acquire()
	enemy.activate(data, pos)
	active.append(enemy)
	_note_count()
	return true


func spawn_boss() -> bool:
	_make_room(1, null)
	var spawned := spawn_enemy(battle.balance.boss_id, spawn_point(8.0))
	if spawned:
		boss_spawned = true
	return spawned


func force_kill_boss() -> bool:
	var boss := boss_actor()
	if boss == null:
		return false
	boss.receive_damage(boss.hp + 100000.0)
	return true


func spawn_point(margin: float) -> Vector2:
	var view := get_viewport().get_visible_rect().size
	if view.x < 10.0:
		view = Vector2(640, 360)
	var half := view * 0.5
	var dir := Vector2.from_angle(randf() * TAU)
	var tx := INF if absf(dir.x) < 0.0001 else half.x / absf(dir.x)
	var ty := INF if absf(dir.y) < 0.0001 else half.y / absf(dir.y)
	return player_pos + dir * (minf(tx, ty) + margin)


func _summon(boss: EnemyActor) -> void:
	if boss.data.summon_id == "" or boss.data.summon_count <= 0:
		return
	_make_room(boss.data.summon_count, boss)
	for i in boss.data.summon_count:
		if active.size() >= cap:
			rejected_spawns += 1
			break
		var dir := Vector2.from_angle(randf() * TAU)
		spawn_enemy(boss.data.summon_id, boss.global_position + dir * (boss.data.radius + 14.0))


func _spawn_splits(parent: EnemyActor) -> void:
	var count := parent.data.split_count
	_make_room(count, null)
	var base := randf() * TAU
	for i in count:
		if active.size() >= cap:
			rejected_spawns += 1
			break
		var dir := Vector2.from_angle(base + TAU * float(i) / float(count))
		spawn_enemy(parent.data.split_id, parent.global_position + dir * (parent.data.radius + 8.0))


func _make_room(slots: int, protect: EnemyActor) -> void:
	var guard := 0
	while active.size() + slots > cap and guard < cap + 8:
		guard += 1
		var victim: EnemyActor = null
		var best_d := -1.0
		for enemy in active:
			if enemy == protect or not enemy.alive or enemy.data == null or enemy.data.is_boss:
				continue
			var d := enemy.global_position.distance_squared_to(player_pos)
			if d > best_d:
				best_d = d
				victim = enemy
		if victim == null:
			return
		active.erase(victim)
		_release(victim)


func _note_count() -> void:
	if active.size() > peak_count:
		peak_count = active.size()
	if active.size() > cap:
		overflowed = true


func _acquire() -> EnemyActor:
	if pool.is_empty():
		var enemy: EnemyActor = ENEMY_SCENE.instantiate()
		add_child(enemy)
		return enemy
	return pool.pop_back()


func _release(enemy: EnemyActor) -> void:
	enemy.deactivate()
	pool.append(enemy)


func _key(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL)), int(floor(pos.y / CELL)))
