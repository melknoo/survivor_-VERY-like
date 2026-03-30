extends Area2D

var xp_value: int = 5
var _is_attracted: bool = false
var _is_collecting: bool = false
var _player_ref: Node2D = null
var _attract_speed: float = 80.0
var _sprite: Sprite2D
var _glow: CanvasItemMaterial

func _ready() -> void:
	add_to_group("xp_gem")
	collision_layer = 8  # Pickups
	collision_mask = 0

	_setup_sprite()
	call_deferred("_setup_collision")

	# Check if already in pickup range on spawn
	call_deferred("_check_initial_attraction")

func _setup_sprite() -> void:
	_sprite = Sprite2D.new()

	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/items/Full Spritesheets/pixelquest16-july-2025-cave.png")
	atlas.region = Rect2(32, 16, 16, 16)  # Row 2, Col 3 — green gem
	_sprite.texture = atlas
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	add_child(_sprite)

	# Idle bob tween
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_sprite, "position:y", -3.0, 0.6).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_sprite, "position:y", 3.0, 0.6).set_ease(Tween.EASE_IN_OUT)

func _setup_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	col.shape = shape
	add_child(col)

func _check_initial_attraction() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var p := players[0] as Node2D
	var dist := global_position.distance_to(p.global_position)
	if dist <= p.pickup_range + 10.0:
		attract_to(p)

func attract_to(target: Node2D) -> void:
	_is_attracted = true
	_player_ref = target

func _physics_process(delta: float) -> void:
	if not _is_attracted or not is_instance_valid(_player_ref) or _is_collecting:
		return

	var dir: Vector2 = _player_ref.global_position - global_position
	var dist := dir.length()

	if dist < 8.0:
		_is_collecting = true
		_collect()
		return

	_attract_speed = lerp(_attract_speed, 600.0, delta * 3.0)
	global_position += dir.normalized() * _attract_speed * delta

func _collect() -> void:
	collision_layer = 0  # Prevent double-collection

	var combo := 1
	if _player_ref and _player_ref.has_method("increment_pickup_combo"):
		combo = _player_ref.increment_pickup_combo()
	var pitch := 1.0 + clampf((combo - 1) * 0.06, 0.0, 0.8)
	SFX.play_pitched("xp_pickup", pitch)

	if _player_ref and _player_ref.has_method("add_xp"):
		_player_ref.add_xp(xp_value)

	# Spawn collect sparks
	var effects := get_tree().get_first_node_in_group("effects_container")
	if effects:
		var sparks := GPUParticles2D.new()
		sparks.global_position = global_position
		sparks.amount = 6
		sparks.lifetime = 0.3
		sparks.one_shot = true
		sparks.explosiveness = 0.95
		sparks.emitting = true

		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0, -1, 0)
		mat.spread = 180.0
		mat.initial_velocity_min = 30.0
		mat.initial_velocity_max = 80.0
		mat.gravity = Vector3(0, 100, 0)
		mat.scale_min = 1.5
		mat.scale_max = 3.0
		mat.color = Color(0.2, 1.0, 0.4)

		var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		sparks.texture = ImageTexture.create_from_image(img)
		sparks.process_material = mat

		var canvas_mat := CanvasItemMaterial.new()
		canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sparks.material = canvas_mat
		effects.add_child(sparks)

		# Self-cleaning timer on sparks node
		var cleanup := Timer.new()
		cleanup.wait_time = 1.0
		cleanup.one_shot = true
		cleanup.timeout.connect(sparks.queue_free)
		sparks.add_child(cleanup)
		cleanup.start()

	# Bounce-then-vanish on sprite
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.8, 1.8), 0.07)
	tween.tween_property(_sprite, "scale", Vector2(0.0, 0.0), 0.1)
	tween.tween_callback(queue_free)
