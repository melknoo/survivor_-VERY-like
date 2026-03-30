extends Node

# Singleton-like: autoloaded as "Settings" in project.godot
# Holds runtime settings and persists them to disk.

const SETTINGS_PATH := "user://settings.cfg"

var music_volume: int = 80       # 0-100
var sfx_volume: int = 100        # 0-100
var screenshake: bool = true

func _ready() -> void:
	load_settings()
	apply_to_buses()

func apply_to_buses() -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _pct_to_db(music_volume))
		AudioServer.set_bus_mute(music_idx, music_volume == 0)

	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _pct_to_db(sfx_volume))
		AudioServer.set_bus_mute(sfx_idx, sfx_volume == 0)

	var ui_idx := AudioServer.get_bus_index("UI")
	if ui_idx != -1:
		AudioServer.set_bus_volume_db(ui_idx, _pct_to_db(sfx_volume) - 5.0)
		AudioServer.set_bus_mute(ui_idx, sfx_volume == 0)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "screenshake", screenshake)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = config.get_value("settings", "music_volume", 80)
	sfx_volume   = config.get_value("settings", "sfx_volume", 100)
	screenshake  = config.get_value("settings", "screenshake", true)

func _pct_to_db(pct: int) -> float:
	# 100% → 0 dB, 50% → -6 dB, 0% → muted
	if pct <= 0:
		return -80.0
	return 20.0 * log(float(pct) / 100.0) / log(10.0)
