extends Node

const WEAPON_SCRIPTS: Dictionary = {
	"weapon_knives":    "res://scenes/attacks/weapons/knives_weapon.gd",
	"weapon_garlic":    "res://scenes/attacks/weapons/garlic_weapon.gd",
	"weapon_orbiter":   "res://scenes/attacks/weapons/orbiter_weapon.gd",
	"weapon_lightning": "res://scenes/attacks/weapons/lightning_weapon.gd",
	"weapon_bow":       "res://scenes/attacks/weapons/bow_weapon.gd",
}

var _weapons: Dictionary = {}  # weapon_id -> BaseWeapon node

func _ready() -> void:
	# Starting weapon is determined by the selected character
	var char_data: Dictionary = Progression.get_selected_char_data()
	add_or_upgrade_weapon(char_data["weapon"])

func add_or_upgrade_weapon(weapon_id: String) -> void:
	if _weapons.has(weapon_id):
		_weapons[weapon_id].upgrade()
	else:
		_add_weapon(weapon_id)

func _add_weapon(weapon_id: String) -> void:
	if not WEAPON_SCRIPTS.has(weapon_id):
		push_warning("Unknown weapon_id: " + weapon_id)
		return
	var weapon := Node.new()
	weapon.set_script(load(WEAPON_SCRIPTS[weapon_id]))
	weapon.name = weapon_id
	add_child(weapon)
	_weapons[weapon_id] = weapon

func has_weapon(weapon_id: String) -> bool:
	return _weapons.has(weapon_id)

func get_weapon_level(weapon_id: String) -> int:
	if _weapons.has(weapon_id):
		return _weapons[weapon_id].current_level
	return 0
