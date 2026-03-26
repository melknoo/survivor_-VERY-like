class_name UpgradeDatabase
extends RefCounted

# Icon positions in assets/items/items.png (352x832, 32x32 cells, 11 cols x 26 rows)
# Index → row = idx / 11, col = idx % 11 → x = col*32, y = row*32
#
# Used icons (item index → Rect2):
#   1.a  dagger        idx=0   → Rect2(0,   0,   32, 32)
#   2.c  rapier        idx=13  → Rect2(64,  32,  32, 32)
#   13.f chest plate   idx=78  → Rect2(32,  224, 32, 32)
#   15.a shoes         idx=83  → Rect2(192, 224, 32, 32)
#   16.e helm          idx=91  → Rect2(96,  256, 32, 32)
#   17.g ankh          idx=101 → Rect2(64,  288, 32, 32)
#   20.b red potion    idx=115 → Rect2(160, 320, 32, 32)

static func get_all() -> Array:
	return [
		{
			"id": "move_speed",
			"name": "Sturmläufer",
			"description": "Bewegung +%s%%",
			"icon_region": Rect2(192, 224, 32, 32),
			"max_level": 5,
			"rarity": "common",
			"values": [8, 12, 16, 20, 25],
		},
		{
			"id": "max_hp",
			"name": "Eisenkonstitution",
			"description": "+%s max. Lebenspunkte",
			"icon_region": Rect2(96, 256, 32, 32),
			"max_level": 5,
			"rarity": "common",
			"values": [15, 20, 25, 30, 40],
		},
		{
			"id": "hp_regen",
			"name": "Wundheilung",
			"description": "+%s HP/Sekunde",
			"icon_region": Rect2(160, 320, 32, 32),
			"max_level": 5,
			"rarity": "uncommon",
			"values": [0.5, 1.0, 1.5, 2.0, 3.0],
		},
		{
			"id": "attack_damage",
			"name": "Scharfe Klinge",
			"description": "Schaden +%s%%",
			"icon_region": Rect2(0, 0, 32, 32),
			"max_level": 5,
			"rarity": "common",
			"values": [10, 15, 20, 25, 35],
		},
		{
			"id": "attack_speed",
			"name": "Blitzreflexe",
			"description": "Angriff +%s%% schneller",
			"icon_region": Rect2(64, 32, 32, 32),
			"max_level": 5,
			"rarity": "common",
			"values": [8, 12, 16, 20, 25],
		},
		{
			"id": "pickup_range",
			"name": "Magnetismus",
			"description": "Aufnahmeradius +%s%%",
			"icon_region": Rect2(64, 288, 32, 32),
			"max_level": 5,
			"rarity": "common",
			"values": [20, 30, 40, 50, 75],
		},
		{
			"id": "armor",
			"name": "Stahlhaut",
			"description": "-%s Schaden pro Treffer",
			"icon_region": Rect2(32, 224, 32, 32),
			"max_level": 5,
			"rarity": "uncommon",
			"values": [1, 2, 3, 5, 8],
		},
	]
