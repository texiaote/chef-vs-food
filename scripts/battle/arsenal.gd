class_name Arsenal
extends Node2D

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const CLOUD_SCENE := preload("res://scenes/pepper_cloud.tscn")
const RING_SCENE := preload("res://scenes/cream_ring.tscn")
const MAX_PROJECTILES := 240
const MAX_CLOUDS := 48
const MAX_RINGS := 12

var battle = null
var horde: Horde
var weapons: Array = []
var projectiles: Array[Projectile] = []
var projectile_pool: Array[Projectile] = []
var clouds: Array[PepperCloud] = []
var cloud_pool: Array[PepperCloud] = []
var rings: Array[CreamRing] = []
var ring_pool: Array[CreamRing] = []
var pans: Array[Sprite2D] = []
var swing: SwingFx


class Runtime extends RefCounted:
	var data: WeaponData
	var level: int = 1
	var evolved: bool = false
	var evo: EvolutionData
	var cd: float = 0.25
	var orbit: float = 0.0
	var hit_cd: Dictionary = {}


func _ready() -> void:
	swing = preload("res://scripts/battle/swing_fx.gd").new()
	swing.name = "Swing"
	add_child(swing)
	for _i in 8:
		var pan := Sprite2D.new()
		pan.visible = false
		pan.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pan.z_index = 2
		add_child(pan)
		pans.append(pan)


func reset() -> void:
	weapons.clear()
	for pan in pans:
		pan.visible = false


func add_weapon(data: WeaponData) -> void:
	if data == null or find(data.id) != null:
		return
	var runtime := Runtime.new()
	runtime.data = data
	runtime.level = 1
	runtime.cd = 0.2
	weapons.append(runtime)


func find(id: String) -> Runtime:
	for runtime in weapons:
		if runtime.data != null and runtime.data.id == id:
			return runtime
	return null


func upgrade(id: String) -> void:
	var runtime := find(id)
	if runtime == null or runtime.evolved:
		return
	if runtime.level < runtime.data.max_level:
		runtime.level += 1


func evolve(evo: EvolutionData) -> void:
	var runtime := find(evo.weapon_id)
	if runtime == null:
		return
	runtime.evolved = true
	runtime.evo = evo
	runtime.cd = 0.15


func has_pattern(names: Array) -> bool:
	for runtime in weapons:
		if names.has(pattern_of(runtime)):
			return true
	return false


func pattern_of(runtime: Runtime) -> String:
	if runtime.evolved and runtime.evo != null:
		return runtime.evo.pattern
	return runtime.data.pattern


func tick(delta: float) -> void:
	for runtime in weapons:
		var pattern := pattern_of(runtime)
		if pattern == "orbit" or pattern == "hot_oil":
			_tick_orbit(runtime, delta)
			continue
		runtime.cd -= delta
		if runtime.cd > 0.0:
			continue
		runtime.cd = _cooldown(runtime)
		match pattern:
			"knife":
				_fire_knife(runtime, false)
			"knife_rain":
				_fire_knife(runtime, true)
			"spatula":
				_swing(runtime)
			"cloud":
				_drop_cloud(runtime)
			"bounce":
				_fire_pin(runtime)
	_tick_projectiles(delta)
	_tick_clouds(delta)
	_tick_rings(delta)
	if swing.has_method("tick"):
		swing.tick(delta)


func slow_at(pos: Vector2) -> float:
	var slow := 1.0
	for ring in rings:
		if ring.slows_at(pos):
			slow = minf(slow, ring.slow)
	return slow


func hostile_projectiles() -> Array:
	var out: Array = []
	for projectile in projectiles:
		if projectile.alive and projectile.hostile:
			out.append(projectile)
	return out


func live_rings() -> Array:
	var out: Array = []
	for ring in rings:
		if ring.alive:
			out.append(ring)
	return out


func spawn_popcorn(pos: Vector2, vel: Vector2, damage: float, tex: Texture2D) -> void:
	_spawn_projectile({
		"pos": pos,
		"vel": vel,
		"damage": damage,
		"ttl": 3.2,
		"radius": 5.0,
		"pierce": 1,
		"kind": "popcorn",
		"texture": tex,
		"tint": Color.WHITE,
		"scale": 1.0,
		"hostile": true,
	})


func spawn_cream(pos: Vector2, radius: float, duration: float, slow: float, windup: float) -> void:
	var ring := _acquire_ring()
	ring.activate(pos, radius, duration, slow, windup)


func _tick_orbit(runtime: Runtime, delta: float) -> void:
	runtime.orbit += runtime.data.orbit_speed * delta
	var count := runtime.data.count_at(runtime.level)
	var orbit_r := runtime.data.extra_at(runtime.level)
	var hit_r := runtime.data.area_at(runtime.level)
	var burn := 0.0
	var burn_time := 0.0
	var tex := runtime.data.effect_texture if runtime.data.effect_texture != null else runtime.data.texture
	var tint := runtime.data.tint
	if runtime.evolved and runtime.evo != null:
		orbit_r *= runtime.evo.radius_multiplier
		burn = runtime.evo.burn_dps * battle.damage_multiplier()
		burn_time = runtime.evo.burn_duration
		if runtime.evo.texture != null:
			tex = runtime.evo.texture
		tint = Color(1.45, 0.72, 0.35)
	for i in pans.size():
		var pan := pans[i]
		if i >= count:
			pan.visible = false
			continue
		var angle := runtime.orbit + TAU * float(i) / float(maxi(count, 1))
		pan.visible = true
		pan.texture = tex
		pan.modulate = tint
		pan.scale = Vector2(0.9, 0.9)
		pan.global_position = battle.chef.global_position + Vector2.from_angle(angle) * orbit_r
		pan.rotation = angle
	var expired: Array = []
	for key in runtime.hit_cd.keys():
		runtime.hit_cd[key] = float(runtime.hit_cd[key]) - delta
		if float(runtime.hit_cd[key]) <= 0.0:
			expired.append(key)
	for key in expired:
		runtime.hit_cd.erase(key)
	var interval := _cooldown(runtime)
	var amount := _damage(runtime)
	for i in count:
		var angle := runtime.orbit + TAU * float(i) / float(maxi(count, 1))
		var pos: Vector2 = battle.chef.global_position + Vector2.from_angle(angle) * orbit_r
		for enemy in horde.query(pos, hit_r + 24.0):
			if not enemy.alive:
				continue
			if pos.distance_to(enemy.global_position) > hit_r + enemy.data.radius:
				continue
			var id := enemy.get_instance_id()
			if runtime.hit_cd.has(id):
				continue
			runtime.hit_cd[id] = interval
			enemy.receive_damage(amount, burn, burn_time)
			AudioManager.play("hit")


func _fire_knife(runtime: Runtime, ring: bool) -> void:
	var count := runtime.evo.count if ring and runtime.evo != null else runtime.data.count_at(runtime.level)
	count = maxi(count, 1)
	var pierce := maxi(int(runtime.data.extra_at(runtime.level)), 1)
	var speed := runtime.data.projectile_speed
	var tex := runtime.data.effect_texture if runtime.data.effect_texture != null else runtime.data.texture
	if ring and runtime.evo != null and runtime.evo.texture != null:
		tex = runtime.data.effect_texture if runtime.data.effect_texture != null else runtime.data.texture
	var base: float = battle.chef.facing.angle()
	for i in count:
		var angle := base
		if ring:
			angle = TAU * float(i) / float(count)
		elif count > 1:
			var spread := deg_to_rad(8.0 + 3.0 * float(count))
			var t := float(i) / float(count - 1) - 0.5
			angle = base + t * spread * 2.0
		var dir := Vector2.from_angle(angle)
		_spawn_projectile({
			"pos": battle.chef.global_position + dir * 14.0,
			"vel": dir * speed,
			"damage": _damage(runtime),
			"ttl": 1.25,
			"radius": 6.0,
			"pierce": pierce,
			"kind": "knife_rain" if ring else "knife",
			"texture": tex,
			"tint": runtime.data.tint,
			"scale": 0.55,
			"hostile": false,
		})
	AudioManager.play("shoot")


func _swing(runtime: Runtime) -> void:
	var arc := runtime.data.area_at(runtime.level)
	var reach := runtime.data.extra_at(runtime.level)
	var facing: Vector2 = battle.chef.facing
	var angle := facing.angle()
	var half := deg_to_rad(arc) * 0.5
	var amount := _damage(runtime)
	for enemy in horde.query(battle.chef.global_position, reach + 20.0):
		if not enemy.alive:
			continue
		var off: Vector2 = enemy.global_position - battle.chef.global_position
		var dist := off.length()
		if dist > reach + enemy.data.radius:
			continue
		if dist > 1.0 and absf(wrapf(off.angle() - angle, -PI, PI)) > half:
			continue
		enemy.receive_damage(amount)
	swing.global_position = battle.chef.global_position
	swing.trigger(facing, arc, reach)
	AudioManager.play("swing")


func _drop_cloud(runtime: Runtime) -> void:
	var count := runtime.data.count_at(runtime.level)
	var drop := runtime.data.area_at(runtime.level)
	var radius := runtime.data.extra_at(runtime.level)
	var tex := runtime.data.effect_texture if runtime.data.effect_texture != null else runtime.data.texture
	for _i in count:
		var off := Vector2.from_angle(randf() * TAU) * randf_range(16.0, maxf(drop, 18.0))
		var cloud := _acquire_cloud()
		cloud.activate(
			battle.chef.global_position + off,
			radius,
			runtime.data.duration,
			runtime.data.tick_rate,
			_damage(runtime),
			tex
		)


func _fire_pin(runtime: Runtime) -> void:
	var count := runtime.data.count_at(runtime.level)
	var hits := maxi(int(runtime.data.extra_at(runtime.level)), 1)
	var tex := runtime.data.effect_texture if runtime.data.effect_texture != null else runtime.data.texture
	for i in count:
		var angle: float = battle.chef.facing.angle() + (float(i) - float(count - 1) * 0.5) * 0.22
		var dir := Vector2.from_angle(angle)
		_spawn_projectile({
			"pos": battle.chef.global_position + dir * 12.0,
			"vel": dir * runtime.data.projectile_speed,
			"damage": _damage(runtime),
			"ttl": 2.4,
			"radius": runtime.data.area_at(runtime.level),
			"pierce": 1,
			"bounces": hits,
			"chain_range": runtime.data.chain_range,
			"kind": "bounce",
			"texture": tex,
			"tint": runtime.data.tint,
			"scale": 0.7,
			"hostile": false,
		})
	AudioManager.play("shoot")


func _tick_projectiles(delta: float) -> void:
	var i := projectiles.size() - 1
	while i >= 0:
		var projectile := projectiles[i]
		if not projectile.alive:
			_release_projectile_at(i)
			i -= 1
			continue
		projectile.global_position += projectile.vel * delta
		projectile.ttl -= delta
		if projectile.vel.length_squared() > 1.0:
			projectile.rotation = projectile.vel.angle()
		if projectile.ttl <= 0.0:
			_release_projectile_at(i)
			i -= 1
			continue
		if projectile.hostile:
			var chef: Chef = battle.chef
			if projectile.global_position.distance_to(chef.global_position) <= projectile.radius + chef.radius:
				chef.hurt(projectile.damage, battle.balance.invuln_duration)
				_release_projectile_at(i)
			i -= 1
			continue
		var hit_done := false
		for enemy in horde.query(projectile.global_position, projectile.radius + 28.0):
			if not enemy.alive:
				continue
			var id := enemy.get_instance_id()
			if projectile.hits.has(id):
				continue
			if projectile.global_position.distance_to(enemy.global_position) > projectile.radius + enemy.data.radius:
				continue
			enemy.receive_damage(projectile.damage, projectile.burn_dps, projectile.burn_time)
			projectile.hits[id] = true
			AudioManager.play("hit")
			if projectile.kind == "bounce":
				projectile.bounces -= 1
				if projectile.bounces <= 0:
					_release_projectile_at(i)
				else:
					var nxt: EnemyActor = _chain_target(projectile, enemy)
					if nxt == null:
						_release_projectile_at(i)
					else:
						var dir := nxt.global_position - projectile.global_position
						if dir.length_squared() < 0.01:
							dir = Vector2.RIGHT
						else:
							dir = dir.normalized()
						projectile.vel = dir * projectile.speed
						projectile.ttl = maxf(projectile.ttl, 0.45)
				hit_done = true
				break
			projectile.pierce -= 1
			if projectile.pierce <= 0:
				_release_projectile_at(i)
				hit_done = true
				break
		if hit_done and (i >= projectiles.size() or projectiles[i] != projectile):
			pass
		i -= 1


func _tick_clouds(delta: float) -> void:
	var i := clouds.size() - 1
	while i >= 0:
		var cloud := clouds[i]
		if not cloud.alive:
			_release_cloud_at(i)
			i -= 1
			continue
		cloud.ttl -= delta
		cloud.tick_acc += delta
		if cloud.ttl <= 0.0:
			_release_cloud_at(i)
			i -= 1
			continue
		while cloud.tick_acc >= cloud.tick_rate:
			cloud.tick_acc -= cloud.tick_rate
			for enemy in horde.query(cloud.global_position, cloud.radius + 8.0):
				if enemy.alive and cloud.global_position.distance_to(enemy.global_position) <= cloud.radius + enemy.data.radius:
					enemy.receive_damage(cloud.damage)
		cloud.queue_redraw()
		i -= 1


func _tick_rings(delta: float) -> void:
	var i := rings.size() - 1
	while i >= 0:
		var ring := rings[i]
		if not ring.alive:
			_release_ring_at(i)
			i -= 1
			continue
		ring.tick(delta)
		if ring.delay <= 0.0 and ring.ttl <= 0.0:
			_release_ring_at(i)
		i -= 1


func _chain_target(projectile: Projectile, current: EnemyActor) -> EnemyActor:
	var best: EnemyActor = null
	var best_d := projectile.chain_range * projectile.chain_range
	for enemy in horde.query(projectile.global_position, projectile.chain_range):
		if not enemy.alive or enemy == current:
			continue
		if projectile.hits.has(enemy.get_instance_id()):
			continue
		var d := projectile.global_position.distance_squared_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	return best


func _spawn_projectile(params: Dictionary) -> void:
	if projectiles.size() >= MAX_PROJECTILES:
		return
	var projectile: Projectile
	if projectile_pool.is_empty():
		projectile = PROJECTILE_SCENE.instantiate()
		add_child(projectile)
	else:
		projectile = projectile_pool.pop_back()
	projectile.launch(params)
	projectiles.append(projectile)


func _release_projectile_at(index: int) -> void:
	if index < 0 or index >= projectiles.size():
		return
	var projectile := projectiles[index]
	projectiles.remove_at(index)
	projectile.deactivate()
	projectile_pool.append(projectile)


func _acquire_cloud() -> PepperCloud:
	while clouds.size() >= MAX_CLOUDS:
		_release_cloud_at(0)
	var cloud: PepperCloud
	if cloud_pool.is_empty():
		cloud = CLOUD_SCENE.instantiate()
		add_child(cloud)
	else:
		cloud = cloud_pool.pop_back()
	clouds.append(cloud)
	return cloud


func _release_cloud_at(index: int) -> void:
	var cloud := clouds[index]
	clouds.remove_at(index)
	cloud.deactivate()
	cloud_pool.append(cloud)


func _acquire_ring() -> CreamRing:
	while rings.size() >= MAX_RINGS:
		_release_ring_at(0)
	var ring: CreamRing
	if ring_pool.is_empty():
		ring = RING_SCENE.instantiate()
		add_child(ring)
	else:
		ring = ring_pool.pop_back()
	rings.append(ring)
	return ring


func _release_ring_at(index: int) -> void:
	var ring := rings[index]
	rings.remove_at(index)
	ring.deactivate()
	ring_pool.append(ring)


func _damage(runtime: Runtime) -> float:
	var amount: float = runtime.data.damage_at(runtime.level) * float(battle.damage_multiplier())
	if runtime.evolved and runtime.evo != null:
		amount *= runtime.evo.damage_multiplier
	return amount


func _cooldown(runtime: Runtime) -> float:
	return maxf(0.08, runtime.data.cooldown_at(runtime.level) * battle.cooldown_multiplier())
