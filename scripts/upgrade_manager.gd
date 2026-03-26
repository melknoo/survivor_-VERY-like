class_name UpgradeManager
extends Node

var _db: Array = []
var _levels: Dictionary = {}  # upgrade_id -> current level (0 = not yet taken)

func _ready() -> void:
	_db = UpgradeDatabase.get_all()
	for upg in _db:
		_levels[upg["id"]] = 0
	# Player always starts with knives at level 1
	_levels["weapon_knives"] = 1

func get_upgrade_level(id: String) -> int:
	return _levels.get(id, 0)

func get_all_upgrades() -> Array:
	return _db

# Returns up to `count` upgrade choices following these rules:
#  - At least 1 passive if available
#  - At most 1 new (unowned) weapon
#  - Already-owned weapon upgrades count as normal choices
func get_random_choices(count: int) -> Array:
	var passives: Array = []
	var new_weapons: Array = []      # type=weapon, level=0
	var weapon_upgrades: Array = []  # type=weapon, level>0 and <max

	for upg in _db:
		var lvl: int = _levels[upg["id"]]
		if lvl >= upg["max_level"]:
			continue
		var utype: String = upg.get("type", "passive")
		if utype == "weapon":
			if lvl == 0:
				new_weapons.append(upg)
			else:
				weapon_upgrades.append(upg)
		else:
			passives.append(upg)

	if passives.is_empty() and new_weapons.is_empty() and weapon_upgrades.is_empty():
		return []

	var result: Array = []
	var remaining := count

	# Guarantee 1 passive first
	if not passives.is_empty() and remaining > 0:
		var p := _weighted_pick(passives)
		result.append(p)
		passives.erase(p)
		remaining -= 1

	# At most 1 new weapon
	if not new_weapons.is_empty() and remaining > 0:
		result.append(_weighted_pick(new_weapons))
		remaining -= 1

	# Fill rest from passives + weapon upgrades
	var fill: Array = passives + weapon_upgrades
	while remaining > 0 and not fill.is_empty():
		var pick := _weighted_pick(fill)
		result.append(pick)
		fill.erase(pick)
		remaining -= 1

	result.shuffle()
	return result

func apply_upgrade(upgrade_id: String, player: Node) -> void:
	var upg := _get_upgrade(upgrade_id)
	if upg.is_empty():
		return

	var cur_lvl: int = _levels[upgrade_id]
	if cur_lvl >= upg["max_level"]:
		return

	_levels[upgrade_id] = cur_lvl + 1
	var new_lvl: int = _levels[upgrade_id]
	var val: float = float(upg["values"][new_lvl - 1])

	if player.has_method("apply_upgrade_stat"):
		player.apply_upgrade_stat(upgrade_id, val)

func _weighted_pick(pool: Array) -> Dictionary:
	var weights: Array = []
	for upg in pool:
		match upg.get("rarity", "common"):
			"common":   weights.append(60.0)
			"uncommon": weights.append(30.0)
			"rare":     weights.append(10.0)
			_:          weights.append(30.0)

	var total := 0.0
	for w in weights:
		total += w

	var roll := randf() * total
	var cumulative := 0.0
	for idx in range(weights.size()):
		cumulative += weights[idx]
		if roll <= cumulative:
			return pool[idx]

	return pool[pool.size() - 1]

func _get_upgrade(id: String) -> Dictionary:
	for upg in _db:
		if upg["id"] == id:
			return upg
	return {}
