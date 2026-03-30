extends Area2D

@export var target_radius: float = 200.0
@export var nova_damage: float = 15.0

var _col_shape: CircleShape2D
var _hit_bodies: Array = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Player only
	monitoring = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	_col_shape = CircleShape2D.new()
	_col_shape.radius = 0.1
	var col := CollisionShape2D.new()
	col.shape = _col_shape
	add_child(col)

	body_entered.connect(_on_body_entered)

	_expand()

func _expand() -> void:
	# Grow collision shape
	var tw := create_tween()
	tw.tween_method(
		func(r: float) -> void: _col_shape.radius = r,
		0.1, target_radius, 0.35
	)
	tw.tween_callback(queue_free)

	# Visual ring
	_spawn_ring_visual()

func _spawn_ring_visual() -> void:
	var effects := get_tree().get_first_node_in_group("effects_container")
	if not effects:
		return

	# Build a circle from a Line2D
	var ring := Line2D.new()
	ring.global_position = global_position
	ring.width = 4.0
	ring.default_color = Color(0.8, 0.05, 0.05, 0.9)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat
	ring.z_index = 5
	effects.add_child(ring)

	const SEGMENTS := 40
	var tw := ring.create_tween()

	# Expand ring over 0.35s, then fade out
	for step in range(20):
		var t := float(step) / 19.0
		var r := target_radius * t
		var pts := PackedVector2Array()
		for i in range(SEGMENTS + 1):
			var a := TAU * float(i) / float(SEGMENTS)
			pts.append(Vector2(cos(a), sin(a)) * r)
		tw.tween_callback(func() -> void: ring.points = pts)
		tw.tween_interval(0.35 / 20.0)

	tw.tween_property(ring, "modulate:a", 0.0, 0.2)
	tw.tween_callback(ring.queue_free)

	# Fill glow disk
	var glow_disk := GPUParticles2D.new()
	glow_disk.global_position = global_position
	glow_disk.amount = 24
	glow_disk.lifetime = 0.5
	glow_disk.one_shot = true
	glow_disk.explosiveness = 0.9
	glow_disk.emitting = true
	var pmat := ParticleProcessMaterial.new()
	pmat.spread = 180.0
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = target_radius * 0.5
	pmat.initial_velocity_min = target_radius * 0.8
	pmat.initial_velocity_max = target_radius * 1.2
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 4.0
	pmat.scale_max = 8.0
	pmat.color = Color(0.9, 0.05, 0.05)
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	glow_disk.texture = ImageTexture.create_from_image(img)
	glow_disk.process_material = pmat
	var dmat := CanvasItemMaterial.new()
	dmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_disk.material = dmat
	effects.add_child(glow_disk)
	var cleanup := Timer.new()
	cleanup.wait_time = 1.2
	cleanup.one_shot = true
	cleanup.timeout.connect(glow_disk.queue_free)
	glow_disk.add_child(cleanup)
	cleanup.start()

func _on_body_entered(body: Node2D) -> void:
	if _hit_bodies.has(body):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		_hit_bodies.append(body)
		body.take_damage(nova_damage)
