extends Camera2D

var target_position: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("camera")
	rng.randomize()

func _process(delta: float) -> void:
	# Follow player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_position = (players[0] as Node2D).global_position

	position = target_position

	# Screenshake
	if shake_timer > 0.0:
		shake_timer -= delta
		var t := shake_timer / shake_duration
		var offset_x := rng.randf_range(-shake_intensity, shake_intensity) * t
		var offset_y := rng.randf_range(-shake_intensity, shake_intensity) * t
		offset = Vector2(offset_x, offset_y)
	else:
		offset = Vector2.ZERO

func shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
