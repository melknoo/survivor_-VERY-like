class_name BaseWeapon
extends Node

var weapon_id: String = ""
var weapon_name: String = ""
var base_damage: float = 10.0
var base_cooldown: float = 1.0
var current_level: int = 1
var max_level: int = 8

var _player: Node2D = null
var _timer: Timer

func _ready() -> void:
	_player = get_parent().get_parent() as Node2D  # weapon → AttackManager → Player
	_timer = Timer.new()
	_timer.timeout.connect(_on_timer)
	add_child(_timer)
	_start_timer()

func _start_timer() -> void:
	var stats := _get_stats_for_level(current_level)
	var cd: float = stats.get("cooldown", base_cooldown)
	# Scale by player's attack_speed stat
	if _player and _player.get("base_attack_speed") != null and _player.base_attack_speed > 0.0:
		cd = cd / (_player.attack_speed / _player.base_attack_speed)
	_timer.wait_time = maxf(0.05, cd)
	_timer.start()

func _on_timer() -> void:
	if not is_instance_valid(_player) or _player.get("is_dead") == true:
		return
	activate()
	_start_timer()  # Re-evaluate cooldown each cycle (attack_speed may change)

func activate() -> void:
	pass  # Override in subclasses

func upgrade() -> void:
	if current_level < max_level:
		current_level += 1
		_on_level_changed()

func _on_level_changed() -> void:
	_start_timer()  # Default: restart timer with new cooldown

func get_effective_damage() -> float:
	var stats := _get_stats_for_level(current_level)
	var dmg: float = stats.get("damage", base_damage)
	if _player and _player.get("base_attack_damage") != null and _player.base_attack_damage > 0.0:
		dmg *= _player.attack_damage / _player.base_attack_damage
	return dmg

func _get_stats_for_level(_level: int) -> Dictionary:
	return {}  # Override in subclasses
