extends BaseWeapon

const PROJECTILE_SCENE := preload("res://scenes/attacks/projectile.tscn")
const ATTACK_RANGE := 650.0

# Level stats: arrow count, cooldown (s), base damage
const LEVEL_STATS: Array = [
	{"arrows": 1, "cooldown": 1.10, "damage": 11.0},
	{"arrows": 1, "cooldown": 1.00, "damage": 13.0},
	{"arrows": 2, "cooldown": 0.95, "damage": 13.0},
	{"arrows": 2, "cooldown": 0.85, "damage": 15.0},
	{"arrows": 3, "cooldown": 0.80, "damage": 15.0},
	{"arrows": 3, "cooldown": 0.70, "damage": 17.0},
	{"arrows": 4, "cooldown": 0.65, "damage": 19.0},
	{"arrows": 5, "cooldown": 0.55, "damage": 21.0},
]

func _ready() -> void:
	weapon_id = "weapon_bow"
	weapon_name = "Bogen"
	base_damage = 11.0
	base_cooldown = 1.1
	super._ready()

func _get_stats_for_level(level: int) -> Dictionary:
	return LEVEL_STATS[clampi(level - 1, 0, LEVEL_STATS.size() - 1)]

func activate() -> void:
	var target := _find_nearest_enemy()
	if not target:
		return
	var stats := _get_stats_for_level(current_level)
	var count: int = stats["arrows"]
	_fire_at(target, count, get_effective_damage())
	SFX.play("knife_throw")

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist_sq := ATTACK_RANGE * ATTACK_RANGE
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist_sq := _player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = enemy
	return nearest

func _fire_at(target: Node2D, count: int, dmg: float) -> void:
	var container := get_tree().get_first_node_in_group("projectile_container")
	if not container:
		return
	var base_dir := (target.global_position - _player.global_position).normalized()
	var spread := deg_to_rad(8.0)
	var start_angle := -spread * (count - 1) * 0.5
	for i in range(count):
		var dir := base_dir.rotated(start_angle + i * spread)
		var proj := PROJECTILE_SCENE.instantiate()
		proj.global_position = _player.global_position
		proj.setup(dir, dmg)
		container.add_child(proj)

