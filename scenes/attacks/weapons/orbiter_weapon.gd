extends BaseWeapon

const LEVEL_STATS: Array = [
	{"count": 1, "radius":  70.0, "damage": 12.0, "speed": 5.5},
	{"count": 1, "radius":  75.0, "damage": 15.0, "speed": 6.0},
	{"count": 2, "radius":  80.0, "damage": 15.0, "speed": 6.5},
	{"count": 2, "radius":  85.0, "damage": 18.0, "speed": 7.0},
	{"count": 3, "radius":  90.0, "damage": 20.0, "speed": 7.5},
	{"count": 3, "radius":  95.0, "damage": 24.0, "speed": 8.0},
	{"count": 4, "radius": 100.0, "damage": 28.0, "speed": 8.5},
	{"count": 5, "radius": 110.0, "damage": 35.0, "speed": 9.0},
]

const HIT_COOLDOWN := 0.5  # seconds per enemy before re-hit

var _angle: float = 0.0
var _orbiters: Array = []
var _hit_times: Dictionary = {}  # instance_id -> Time (ms) when cooldown expires

func _ready() -> void:
	weapon_id = "weapon_orbiter"
	weapon_name = "Heiliger Orbiter"
	base_damage = 12.0
	base_cooldown = 999.0  # Timer unused — damage via collision
	super._ready()
	_timer.stop()  # Orbiters use physics collision, not a fire timer
	_rebuild_orbiters()
	tree_exiting.connect(_on_tree_exiting)

func _get_stats_for_level(level: int) -> Dictionary:
	return LEVEL_STATS[clampi(level - 1, 0, LEVEL_STATS.size() - 1)]

func _on_level_changed() -> void:
	_rebuild_orbiters()

func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return
	var stats := _get_stats_for_level(current_level)
	var speed_scale: float = float(_player.move_speed) / float(_player.base_move_speed)
	_angle += float(stats["speed"]) * speed_scale * delta
	var count := _orbiters.size()
	if count == 0:
		return
	for i in range(count):
		var orbiter := _orbiters[i] as Area2D
		if not is_instance_valid(orbiter):
			continue
		var offset_angle := _angle + TAU / count * i
		orbiter.position = Vector2(cos(offset_angle), sin(offset_angle)) * float(stats["radius"])

func _rebuild_orbiters() -> void:
	for o in _orbiters:
		if is_instance_valid(o):
			o.queue_free()
	_orbiters.clear()
	var stats := _get_stats_for_level(current_level)
	for _i in range(int(stats["count"])):
		_orbiters.append(_make_orbiter())

func _make_orbiter() -> Area2D:
	var orb := Area2D.new()
	orb.collision_layer = 4   # PlayerProjectiles
	orb.collision_mask = 2    # Enemies
	orb.monitoring = true

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	col.shape = shape
	orb.add_child(col)

	# Glowing orb visual
	var sprite := Sprite2D.new()
	var img := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	var c := 6.5
	for x in range(14):
		for y in range(14):
			var d := Vector2(x - c, y - c).length() / c
			if d <= 1.0:
				img.set_pixel(x, y, Color(0.7, 0.85, 1.0, (1.0 - d) * 0.9))
	sprite.texture = ImageTexture.create_from_image(img)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = mat
	orb.add_child(sprite)

	# Particle trail
	var trail := GPUParticles2D.new()
	trail.amount = 4
	trail.lifetime = 0.18
	trail.emitting = true
	trail.z_index = -1
	var pmat := ParticleProcessMaterial.new()
	pmat.spread = 25.0
	pmat.initial_velocity_min = 8.0
	pmat.initial_velocity_max = 22.0
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 1.5
	pmat.scale_max = 3.0
	pmat.color = Color(0.6, 0.8, 1.0, 0.5)
	var ti := Image.create(3, 3, false, Image.FORMAT_RGBA8)
	ti.fill(Color.WHITE)
	trail.texture = ImageTexture.create_from_image(ti)
	trail.process_material = pmat
	trail.material = mat.duplicate()
	orb.add_child(trail)

	orb.body_entered.connect(_on_orbiter_body_entered.bind(orb))

	# Direct child of player — position is in player's local space, zero-lag follow
	_player.add_child(orb)

	# Set initial local position immediately so it doesn't spawn at player origin for one frame
	var count := _orbiters.size()
	var angle_offset := TAU / (count + 1) * count
	var stats := _get_stats_for_level(current_level)
	orb.position = Vector2(cos(_angle + angle_offset), sin(_angle + angle_offset)) * float(stats["radius"])

	return orb

func _on_orbiter_body_entered(body: Node2D, _orb: Area2D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("enemies"):
		return
	var eid := body.get_instance_id()
	var now := Time.get_ticks_msec()
	if _hit_times.get(eid, 0) > now:
		return
	_hit_times[eid] = now + int(HIT_COOLDOWN * 1000)
	if body.has_method("take_damage"):
		body.take_damage(get_effective_damage())
	# TODO: Play SFX (orbiter hit)

func _on_tree_exiting() -> void:
	for o in _orbiters:
		if is_instance_valid(o):
			o.queue_free()
