extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over.tscn")
const LEVEL_UP_SCREEN_SCRIPT := preload("res://scenes/ui/level_up_screen.gd")

var kill_count: int = 0
var game_time: float = 0.0
var is_game_over: bool = false

var _player: CharacterBody2D
var _hud: CanvasLayer
var _world_gen: Node2D
var _upgrade_manager: Node
var _level_up_queue: Array = []
var _level_up_screen_open: bool = false

func _ready() -> void:
	add_to_group("game_world")
	_setup_containers()
	_setup_world_generator()
	_setup_upgrade_manager()
	_setup_player()
	_setup_camera()
	_setup_enemy_spawner()
	_setup_hud()
	_setup_vignette()

func _setup_containers() -> void:
	for entry in [
		["Enemies", "enemies_container"],
		["Projectiles", "projectile_container"],
		["Pickups", "pickups_container"],
		["Effects", "effects_container"],
	]:
		var node := Node2D.new()
		node.name = entry[0]
		node.add_to_group(entry[1])
		add_child(node)

func _setup_upgrade_manager() -> void:
	_upgrade_manager = Node.new()
	_upgrade_manager.name = "UpgradeManager"
	_upgrade_manager.set_script(preload("res://scripts/upgrade_manager.gd"))
	add_child(_upgrade_manager)

func _setup_world_generator() -> void:
	_world_gen = Node2D.new()
	_world_gen.name = "WorldGenerator"
	_world_gen.set_script(preload("res://scripts/world_generator.gd"))
	add_child(_world_gen)

func _setup_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector2.ZERO
	add_child(_player)
	_player.died.connect(_on_player_died)
	_player.level_up.connect(_on_level_up)

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.set_script(preload("res://scripts/camera_controller.gd"))
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0
	cam.zoom = Vector2(2.5, 2.5)  # Zoom in for pixel art feel
	add_child(cam)

func _setup_enemy_spawner() -> void:
	var spawner := Node.new()
	spawner.name = "EnemySpawner"
	spawner.set_script(preload("res://scripts/enemy_spawner.gd"))
	add_child(spawner)

func _setup_hud() -> void:
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)

	_player.hp_changed.connect(_hud.update_hp)
	_player.xp_changed.connect(_hud.update_xp)
	_player.level_changed.connect(_hud.update_level)

func _setup_vignette() -> void:
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 4  # Below HUD (layer 5) so UI stays crisp

	var vignette_rect := ColorRect.new()
	vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float v = smoothstep(0.55, 1.35, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * 0.78);
}"""
	mat.shader = shader
	vignette_rect.material = mat

	vignette_layer.add_child(vignette_rect)
	add_child(vignette_layer)

func _process(delta: float) -> void:
	if is_game_over:
		return
	game_time += delta

	if _hud:
		_hud.update_time(game_time)

	if _world_gen and _player:
		_world_gen.update_chunks(_player.global_position)

func increment_kill_count() -> void:
	kill_count += 1
	if _hud:
		_hud.update_kills(kill_count)

func _on_player_died() -> void:
	is_game_over = true
	Engine.time_scale = 0.3

	# Wait 1.5 real seconds (slow-mo effect)
	await get_tree().create_timer(1.5, true, false, true).timeout

	Engine.time_scale = 1.0
	get_tree().paused = false

	var go := GAME_OVER_SCENE.instantiate()
	go.setup(game_time, kill_count, _player.current_level if _player else 1)
	add_child(go)

func _on_level_up(_new_level: int) -> void:
	# Full-screen flash
	var layer := CanvasLayer.new()
	layer.layer = 20
	var rect := ColorRect.new()
	rect.color = Color(1.0, 1.0, 1.0, 0.35)
	rect.anchors_preset = Control.PRESET_FULL_RECT
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.4)
	tween.tween_callback(layer.queue_free)

	# Queue level-up and show screen if not already open
	_level_up_queue.append(true)
	if not _level_up_screen_open:
		_show_next_level_up()

func _show_next_level_up() -> void:
	if _level_up_queue.is_empty():
		return
	_level_up_queue.pop_front()

	var choices: Array = _upgrade_manager.get_random_choices(3)
	if choices.is_empty():
		# All upgrades maxed – skip screen
		_show_next_level_up()
		return

	_level_up_screen_open = true
	get_tree().paused = true

	var screen := CanvasLayer.new()
	screen.set_script(LEVEL_UP_SCREEN_SCRIPT)
	add_child(screen)
	screen.setup(choices, _upgrade_manager)
	screen.upgrade_chosen.connect(_on_upgrade_chosen.bind(screen))

func _on_upgrade_chosen(upgrade_id: String, screen: CanvasLayer) -> void:
	# screen calls queue_free() itself after emitting, disconnect is automatic
	_upgrade_manager.apply_upgrade(upgrade_id, _player)
	get_tree().paused = false
	_level_up_screen_open = false

	if not _level_up_queue.is_empty():
		# Brief pause before next card screen
		await get_tree().create_timer(0.25).timeout
		_show_next_level_up()
