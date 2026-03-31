extends Node

signal run_gold_changed(amount: int)

const SAVE_PATH := "user://progression.cfg"

# Characters defined here — all future chars can be added to this dict
const CHARS: Dictionary = {
	# Sprite coordinates are 0-based (row 0 / col 0 oben links).
	"rogue":  {"name": "Diebin",        "sprite_col": 3, "sprite_row": 0, "hp": 100, "speed": 150.0, "damage": 10.0, "weapon": "weapon_knives",    "unlock_cost": 0}, # 1.d rogue
	"bowman": {"name": "Bogenschütze",  "sprite_col": 2, "sprite_row": 0, "hp": 85,  "speed": 145.0, "damage": 11.0, "weapon": "weapon_orbiter",   "unlock_cost": 0}, # 1.c ranger
	"tank":   {"name": "Ritter",        "sprite_col": 0, "sprite_row": 0, "hp": 160, "speed": 90.0,  "damage": 8.0,  "weapon": "weapon_garlic",    "unlock_cost": 150}, # 1.a dwarf/knight-sprite
	"mage":   {"name": "Magierin",      "sprite_col": 1, "sprite_row": 4, "hp": 70,  "speed": 130.0, "damage": 14.0, "weapon": "weapon_lightning", "unlock_cost": 200}, # 5.b male wizard
}

# Permanent upgrade definitions
const PERM_UPGRADES: Dictionary = {
	"hp":     {"name": "Max HP",          "max_level": 5, "costs": [50, 100, 150, 200, 300], "hp_per_level": 10},
	"damage": {"name": "Schaden",         "max_level": 5, "costs": [75, 125, 175, 250, 350], "pct_per_level": 5.0},
	"speed":  {"name": "Geschwindigkeit", "max_level": 5, "costs": [50, 100, 150, 200, 300], "pct_per_level": 3.0},
}

var total_gold: int = 0
var run_gold: int = 0
var selected_char: String = "rogue"
var unlocked_chars: Array = ["rogue", "bowman"]
var perm_levels: Dictionary = {"hp": 0, "damage": 0, "speed": 0}

func _ready() -> void:
	load_data()

# ── Run management ──────────────────────────────────────────────────────────

func add_run_gold(amount: int) -> void:
	run_gold += amount
	emit_signal("run_gold_changed", run_gold)

func end_run() -> void:
	total_gold += run_gold
	run_gold = 0
	save()

# ── Character access ─────────────────────────────────────────────────────────

func get_selected_char_data() -> Dictionary:
	return CHARS.get(selected_char, CHARS["rogue"])

func is_char_unlocked(char_id: String) -> bool:
	return char_id in unlocked_chars

func get_char_unlock_cost(char_id: String) -> int:
	return CHARS.get(char_id, {}).get("unlock_cost", 0)

# ── Permanent bonuses ────────────────────────────────────────────────────────

func get_perm_bonus_hp() -> int:
	return perm_levels.get("hp", 0) * PERM_UPGRADES["hp"]["hp_per_level"]

func get_perm_bonus_damage_pct() -> float:
	return perm_levels.get("damage", 0) * PERM_UPGRADES["damage"]["pct_per_level"]

func get_perm_bonus_speed_pct() -> float:
	return perm_levels.get("speed", 0) * PERM_UPGRADES["speed"]["pct_per_level"]

# ── Shop purchases ───────────────────────────────────────────────────────────

func can_afford(cost: int) -> bool:
	return total_gold >= cost

func buy_perm_upgrade(type: String) -> bool:
	var data: Dictionary = PERM_UPGRADES.get(type, {})
	if data.is_empty():
		return false
	var lvl: int = perm_levels.get(type, 0)
	if lvl >= data["max_level"]:
		return false
	var cost: int = data["costs"][lvl]
	if total_gold < cost:
		return false
	total_gold -= cost
	perm_levels[type] = lvl + 1
	save()
	return true

func buy_char_unlock(char_id: String) -> bool:
	if char_id in unlocked_chars:
		return false
	var cost: int = get_char_unlock_cost(char_id)
	if total_gold < cost:
		return false
	total_gold -= cost
	unlocked_chars.append(char_id)
	save()
	return true

func get_perm_upgrade_cost(type: String) -> int:
	var data: Dictionary = PERM_UPGRADES.get(type, {})
	if data.is_empty():
		return 0
	var lvl: int = perm_levels.get(type, 0)
	if lvl >= data["max_level"]:
		return -1  # maxed
	return data["costs"][lvl]

# ── Persistence ──────────────────────────────────────────────────────────────

func save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "total_gold", total_gold)
	config.set_value("progress", "unlocked_chars", unlocked_chars)
	config.set_value("progress", "selected_char", selected_char)
	config.set_value("progress", "perm_hp", perm_levels["hp"])
	config.set_value("progress", "perm_damage", perm_levels["damage"])
	config.set_value("progress", "perm_speed", perm_levels["speed"])
	config.save(SAVE_PATH)

func load_data() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	total_gold     = config.get_value("progress", "total_gold", 0)
	unlocked_chars = config.get_value("progress", "unlocked_chars", ["rogue", "bowman"])
	selected_char  = config.get_value("progress", "selected_char", "rogue")
	perm_levels["hp"]     = config.get_value("progress", "perm_hp", 0)
	perm_levels["damage"] = config.get_value("progress", "perm_damage", 0)
	perm_levels["speed"]  = config.get_value("progress", "perm_speed", 0)
