extends Node

var _player: AudioStreamPlayer
var _current_track: String = ""

func _ready() -> void:
	_ensure_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"
	_player.volume_db = -10.0
	add_child(_player)

func play_track(path: String, fade_in: float = 1.0) -> void:
	if _current_track == path:
		return
	_current_track = path
	if not ResourceLoader.exists(path):
		return
	var tw := create_tween()
	if _player.playing:
		tw.tween_property(_player, "volume_db", -40.0, 0.5)
		tw.tween_callback(func() -> void:
			_player.stream = load(path)
			_player.play()
		)
	else:
		_player.volume_db = -40.0
		_player.stream = load(path)
		_player.play()
	tw.tween_property(_player, "volume_db", -10.0, fade_in)

func stop(fade_out: float = 1.0) -> void:
	_current_track = ""
	var tw := create_tween()
	tw.tween_property(_player, "volume_db", -40.0, fade_out)
	tw.tween_callback(_player.stop)

func _ensure_bus() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_volume_db(idx, -10.0)
