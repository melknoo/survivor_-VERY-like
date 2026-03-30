extends Node

const SPAWN_RADIUS_MIN := 650.0
const SPAWN_RADIUS_MAX := 850.0
const MAX_ENEMIES := 80

var enemy_scenes: Dictionary = {
	"skeleton": preload("res://scenes/enemies/base_enemy.tscn"),
	"bat":      preload("res://scenes/enemies/bat_enemy.tscn"),
	"slime":    preload("res://scenes/enemies/slime_enemy.tscn"),
}

# Each wave: time_start/end in seconds, entries with weight + count_min/max, interval lerp
var spawn_table: Array = [
	{
		"time_start": 0.0, "time_end": 120.0,
		"entries": [
			{"scene": "skeleton", "weight": 100, "count_min": 1, "count_max": 1},
		],
		"interval": 2.0, "interval_end": 1.2,
	},
	{
		"time_start": 120.0, "time_end": 240.0,
		"entries": [
			{"scene": "skeleton", "weight": 60, "count_min": 1, "count_max": 1},
			{"scene": "bat",      "weight": 40, "count_min": 4, "count_max": 6},
		],
		"interval": 1.5, "interval_end": 0.9,
	},
	{
		"time_start": 240.0, "time_end": 360.0,
		"entries": [
			{"scene": "skeleton", "weight": 40, "count_min": 2, "count_max": 2},
			{"scene": "bat",      "weight": 35, "count_min": 4, "count_max": 7},
			{"scene": "slime",    "weight": 25, "count_min": 1, "count_max": 1},
		],
		"interval": 1.2, "interval_end": 0.7,
	},
	{
		"time_start": 360.0, "time_end": 600.0,
		"entries": [
			{"scene": "skeleton", "weight": 35, "count_min": 3, "count_max": 3},
			{"scene": "bat",      "weight": 35, "count_min": 5, "count_max": 8},
			{"scene": "slime",    "weight": 30, "count_min": 2, "count_max": 2},
		],
		"interval": 0.8, "interval_end": 0.4,
	},
	{
		"time_start": 600.0, "time_end": 9999.0,
		"entries": [
			{"scene": "skeleton", "weight": 30, "count_min": 4, "count_max": 4},
			{"scene": "bat",      "weight": 35, "count_min": 6, "count_max": 9},
			{"scene": "slime",    "weight": 35, "count_min": 2, "count_max": 2},
		],
		"interval": 0.4, "interval_end": 0.3,
	},
]

var spawn_timer: Timer
var enemy_count: int = 0

func _ready() -> void:
	add_to_group("enemy_spawner")
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_spawn_timer)
	add_child(spawn_timer)
	spawn_timer.start()

func _get_game_time() -> float:
	var gw := get_tree().get_first_node_in_group("game_world")
	return gw.game_time if gw else 0.0

func _get_current_wave() -> Dictionary:
	var t := _get_game_time()
	for wave in spawn_table:
		if t >= float(wave["time_start"]) and t < float(wave["time_end"]):
			return wave
	return spawn_table[spawn_table.size() - 1]

func _get_current_interval(wave: Dictionary) -> float:
	var t := _get_game_time()
	var duration := float(wave["time_end"]) - float(wave["time_start"])
	var progress := clampf((t - float(wave["time_start"])) / duration, 0.0, 1.0)
	return lerpf(float(wave["interval"]), float(wave["interval_end"]), progress)

func _on_spawn_timer() -> void:
	var wave := _get_current_wave()
	spawn_timer.wait_time = maxf(0.1, _get_current_interval(wave))

	if enemy_count >= MAX_ENEMIES:
		return

	var player := _get_player()
	if not player:
		return
	var container := _get_container()
	if not container:
		return

	var entry := _weighted_pick(wave["entries"])
	if entry.is_empty():
		return

	var count := randi_range(int(entry.get("count_min", 1)), int(entry.get("count_max", entry.get("count_min", 1))))
	var base_pos := _random_spawn_pos(player.global_position)
	var is_bat: bool = entry["scene"] == "bat"

	for _i in range(count):
		if enemy_count >= MAX_ENEMIES:
			break
		var offset := Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0)) if is_bat else Vector2.ZERO
		_spawn_enemy(entry["scene"], base_pos + offset, container)

	if is_bat and randf() < 0.3:
		SFX.play("bat_screech", 0.05)

func _spawn_enemy(type: String, pos: Vector2, container: Node) -> void:
	if not enemy_scenes.has(type):
		return
	var enemy: Node = enemy_scenes[type].instantiate()
	enemy.global_position = pos
	container.add_child(enemy)
	_apply_time_scaling(enemy)
	register_enemy(enemy)

func register_enemy(enemy: Node) -> void:
	enemy.died_signal.connect(_on_enemy_died)
	enemy_count += 1

func _on_enemy_died() -> void:
	enemy_count = max(0, enemy_count - 1)

func _apply_time_scaling(enemy: Node) -> void:
	var minutes := _get_game_time() / 60.0
	if minutes < 0.1:
		return
	enemy.max_hp *= 1.0 + minutes * 0.08
	enemy.current_hp = enemy.max_hp
	enemy.damage *= 1.0 + minutes * 0.05
	enemy.move_speed = minf(enemy.move_speed * (1.0 + minutes * 0.02), enemy.move_speed * 1.5)

func _weighted_pick(entries: Array) -> Dictionary:
	var total := 0
	for e in entries:
		total += int(e["weight"])
	var r := randi() % total
	var cumulative := 0
	for e in entries:
		cumulative += int(e["weight"])
		if r < cumulative:
			return e
	return entries[entries.size() - 1]

func _random_spawn_pos(player_pos: Vector2) -> Vector2:
	var angle := randf() * TAU
	var radius := randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
	return player_pos + Vector2(cos(angle), sin(angle)) * radius

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] as Node2D if players.size() > 0 else null

func _get_container() -> Node:
	return get_tree().get_first_node_in_group("enemies_container")
