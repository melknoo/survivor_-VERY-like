extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("camera")
	rng.randomize()

func _process(delta: float) -> void:
	# Camera is a child of the player — position (0,0) = always centered on player
	# Screenshake only
	if shake_timer > 0.0:
		shake_timer -= delta
		var t := shake_timer / shake_duration
		offset = Vector2(
			rng.randf_range(-shake_intensity, shake_intensity) * t,
			rng.randf_range(-shake_intensity, shake_intensity) * t
		)
	else:
		offset = Vector2.ZERO

func shake(intensity: float, duration: float) -> void:
	if not Settings.screenshake:
		return
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
