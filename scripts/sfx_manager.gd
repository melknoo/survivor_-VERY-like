extends Node

# Sound variants: each key maps to an Array of file paths.
# play() picks one at random and applies slight pitch variation.
const SOUNDS: Dictionary = {
	"knife_throw": [
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-003.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-004.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-005.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-006.wav",
	],
	"knife_hit": [
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-003.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-004.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-005.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Gore Pierce_HY_PC-006.wav",
	],
	"garlic_pulse": [
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Flare Nova_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Flare Nova_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Flare Nova_HY_PC-003.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Flare Nova_HY_PC-004.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Flare Nova_HY_PC-005.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Flare Nova_HY_PC-006.wav",
	],
	"orbiter_hit": [
		"res://assets/Sounds/DSGNMisc_SKILL IMPACT-Pebbles_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_SKILL IMPACT-Pebbles_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_SKILL IMPACT-Pebbles_HY_PC-003.wav",
		"res://assets/Sounds/DSGNMisc_SKILL IMPACT-Pebbles_HY_PC-004.wav",
		"res://assets/Sounds/DSGNMisc_SKILL IMPACT-Pebbles_HY_PC-005.wav",
		"res://assets/Sounds/DSGNMisc_SKILL IMPACT-Pebbles_HY_PC-006.wav",
	],
	"lightning_strike": [
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Electric Hit_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Electric Hit_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Electric Hit_HY_PC-003.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Electric Hit_HY_PC-004.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Electric Hit_HY_PC-005.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Electric Hit_HY_PC-006.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Voltaic Blast_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Voltaic Blast_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Voltaic Blast_HY_PC-003.wav",
	],
	"lightning_chain": [
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Shimmer Electric_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Shimmer Electric_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Shimmer Electric_HY_PC-003.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Shimmer Electric_HY_PC-004.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Shimmer Electric_HY_PC-005.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Shimmer Electric_HY_PC-006.wav",
	],
	"enemy_hit": [
		"res://assets/Sounds/DSGNMisc_HIT-Hit Noise_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Hit Noise_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Hit Noise_HY_PC-003.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Hit Rattle_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Hit Rattle_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_HIT-Hit Rattle_HY_PC-003.wav",
	],
	"enemy_die": [
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Cruncher_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Cruncher_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Cruncher_HY_PC-003.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Cruncher_HY_PC-004.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Crunchy Burst_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Crunchy Burst_HY_PC-002.wav",
	],
	"slime_split": [
		"res://assets/Sounds/DSGNMisc_CAST-Slime Ball_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_CAST-Slime Ball_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_CAST-Slime Ball_HY_PC-003.wav",
		"res://assets/Sounds/DSGNMisc_CAST-Slime Ball_HY_PC-004.wav",
		"res://assets/Sounds/DSGNMisc_CAST-Slime Ball_HY_PC-005.wav",
		"res://assets/Sounds/DSGNMisc_CAST-Slime Ball_HY_PC-006.wav",
	],
	"bat_screech": [
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Bats Flying_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Bats Flying_HY_PC-002.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Bats Flying_HY_PC-003.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Bats Flying_HY_PC-004.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Bats Flying_HY_PC-005.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Bats Flying_HY_PC-006.wav",
	],
	"player_hurt": [
		"res://assets/Sounds/DSGNImpt_MELEE-Hollow Punch_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_MELEE-Hollow Punch_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_MELEE-Hollow Punch_HY_PC-003.wav",
		"res://assets/Sounds/DSGNImpt_MELEE-Hollow Punch_HY_PC-004.wav",
		"res://assets/Sounds/DSGNImpt_MELEE-Hollow Punch_HY_PC-005.wav",
		"res://assets/Sounds/DSGNImpt_MELEE-Hollow Punch_HY_PC-006.wav",
	],
	"player_die": [
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Forced Shutdown_HY_PC-001.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Forced Shutdown_HY_PC-002.wav",
		"res://assets/Sounds/DSGNImpt_EXPLOSION-Forced Shutdown_HY_PC-003.wav",
	],
	"gold_pickup": [
		"res://assets/Sounds/DSGNTonl_SKILL IMPACT-Coin Impact_HY_PC-001.wav",
		"res://assets/Sounds/DSGNTonl_SKILL IMPACT-Coin Impact_HY_PC-002.wav",
		"res://assets/Sounds/DSGNTonl_SKILL IMPACT-Coin Impact_HY_PC-003.wav",
		"res://assets/Sounds/DSGNTonl_SKILL IMPACT-Coin Impact_HY_PC-004.wav",
		"res://assets/Sounds/DSGNTonl_SKILL IMPACT-Coin Impact_HY_PC-005.wav",
		"res://assets/Sounds/DSGNTonl_SKILL IMPACT-Coin Impact_HY_PC-006.wav",
	],
	"xp_pickup": [
		"res://assets/Sounds/DSGNTonl_USABLE-Coin Toss_HY_PC-001.wav",
		"res://assets/Sounds/DSGNTonl_USABLE-Coin Toss_HY_PC-002.wav",
		"res://assets/Sounds/DSGNTonl_USABLE-Coin Toss_HY_PC-003.wav",
		"res://assets/Sounds/DSGNTonl_USABLE-Coin Toss_HY_PC-004.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Coin Whoosh_HY_PC-001.wav",
		"res://assets/Sounds/DSGNMisc_MOVEMENT-Coin Whoosh_HY_PC-002.wav",
	],
	"level_up": [
		"res://assets/Sounds/DSGNSynth_BUFF-Mecha Level Up_HY_PC-001.wav",
		"res://assets/Sounds/DSGNSynth_BUFF-Mecha Level Up_HY_PC-002.wav",
		"res://assets/Sounds/DSGNSynth_BUFF-Mecha Level Up_HY_PC-003.wav",
	],
	"card_hover": [
		"res://assets/Sounds/DSGNTonl_INTERFACE-Tonal Click_HY_PC-001.wav",
		"res://assets/Sounds/DSGNTonl_INTERFACE-Tonal Click_HY_PC-002.wav",
		"res://assets/Sounds/DSGNTonl_INTERFACE-Tonal Click_HY_PC-003.wav",
	],
	"card_select": [
		"res://assets/Sounds/DSGNSynth_BUFF-Mecha Lock In_HY_PC-001.wav",
		"res://assets/Sounds/DSGNSynth_BUFF-Mecha Lock In_HY_PC-002.wav",
		"res://assets/Sounds/DSGNSynth_BUFF-Mecha Lock In_HY_PC-003.wav",
	],
	"button_click": [
		"res://assets/Sounds/DSGNTonl_INTERFACE-Tonal Click_HY_PC-004.wav",
		"res://assets/Sounds/DSGNTonl_INTERFACE-Tonal Click_HY_PC-005.wav",
		"res://assets/Sounds/DSGNTonl_INTERFACE-Tonal Click_HY_PC-006.wav",
	],
}

const UI_SOUNDS: Array = ["card_hover", "card_select", "button_click", "level_up"]
const MAX_CONCURRENT := 16
const MIN_REPEAT_INTERVAL := 0.05  # Debounce: same sound plays max once per 50ms

var _players: Array[AudioStreamPlayer] = []
var _last_play_time: Dictionary = {}  # sound_name -> last play timestamp (s)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for _i in range(MAX_CONCURRENT):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)

func play(sound_name: String, pitch_variation: float = 0.08, volume_db: float = 0.0) -> void:
	var variants: Array = SOUNDS.get(sound_name, [])
	if variants.is_empty():
		return

	# Debounce: prevent same sound from stacking every frame
	var now := Time.get_ticks_msec() / 1000.0
	if _last_play_time.get(sound_name, -1.0) + MIN_REPEAT_INTERVAL > now:
		return
	_last_play_time[sound_name] = now

	var path: String = variants[randi() % variants.size()]
	if not ResourceLoader.exists(path):
		return

	var player := _get_free_player()
	if not player:
		return

	player.bus = "UI" if sound_name in UI_SOUNDS else "SFX"
	player.stream = load(path)
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.volume_db = volume_db
	player.play()

# play_pitched: sets pitch directly (used for XP combo ascending tone)
func play_pitched(sound_name: String, pitch: float, volume_db: float = 0.0) -> void:
	var variants: Array = SOUNDS.get(sound_name, [])
	if variants.is_empty():
		return
	var path: String = variants[randi() % variants.size()]
	if not ResourceLoader.exists(path):
		return
	var player := _get_free_player()
	if not player:
		return
	player.bus = "SFX"
	player.stream = load(path)
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()

func _get_free_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _players:
		if not p.playing:
			return p
	return null

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_volume_db(idx, 0.0)
	if AudioServer.get_bus_index("UI") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "UI")
		AudioServer.set_bus_volume_db(idx, -5.0)
