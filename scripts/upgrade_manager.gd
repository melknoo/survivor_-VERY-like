class_name UpgradeManager
extends Node

var _db: Array = []
var _levels: Dictionary = {}  # upgrade_id -> current level (0 = not yet taken)

func _ready() -> void:
	_db = UpgradeDatabase.get_all()
	for upg in _db:
		_levels[upg["id"]] = 0

func get_upgrade_level(id: String) -> int:
	return _levels.get(id, 0)

func get_random_choices(count: int) -> Array:
	var available: Array = []
	for upg in _db:
		if _levels[upg["id"]] < upg["max_level"]:
			available.append(upg)

	if available.is_empty():
		return []

	var result: Array = []
	var pool: Array = available.duplicate()

	for _i in range(mini(count, pool.size())):
		# Build weight array based on rarity
		var weights: Array = []
		for upg in pool:
			match upg["rarity"]:
				"common":   weights.append(60.0)
				"uncommon": weights.append(30.0)
				"rare":     weights.append(10.0)
				_:          weights.append(30.0)

		var total := 0.0
		for w in weights:
			total += w

		var roll := randf() * total
		var cumulative := 0.0
		var chosen_idx := 0
		for idx in range(weights.size()):
			cumulative += weights[idx]
			if roll <= cumulative:
				chosen_idx = idx
				break

		result.append(pool[chosen_idx])
		pool.remove_at(chosen_idx)

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

func _get_upgrade(id: String) -> Dictionary:
	for upg in _db:
		if upg["id"] == id:
			return upg
	return {}
