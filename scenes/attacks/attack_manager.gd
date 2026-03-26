extends Node

const PROJECTILE_SCENE := preload("res://scenes/attacks/projectile.tscn")
const ATTACK_RANGE := 600.0

var fire_timer: Timer
var player: Node2D = null  # Parent CharacterBody2D with player.gd script

func _ready() -> void:
	player = get_parent()

	fire_timer = Timer.new()
	fire_timer.timeout.connect(_on_fire_timer)
	add_child(fire_timer)
	_update_fire_rate()
	fire_timer.start()

func _update_fire_rate() -> void:
	if player:
		fire_timer.wait_time = 1.0 / player.attack_speed
	else:
		fire_timer.wait_time = 1.0

func _on_fire_timer() -> void:
	if not player or player.is_dead:
		return

	# Update fire rate in case attack_speed changed
	_update_fire_rate()

	var target := _find_nearest_enemy()
	if not target:
		return

	_fire_at(target)

func _find_nearest_enemy() -> Node2D:
	if not player:
		return null

	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist_sq := ATTACK_RANGE * ATTACK_RANGE

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist_sq := player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = enemy

	return nearest

func _fire_at(target: Node2D) -> void:
	var container := get_tree().get_first_node_in_group("projectile_container")
	if not container:
		return

	var projectile := PROJECTILE_SCENE.instantiate()
	var direction := (target.global_position - player.global_position).normalized()
	projectile.global_position = player.global_position
	projectile.setup(direction, player.attack_damage)
	container.add_child(projectile)
