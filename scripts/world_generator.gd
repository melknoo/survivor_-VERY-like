extends Node2D

const CHUNK_SIZE := 512.0
const VIEW_RANGE := 3
const DECO_PER_CHUNK := 6

var chunks: Dictionary = {}
var rng := RandomNumberGenerator.new()

var deco_paths: Array[String] = [
	"res://assets/Deco/01.png",
	"res://assets/Deco/02.png",
	"res://assets/Deco/03.png",
	"res://assets/Deco/04.png",
	"res://assets/Deco/05.png",
	"res://assets/Deco/06.png",
	"res://assets/Deco/07.png",
	"res://assets/Deco/08.png",
]

var _ground_texture: Texture2D = null
var _bg_rect: ColorRect = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/ground.png"):
		_ground_texture = load("res://assets/ground.png")
	_create_background()

func _create_background() -> void:
	# Single large ColorRect with a tiling shader — much cheaper than thousands of sprites
	_bg_rect = ColorRect.new()
	_bg_rect.size = Vector2(100000.0, 100000.0)
	_bg_rect.position = Vector2(-50000.0, -50000.0)
	_bg_rect.z_index = -20

	var mat := ShaderMaterial.new()
	var shader := Shader.new()

	if _ground_texture:
		shader.code = """
shader_type canvas_item;
uniform sampler2D tile_tex : repeat_enable, filter_nearest;
uniform float tile_size = 64.0;
uniform float rect_offset_x = -50000.0;
uniform float rect_offset_y = -50000.0;
uniform float rect_size = 100000.0;

void fragment() {
	vec2 world_pos = UV * rect_size + vec2(rect_offset_x, rect_offset_y);
	vec2 tile_uv = world_pos / tile_size;
	COLOR = texture(tile_tex, tile_uv);
}
"""
		mat.set_shader_parameter("tile_tex", _ground_texture)
		mat.set_shader_parameter("tile_size", 64.0)
	else:
		# Procedural checkerboard fallback
		# TODO: Replace placeholder with actual ground texture
		shader.code = """
shader_type canvas_item;
uniform float tile_size = 64.0;
uniform float rect_offset_x = -50000.0;
uniform float rect_offset_y = -50000.0;
uniform float rect_size = 100000.0;

void fragment() {
	vec2 world_pos = UV * rect_size + vec2(rect_offset_x, rect_offset_y);
	vec2 cell = floor(world_pos / tile_size);
	float checker = mod(cell.x + cell.y, 2.0);
	vec3 dark = vec3(0.075, 0.105, 0.06);
	vec3 lighter = vec3(0.095, 0.13, 0.075);
	COLOR = vec4(mix(dark, lighter, checker), 1.0);
}
"""

	mat.shader = shader
	_bg_rect.material = mat
	add_child(_bg_rect)

func update_chunks(player_pos: Vector2) -> void:
	var cur := _world_to_chunk(player_pos)

	for x in range(cur.x - VIEW_RANGE, cur.x + VIEW_RANGE + 1):
		for y in range(cur.y - VIEW_RANGE, cur.y + VIEW_RANGE + 1):
			var coord := Vector2i(x, y)
			if not chunks.has(coord):
				_generate_chunk(coord)

	var to_remove: Array[Vector2i] = []
	for coord: Vector2i in chunks.keys():
		if abs(coord.x - cur.x) > VIEW_RANGE + 2 or abs(coord.y - cur.y) > VIEW_RANGE + 2:
			to_remove.append(coord)

	for coord in to_remove:
		if is_instance_valid(chunks[coord]):
			chunks[coord].queue_free()
		chunks.erase(coord)

func _generate_chunk(coord: Vector2i) -> void:
	var chunk := Node2D.new()
	chunk.position = Vector2(coord.x * CHUNK_SIZE, coord.y * CHUNK_SIZE)
	chunk.z_index = -10
	add_child(chunk)
	chunks[coord] = chunk

	rng.seed = hash(coord) ^ 0xDEADBEEF

	for _i in range(DECO_PER_CHUNK):
		var deco := Sprite2D.new()
		var path := deco_paths[rng.randi() % deco_paths.size()]

		if ResourceLoader.exists(path):
			deco.texture = load(path)
		else:
			# Placeholder dark stone
			# TODO: Replace placeholder
			var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.25, 0.22, 0.20, 0.75))
			deco.texture = ImageTexture.create_from_image(img)

		deco.position = Vector2(
			rng.randf_range(32.0, CHUNK_SIZE - 32.0),
			rng.randf_range(32.0, CHUNK_SIZE - 32.0)
		)
		deco.scale = Vector2.ONE * rng.randf_range(0.7, 1.4)
		deco.modulate = Color(
			rng.randf_range(0.65, 0.95),
			rng.randf_range(0.65, 0.95),
			rng.randf_range(0.55, 0.85),
			rng.randf_range(0.55, 0.85)
		)
		chunk.add_child(deco)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / CHUNK_SIZE), floori(world_pos.y / CHUNK_SIZE))
