class_name AutoPlayer
extends RefCounted

## Test-only driver. The real game never calls this.
## Steers the chef so knives point at food, and steps away before contact.


static func steer(battle, wander_bias: float = 0.15) -> Vector2:
	var pos: Vector2 = battle.chef.global_position
	var threat := Vector2.ZERO
	var nearest = null
	var nearest_d := INF
	var pad := float(battle.chef.radius) + 28.0
	for enemy in battle.horde.active:
		if not enemy.alive or enemy.data == null:
			continue
		var off: Vector2 = pos - enemy.global_position
		var dist := off.length()
		if dist < nearest_d:
			nearest_d = dist
			nearest = enemy
		var danger := pad + float(enemy.data.radius)
		if dist < danger:
			if off.length_squared() < 1.0:
				off = Vector2.RIGHT
			threat += off.normalized() * (danger - dist + 8.0)
	for projectile in battle.arsenal.hostile_projectiles():
		var offp: Vector2 = pos - projectile.global_position
		var dp := offp.length()
		if dp < 56.0:
			if offp.length_squared() < 1.0:
				offp = Vector2.UP
			threat += offp.normalized() * (56.0 - dp)
	for ring in battle.arsenal.live_rings():
		if ring.slows_at(pos):
			var offc: Vector2 = pos - ring.global_position
			if offc.length_squared() < 1.0:
				offc = Vector2.UP
			threat += offc.normalized() * 40.0
	if nearest != null and nearest_d < pad + 6.0 and threat.length() < 8.0:
		var away: Vector2 = pos - nearest.global_position
		if away.length_squared() < 1.0:
			away = Vector2.RIGHT
		threat = away.normalized() * 24.0
	if threat.length() > 5.0:
		return threat.normalized()
	var wander := Vector2.RIGHT.rotated(float(battle.run_time) * 0.7)
	if nearest == null:
		return wander
	var hunt: Vector2 = nearest.global_position - pos
	if hunt.length_squared() < 1.0:
		return wander
	return (hunt.normalized() * (1.0 - wander_bias) + wander * wander_bias).normalized()
