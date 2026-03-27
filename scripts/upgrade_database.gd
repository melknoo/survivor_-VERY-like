class_name UpgradeDatabase
extends RefCounted

# Icon positions in assets/items/items.png (352x832, 32x32 cells, 11 cols x 26 rows)
# Formula: idx = sequential item index, row = idx/11, col = idx%11, x = col*32, y = row*32
#
# Passive icons used:
#   dagger       idx=0   → Rect2(  0,   0, 32, 32)
#   rapier       idx=13  → Rect2( 64,  32, 32, 32)
#   chest plate  idx=78  → Rect2( 32, 224, 32, 32)
#   shoes        idx=83  → Rect2(192, 224, 32, 32)
#   helm         idx=91  → Rect2( 96, 256, 32, 32)
#   ankh         idx=101 → Rect2( 64, 288, 32, 32)
#   red potion   idx=115 → Rect2(160, 320, 32, 32)
#
# Weapon icons:
#   magic dagger idx=7   → Rect2(224,   0, 32, 32)  weapon_knives
#   blue staff   idx=59  → Rect2(128, 160, 32, 32)  weapon_lightning
#   cross pend.  idx=99  → Rect2(  0, 288, 32, 32)  weapon_orbiter
#   green potion idx=118 → Rect2(256, 320, 32, 32)  weapon_garlic

static func get_all() -> Array:
	return [
		# ── Passive upgrades ─────────────────────────────────────────────────
		{
			"id": "move_speed",
			"type": "passive",
			"name": "Sturmläufer",
			"description": "Bewegung +%s%%",
			"icon_region": Rect2(192, 224, 32, 32),
			"max_level": 5,
			"rarity": "common",
			"values": [8, 12, 16, 20, 25],
		},
		#{
			#"id": "max_hp",
			#"type": "passive",
			#"name": "Eisenkonstitution",
			#"description": "+%s max. Lebenspunkte",
			#"icon_region": Rect2(96, 256, 32, 32),
			#"max_level": 5,
			#"rarity": "common",
			#"values": [15, 20, 25, 30, 40],
		#},
		#{
			#"id": "hp_regen",
			#"type": "passive",
			#"name": "Wundheilung",
			#"description": "+%s HP/Sekunde",
			#"icon_region": Rect2(160, 320, 32, 32),
			#"max_level": 5,
			#"rarity": "uncommon",
			#"values": [0.5, 1.0, 1.5, 2.0, 3.0],
		#},
		#{
			#"id": "attack_damage",
			#"type": "passive",
			#"name": "Scharfe Klinge",
			#"description": "Schaden +%s%%",
			#"icon_region": Rect2(0, 0, 32, 32),
			#"max_level": 5,
			#"rarity": "common",
			#"values": [10, 15, 20, 25, 35],
		#},
		#{
			#"id": "attack_speed",
			#"type": "passive",
			#"name": "Blitzreflexe",
			#"description": "Angriff +%s%% schneller",
			#"icon_region": Rect2(64, 32, 32, 32),
			#"max_level": 5,
			#"rarity": "common",
			#"values": [8, 12, 16, 20, 25],
		#},
		#{
			#"id": "pickup_range",
			#"type": "passive",
			#"name": "Magnetismus",
			#"description": "Aufnahmeradius +%s%%",
			#"icon_region": Rect2(64, 288, 32, 32),
			#"max_level": 5,
			#"rarity": "common",
			#"values": [20, 30, 40, 50, 75],
		#},
		#{
			#"id": "armor",
			#"type": "passive",
			#"name": "Stahlhaut",
			#"description": "-%s Schaden pro Treffer",
			#"icon_region": Rect2(32, 224, 32, 32),
			#"max_level": 5,
			#"rarity": "uncommon",
			#"values": [1, 2, 3, 5, 8],
		#},
		# ── Weapons ──────────────────────────────────────────────────────────
		#{
			#"id": "weapon_knives",
			#"type": "weapon",
			#"name": "Klingen",
			#"description": "Schießt Klingen auf Feinde. Mehr Projektile & Schaden pro Level.",
			#"icon_region": Rect2(224, 0, 32, 32),
			#"max_level": 8,
			#"rarity": "uncommon",
			#"values": [1, 1, 2, 2, 3, 3, 4, 5],  # projectile count per level (display)
		#},
		#{
			#"id": "weapon_garlic",
			#"type": "weapon",
			#"name": "Knoblauch-Aura",
			#"description": "Pulsierendes Schadensfeld um den Spieler. Stößt Gegner zurück.",
			#"icon_region": Rect2(256, 320, 32, 32),
			#"max_level": 8,
			#"rarity": "rare",
			#"values": [5, 6, 8, 10, 12, 15, 18, 22],  # damage per tick (display)
		#},
		{
			"id": "weapon_orbiter",
			"type": "weapon",
			"name": "Heiliger Orbiter",
			"description": "Leuchtende Kugeln kreisen um den Spieler und treffen Feinde.",
			"icon_region": Rect2(0, 288, 32, 32),
			"max_level": 8,
			"rarity": "rare",
			"values": [1, 1, 2, 2, 3, 3, 4, 5],  # orbiter count (display)
		},
		{
			"id": "weapon_lightning",
			"type": "weapon",
			"name": "Kettenblitz",
			"description": "Blitzeinschlag auf zufälligen Feind. Ab Lv.3 Kettenblitz.",
			"icon_region": Rect2(128, 160, 32, 32),
			"max_level": 8,
			"rarity": "rare",
			"values": [25, 30, 35, 40, 50, 60, 75, 100],  # damage (display)
		},
	]
