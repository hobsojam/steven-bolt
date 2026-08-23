extends RefCounted

# Pure combat-resolution logic, deliberately independent of the scene tree
# (see AGENTS.md's "keep pure math testable" note) so tests/run_tests.gd can
# exercise hit/kill/breach resolution headlessly. scripts/enemy_wave_visual.gd
# is the thin layer that turns this state into MeshInstance3D placeholders.
#
# Bullets aren't locked onto the enemy they were fired at - resolve_hits()
# always resolves against whichever enemy is currently nearest in a bullet's
# lane. That keeps bullets as plain {lane, distance} data (no stale index if
# their original target dies to another bullet first) at the cost of being a
# simplification, not a literal single-target projectile.

const CombatRules := preload("res://scripts/combat_rules.gd")

var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var _fire_cooldown: float = 0.0


func _init(enemy_data: Array) -> void:
	for data in enemy_data:
		enemies.append(
			{"lane": data["lane"], "distance": data["distance"], "hp": data["hp"], "alive": true}
		)


func is_cleared() -> bool:
	for enemy in enemies:
		if enemy["alive"]:
			return false
	return true


func nearest_enemy_index_in_lane(lane: int) -> int:
	var best_index: int = -1
	var best_distance: float = INF
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		if enemy["alive"] and enemy["lane"] == lane and enemy["distance"] < best_distance:
			best_distance = enemy["distance"]
			best_index = i
	return best_index


func apply_hit(enemy_index: int, damage: int) -> bool:
	var enemy: Dictionary = enemies[enemy_index]
	enemy["hp"] -= damage
	if enemy["hp"] <= 0:
		enemy["alive"] = false
		return true
	return false


func try_fire(crowd_lane: int, crowd_distance: float, damage: int, delta: float) -> void:
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return
	if nearest_enemy_index_in_lane(crowd_lane) == -1:
		return
	bullets.append({"lane": crowd_lane, "distance": crowd_distance, "damage": damage})
	_fire_cooldown = CombatRules.FIRE_INTERVAL


func advance_bullets(delta: float) -> void:
	for bullet in bullets:
		bullet["distance"] += CombatRules.BULLET_SPEED * delta


func resolve_hits() -> Array[int]:
	var killed: Array[int] = []
	var remaining_bullets: Array[Dictionary] = []
	for bullet in bullets:
		var target_index: int = nearest_enemy_index_in_lane(bullet["lane"])
		if target_index != -1 and bullet["distance"] >= enemies[target_index]["distance"]:
			if apply_hit(target_index, bullet["damage"]):
				killed.append(target_index)
		else:
			remaining_bullets.append(bullet)
	bullets = remaining_bullets
	return killed


func resolve_breaches(distance_traveled: float) -> int:
	var cost: int = 0
	for enemy in enemies:
		if enemy["alive"] and enemy["distance"] <= distance_traveled:
			enemy["alive"] = false
			cost += CombatRules.ENEMY_BREACH_COST
	return cost
