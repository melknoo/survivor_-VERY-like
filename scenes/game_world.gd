extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/game_over.tscn")

var kill_count: int = 0
var game_time: float = 0.0
var is_game_over: bool = false

var _player: CharacterBody2D
var _hud: CanvasLayer
var _world_gen: Node2D

func _ready() -> void:
	add_to_group("game_world")
	_setup_containers()
	_setup_world_generator()
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

func _on_level_up(new_level: int) -> void:
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
