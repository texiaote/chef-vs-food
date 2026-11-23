extends Node

## Writes the runtime .tres catalog. Numbers here are the v0.1 starting values.
## Re-run: godot --headless --path . --scene res://tools/build_data.tscn


func _ready() -> void:
	_build()
	print("DATA BUILT")
	get_tree().quit()


func _build() -> void:
	_weapons()
	_passives()
	_evolutions()
	_enemies()
	_balance()


func _tex(path: String) -> Texture2D:
	var res = load(path)
	if res == null:
		push_error("Missing texture %s" % path)
	return res


func _save(res: Resource, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	res.take_over_path(path)
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("Failed to save %s (%s)" % [path, err])


func _weapons() -> void:
	var knife := WeaponData.new()
	knife.id = "flying_knife"
	knife.display_name = "飞刀 Flying Knife"
	knife.description = "朝移动方向射出飞刀，每把只打一个敌人。"
	knife.texture = _tex("res://assets/textures/weapons/knife.png")
	knife.effect_texture = knife.texture
	knife.pattern = "knife"
	knife.damages = PackedFloat32Array([12, 16, 20, 25, 32])
	knife.cooldowns = PackedFloat32Array([0.70, 0.62, 0.54, 0.48, 0.42])
	knife.counts = PackedInt32Array([1, 1, 2, 2, 3])
	knife.areas = PackedFloat32Array([6, 6, 6, 6, 6])
	knife.extras = PackedFloat32Array([1, 1, 1, 1, 1])
	knife.projectile_speed = 300.0
	_save(knife, "res://data/weapons/flying_knife.tres")

	var spatula := WeaponData.new()
	spatula.id = "spatula"
	spatula.display_name = "锅铲 Spatula"
	spatula.description = "朝面前扇形挥击，只打近处的敌人。"
	spatula.texture = _tex("res://assets/textures/weapons/spatula.png")
	spatula.effect_texture = spatula.texture
	spatula.pattern = "spatula"
	spatula.damages = PackedFloat32Array([9, 12, 16, 20, 26])
	spatula.cooldowns = PackedFloat32Array([0.82, 0.74, 0.66, 0.58, 0.52])
	spatula.counts = PackedInt32Array([1, 1, 1, 1, 1])
	spatula.areas = PackedFloat32Array([70, 82, 96, 112, 130])
	spatula.extras = PackedFloat32Array([40, 46, 52, 58, 66])
	_save(spatula, "res://data/weapons/spatula.tres")

	var pan := WeaponData.new()
	pan.id = "frying_pan"
	pan.display_name = "平底锅 Frying Pan"
	pan.description = "绕着厨师转。等级越高，锅越多。"
	pan.texture = _tex("res://assets/textures/weapons/pan.png")
	pan.effect_texture = pan.texture
	pan.pattern = "orbit"
	pan.damages = PackedFloat32Array([8, 10, 13, 16, 20])
	pan.cooldowns = PackedFloat32Array([0.42, 0.38, 0.34, 0.30, 0.26])
	pan.counts = PackedInt32Array([1, 2, 3, 4, 5])
	pan.areas = PackedFloat32Array([15, 15, 16, 16, 17])
	pan.extras = PackedFloat32Array([46, 48, 50, 52, 54])
	pan.orbit_speed = 2.5
	_save(pan, "res://data/weapons/frying_pan.tres")

	var pepper := WeaponData.new()
	pepper.id = "pepper_shaker"
	pepper.display_name = "胡椒罐 Pepper Shaker"
	pepper.description = "在附近随机洒下一团胡椒，持续造成伤害。"
	pepper.texture = _tex("res://assets/textures/weapons/pepper.png")
	pepper.effect_texture = _tex("res://assets/textures/weapons/pepper_cloud.png")
	pepper.pattern = "cloud"
	pepper.damages = PackedFloat32Array([4, 5, 6, 8, 10])
	pepper.cooldowns = PackedFloat32Array([2.0, 1.8, 1.6, 1.45, 1.3])
	pepper.counts = PackedInt32Array([1, 1, 2, 2, 3])
	pepper.areas = PackedFloat32Array([80, 90, 100, 110, 120])
	pepper.extras = PackedFloat32Array([30, 34, 36, 40, 46])
	pepper.duration = 2.6
	pepper.tick_rate = 0.4
	_save(pepper, "res://data/weapons/pepper_shaker.tres")

	var pin := WeaponData.new()
	pin.id = "rolling_pin"
	pin.display_name = "擀面杖 Rolling Pin"
	pin.description = "扔出擀面杖，在敌人之间弹来弹去。"
	pin.texture = _tex("res://assets/textures/weapons/rolling_pin.png")
	pin.effect_texture = pin.texture
	pin.pattern = "bounce"
	pin.damages = PackedFloat32Array([10, 13, 16, 20, 25])
	pin.cooldowns = PackedFloat32Array([1.45, 1.3, 1.15, 1.0, 0.9])
	pin.counts = PackedInt32Array([1, 1, 1, 2, 2])
	pin.areas = PackedFloat32Array([8, 8, 9, 9, 10])
	pin.extras = PackedFloat32Array([3, 4, 5, 6, 8])
	pin.projectile_speed = 210.0
	pin.chain_range = 190.0
	_save(pin, "res://data/weapons/rolling_pin.tres")


func _passives() -> void:
	_passive("apron", "围裙 Apron", "提高最大生命。", "max_hp", 20.0, "res://assets/textures/passives/apron.png")
	_passive("sneakers", "跑鞋 Sneakers", "提高移动速度。", "move_speed", 0.10, "res://assets/textures/passives/sneakers.png")
	_passive("big_ladle", "大汤勺 Big Ladle", "扩大经验拾取范围。", "pickup_radius", 24.0, "res://assets/textures/passives/ladle.png")
	_passive("secret_sauce", "秘制酱料 Secret Sauce", "提高所有伤害。", "damage", 0.12, "res://assets/textures/passives/sauce.png")
	_passive("kitchen_timer", "厨房计时器 Kitchen Timer", "缩短武器冷却。", "cooldown", 0.08, "res://assets/textures/passives/timer.png")


func _passive(id: String, display_name: String, description: String, stat: String, per_level: float, tex_path: String) -> void:
	var data := PassiveData.new()
	data.id = id
	data.display_name = display_name
	data.description = description
	data.stat = stat
	data.per_level = per_level
	data.max_level = 5
	data.texture = _tex(tex_path)
	_save(data, "res://data/passives/%s.tres" % id)


func _evolutions() -> void:
	var rain := EvolutionData.new()
	rain.id = "knife_rain"
	rain.display_name = "飞刀雨 Knife Rain"
	rain.description = "飞刀满级且拥有秘制酱料。向四周同时扔出一圈飞刀。"
	rain.weapon_id = "flying_knife"
	rain.passive_id = "secret_sauce"
	rain.pattern = "knife_rain"
	rain.texture = _tex("res://assets/textures/weapons/knife_rain.png")
	rain.damage_multiplier = 0.8
	rain.radius_multiplier = 1.0
	rain.count = 14
	_save(rain, "res://data/evolutions/knife_rain.tres")

	var oil := EvolutionData.new()
	oil.id = "hot_oil_pan"
	oil.display_name = "热油锅 Hot Oil Pan"
	oil.description = "平底锅满级且拥有厨房计时器。轨道更大，命中的敌人会燃烧。"
	oil.weapon_id = "frying_pan"
	oil.passive_id = "kitchen_timer"
	oil.pattern = "hot_oil"
	oil.texture = _tex("res://assets/textures/weapons/hot_pan.png")
	oil.damage_multiplier = 1.15
	oil.radius_multiplier = 1.65
	oil.count = 5
	oil.burn_dps = 7.0
	oil.burn_duration = 2.2
	_save(oil, "res://data/evolutions/hot_oil_pan.tres")


func _enemies() -> void:
	var broccoli := EnemyData.new()
	broccoli.id = "broccoli"
	broccoli.display_name = "西兰花 Broccoli"
	broccoli.texture = _tex("res://assets/textures/enemies/broccoli.png")
	broccoli.max_hp = 8
	broccoli.speed = 28
	broccoli.contact_damage = 5
	broccoli.xp = 2
	broccoli.radius = 12
	broccoli.behavior = "chase"
	_save(broccoli, "res://data/enemies/broccoli.tres")

	var chili := EnemyData.new()
	chili.id = "chili"
	chili.display_name = "辣椒 Chili"
	chili.texture = _tex("res://assets/textures/enemies/chili.png")
	chili.max_hp = 6
	chili.speed = 74
	chili.contact_damage = 6
	chili.xp = 2
	chili.radius = 10
	chili.behavior = "chase"
	_save(chili, "res://data/enemies/chili.tres")

	var potato := EnemyData.new()
	potato.id = "potato"
	potato.display_name = "土豆 Potato"
	potato.texture = _tex("res://assets/textures/enemies/potato.png")
	potato.max_hp = 46
	potato.speed = 18
	potato.contact_damage = 10
	potato.xp = 5
	potato.radius = 14
	potato.behavior = "chase"
	_save(potato, "res://data/enemies/potato.tres")

	var onion := EnemyData.new()
	onion.id = "onion"
	onion.display_name = "洋葱 Onion"
	onion.texture = _tex("res://assets/textures/enemies/onion.png")
	onion.max_hp = 18
	onion.speed = 32
	onion.contact_damage = 7
	onion.xp = 4
	onion.radius = 12
	onion.behavior = "split"
	onion.split_id = "onion_small"
	onion.split_count = 2
	_save(onion, "res://data/enemies/onion.tres")

	var small := EnemyData.new()
	small.id = "onion_small"
	small.display_name = "小洋葱 Small Onion"
	small.texture = _tex("res://assets/textures/enemies/onion_small.png")
	small.max_hp = 6
	small.speed = 44
	small.contact_damage = 5
	small.xp = 1
	small.radius = 8
	small.behavior = "chase"
	_save(small, "res://data/enemies/onion_small.tres")

	var corn := EnemyData.new()
	corn.id = "corn"
	corn.display_name = "玉米 Corn"
	corn.texture = _tex("res://assets/textures/enemies/corn.png")
	corn.max_hp = 16
	corn.speed = 34
	corn.contact_damage = 6
	corn.xp = 4
	corn.radius = 12
	corn.behavior = "ranged"
	corn.preferred_range = 145
	corn.range_band = 26
	corn.shoot_cooldown = 1.9
	corn.projectile_speed = 120
	corn.projectile_damage = 8
	corn.projectile_texture = _tex("res://assets/textures/enemies/popcorn.png")
	_save(corn, "res://data/enemies/corn.tres")

	var cupcake := EnemyData.new()
	cupcake.id = "cake_small"
	cupcake.display_name = "小蛋糕 Small Cake"
	cupcake.texture = _tex("res://assets/textures/enemies/cake_small.png")
	cupcake.max_hp = 20
	cupcake.speed = 38
	cupcake.contact_damage = 7
	cupcake.xp = 3
	cupcake.radius = 11
	cupcake.behavior = "chase"
	_save(cupcake, "res://data/enemies/cake_small.tres")

	var cake := EnemyData.new()
	cake.id = "cake"
	cake.display_name = "巨型生日蛋糕 Giant Birthday Cake"
	cake.texture = _tex("res://assets/textures/enemies/cake.png")
	cake.max_hp = 1400
	cake.speed = 24
	cake.contact_damage = 10
	cake.xp = 120
	cake.radius = 34
	cake.behavior = "boss"
	cake.is_boss = true
	cake.summon_id = "cake_small"
	cake.summon_count = 3
	cake.summon_cooldown = 5.5
	cake.slam_cooldown = 4.2
	cake.slam_radius = 74
	cake.slam_duration = 2.5
	cake.slam_slow = 0.48
	cake.slam_windup = 0.4
	_save(cake, "res://data/enemies/cake.tres")


func _balance() -> void:
	var data := BalanceData.new()
	data.player_max_hp = 100
	data.player_speed = 102
	data.player_radius = 12
	data.invuln_duration = 0.55
	data.base_pickup_radius = 56
	data.gem_attract_speed = 280
	data.gem_collect_distance = 12
	data.enemy_cap = 300
	data.win_time = 600
	data.boss_time = 480
	data.boss_id = "cake"
	data.spawn_margin = 28
	data.leash_distance = 920
	data.separation_scale = 0.82
	data.xp_base = 12
	data.xp_exponent = 1.28
	data.contact_damage_min = 5
	data.contact_damage_max = 10
	data.spawn_interval_at_minute = PackedFloat32Array([
		0.20, 0.17, 0.15, 0.13, 0.11, 0.09, 0.075, 0.06, 0.05, 0.04, 0.04,
	])
	data.spawn_ids = PackedStringArray([
		"broccoli", "chili", "potato", "onion", "corn",
	])
	data.spawn_from = PackedFloat32Array([0, 120, 240, 300, 360])
	data.spawn_weight = PackedFloat32Array([8, 6, 4, 4, 4])
	_save(data, "res://data/balance.tres")
