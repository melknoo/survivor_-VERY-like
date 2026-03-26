extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/base_enemy.tscn")

const SPAWN_RADIUS_MIN := 650.0
const SPAWN_RADIUS_MAX := 850.0
const MAX_ENEMIES := 50
const INITIAL_INTERVAL := 2.0
const MIN_INTERVAL := 0.3

var spawn_timer: Timer
var difficulty_timer: Timer
var current_interval: float = INITIAL_INTERVAL
var spawn_count_per_wave: int = 1
var enemy_count: int = 0

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_interval
	spawn_timer.timeout.connect(_on_spawn_timer)
	add_child(spawn_timer)
	spawn_timer.start()

	difficulty_timer = Timer.new()
	difficulty_timer.wait_time = 30.0
	difficulty_timer.timeout.connect(_on_difficulty_increase)
	add_child(difficulty_timer)
	difficulty_timer.start()

func _on_spawn_timer() -> void:
	if enemy_count >= MAX_ENEMIES:
		return

	var player: Node2D = _get_player()
	if not player:
		return

	var container := _get_container()
	if not container:
		return

	for _i in range(spawn_count_per_wave):
		if enemy_count >= MAX_ENEMIES:
			break
		_spawn_enemy(player.global_position, container)

func _spawn_enemy(player_pos: Vector2, container: Node) -> void:
	var angle := randf() * TAU
	var radius := randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
	var spawn_pos := player_pos + Vector2(cos(angle), sin(angle)) * radius

	var enemy := ENEMY_SCENE.instantiate()
	enemy.position = spawn_pos
	enemy.died_signal.connect(_on_enemy_died)
	container.add_child(enemy)
	enemy_count += 1

func _on_enemy_died() -> void:
	enemy_count = max(0, enemy_count - 1)

func _on_difficulty_increase() -> void:
	# Reduce spawn interval and/or increase spawn count
	current_interval = max(MIN_INTERVAL, current_interval * 0.8)
	spawn_timer.wait_time = current_interval

	if spawn_count_per_wave < 5:
		spawn_count_per_wave += 1

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if players.size() > 0 else null

func _get_container() -> Node:
	return get_tree().get_first_node_in_group("enemies_container")
