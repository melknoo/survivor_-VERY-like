extends BaseWeapon

const LEVEL_STATS: Array = [
	{"radius":  80.0, "cooldown": 1.2, "damage":  5.0, "knockback": 20.0},
	{"radius":  90.0, "cooldown": 1.1, "damage":  6.0, "knockback": 25.0},
	{"radius": 100.0, "cooldown": 1.0, "damage":  8.0, "knockback": 30.0},
	{"radius": 115.0, "cooldown": 0.9, "damage": 10.0, "knockback": 35.0},
	{"radius": 130.0, "cooldown": 0.8, "damage": 12.0, "knockback": 40.0},
	{"radius": 145.0, "cooldown": 0.7, "damage": 15.0, "knockback": 45.0},
	{"radius": 160.0, "cooldown": 0.6, "damage": 18.0, "knockback": 50.0},
	{"radius": 180.0, "cooldown": 0.5, "damage": 22.0, "knockback": 60.0},
]

var _area: Area2D
var _col_shape: CircleShape2D
var _aura: Sprite2D

func _ready() -> void:
	weapon_id = "weapon_garlic"
	weapon_name = "Knoblauch-Aura"
	base_damage = 5.0
	base_cooldown = 1.2
	super._ready()
	_setup_area()
	_setup_aura_visual()
	tree_exiting.connect(_on_tree_exiting)

func _get_stats_for_level(level: int) -> Dictionary:
	return LEVEL_STATS[clampi(level - 1, 0, LEVEL_STATS.size() - 1)]

func _on_level_changed() -> void:
	super._on_level_changed()
	var r := _current_radius()
	_col_shape.radius = r
	if _aura:
		_aura.scale = Vector2.ONE * (r * 2.0 / 64.0)

func activate() -> void:
	var stats := _get_stats_for_level(current_level)
	var dmg := get_effective_damage()
	var knockback: float = stats["knockback"]
	_pulse()
	for body in _area.get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(dmg)
			if body.has_method("apply_knockback"):
				var dir := (body.global_position - _player.global_position).normalized()
				body.apply_knockback(dir, knockback)
	# TODO: Play SFX (garlic pulse)

func _pulse() -> void:
	if not is_instance_valid(_aura):
		return
	var base_s := _aura.scale
	var big_s := base_s * 1.18
	var tw := _aura.create_tween()
	tw.tween_property(_aura, "scale", big_s, 0.08)
	tw.tween_property(_aura, "scale", base_s, 0.10)

func _setup_area() -> void:
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2  # Enemies layer
	_area.monitoring = true
	_col_shape = CircleShape2D.new()
	_col_shape.radius = _current_radius()
	var cs := CollisionShape2D.new()
	cs.shape = _col_shape
	_area.add_child(cs)
	_player.add_child(_area)  # Follows player automatically

func _setup_aura_visual() -> void:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := (size - 1) * 0.5
	for x in range(size):
		for y in range(size):
			var dx := x - half
			var dy := y - half
			var t := sqrt(dx * dx + dy * dy) / half
			if t <= 1.0:
				var ring := 1.0 - smoothstep(0.65, 1.0, t)
				var inner := smoothstep(0.0, 0.25, t)
				img.set_pixel(x, y, Color(0.5, 0.95, 0.2, ring * inner * 0.45))
	_aura = Sprite2D.new()
	_aura.texture = ImageTexture.create_from_image(img)
	_aura.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var r := _current_radius()
	_aura.scale = Vector2.ONE * (r * 2.0 / 64.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_aura.material = mat
	_player.add_child(_aura)

func _current_radius() -> float:
	return _get_stats_for_level(current_level).get("radius", 80.0)

func _on_tree_exiting() -> void:
	if is_instance_valid(_area):
		_area.queue_free()
	if is_instance_valid(_aura):
		_aura.queue_free()
