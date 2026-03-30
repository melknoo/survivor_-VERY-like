# Vampire Survivors Clone – Godot 4 Projekt

## Projekt-Überblick
Ein Vampire-Survivors-artiges 2D-Spiel mit Pixel-Art-Ästhetik im Stil von Balatro/Vampire Survivors. Gebaut in Godot 4.3+ mit GDScript.

## Tech-Stack
- **Engine:** Godot 4.3+
- **Sprache:** GDScript (kein C#, kein C++)
- **Rendering:** 2D, Compatibility Renderer
- **Auflösung:** 1920×1080, Stretch Mode `canvas_items`
- **Texture Filter:** `Nearest` (Pixel-Art, keine Interpolation)

## Projektstruktur
```
scenes/           # Alle .tscn Szenen-Dateien
  player/         # Spieler-Szene und Skript
  enemies/        # Gegner-Szenen und Skripte
  attacks/        # Projektile, Attack-Manager, Waffen
    base_weapon.gd          # Basis-Klasse für alle Waffen (extends Node)
    attack_manager.gd       # Verwaltet aktive Waffen-Nodes
    weapons/
      knives_weapon.gd      # Projektil-Waffe mit Fächer
      garlic_weapon.gd      # Aura-Waffe mit Knockback
      orbiter_weapon.gd     # Kreisende Kugeln
      lightning_weapon.gd   # Blitz mit Chain Lightning
  pickups/        # XP-Gems etc.
  effects/        # Partikel, Damage Numbers, Shader
  ui/             # HUD, Game Over, Menüs, Level-Up-Screen, Stats-Screen
scripts/          # Standalone-Skripte (Spawner, WorldGen, Camera)
  upgrade_database.gd  # Alle Upgrades + Waffen (type: "passive" | "weapon")
  upgrade_manager.gd   # Weighted random selection, apply logic
assets/           # Sprites, Tilesets, Fonts, Audio – VOR Implementierung analysieren
```

## Waffen-System

### Architektur
- `BaseWeapon` (extends Node) — Basis-Klasse: Timer, `activate()`, `upgrade()`, `get_effective_damage()`
- `AttackManager` (extends Node, Child des Spielers) — hält alle aktiven Waffen als Children
- Waffen werden via `add_or_upgrade_weapon(weapon_id)` hinzugefügt/geupgraded
- Waffen-Damage skaliert mit `player.attack_damage / player.base_attack_damage`
- Waffen-Cooldown skaliert mit `player.attack_speed`

### Implementierte Waffen
| ID | Name | Mechanik |
|----|------|---------|
| `weapon_knives` | Klingen | Projektil(e) auf nächsten Gegner, Fächer bei Lv3+ |
| `weapon_garlic` | Knoblauch-Aura | Pulse-Aura, trifft alle Gegner im Radius + Knockback |
| `weapon_orbiter` | Heiliger Orbiter | Area2D-Kugeln kreisen um Spieler, Collision-Damage |
| `weapon_lightning` | Kettenblitz | Blitz auf zufälligen Gegner, Chain ab Lv3 |

### Upgrade-Integration
- `upgrade_database.gd`: Einträge haben `"type": "passive"` oder `"type": "weapon"`
- Waffen ohne `%s` in `description` werden direkt angezeigt (level_up_screen unterstützt beide)
- Waffen erscheinen im Level-Up-Screen: neu = `"✦ NEU ✦"`, vorhanden = `"Lv. X → Y"`
- `upgrade_manager._levels["weapon_knives"] = 1` beim Start (Standardwaffe)
- Selection-Regeln: max. 1 neue Waffe, mind. 1 Passiv-Option

## Coding-Konventionen

### GDScript
- Immer statisch typisierte Variablen: `var speed: float = 200.0`
- Export-Variablen für alle tweakbaren Werte: `@export var speed: float = 200.0`
- Signale als Kommunikation zwischen Nodes, keine direkten Referenzen über mehrere Ebenen
- `class_name` am Anfang jedes Skripts für Type Hints
- Snake_case für Variablen und Funktionen, PascalCase für Klassen
- Kein Autoload/Singleton – Kommunikation über Signale und Groups

### Szenen (.tscn)
- Godot 4 Textformat mit korrekten `uid://`-Referenzen
- Jede Szene so unabhängig wie möglich (keine harten Pfad-Abhängigkeiten)
- Root-Node-Name = Dateiname (player.tscn → Root-Node "Player")

### Kollisions-Layer
- Layer 1: Spieler
- Layer 2: Gegner
- Layer 3: Spieler-Projektile
- Layer 4: Pickups (XP-Gems)

### Groups
- `"player"` – Spieler-Node
- `"enemies"` – Alle Gegner
- `"enemy_spawner"` – EnemySpawner-Node (für `register_enemy()` aus Slime-Split)

## Art Direction / Visueller Stil
- **Pixel-Art** mit crisp Pixels, kein Smoothing
- **Dunkle Farbpalette** (Balatro-Feeling): dunkle Grün-/Blau-/Brauntöne als Basis, kräftige Akzentfarben
- **Juice überall:** Screenshake, Partikel, Damage Numbers, Hit-Flash, Tweens auf UI-Elementen
- **Vignette** am Bildschirmrand
- Platzhalter mit `# TODO: Replace placeholder` markieren

## Assets
Der `assets/`-Ordner enthält heruntergeladene Assets. Vor jeder Implementierung:
1. Ordner rekursiv durchsuchen
2. Bilder öffnen und analysieren (Dimensionen, Tile-/Frame-Größe, Sprite-Sheet-Layout)
3. Passende Assets den Spielelementen zuordnen
4. Nur Code-Platzhalter nutzen wenn kein passendes Asset vorhanden ist

## Gegner-System

### Basis-Klasse (`base_enemy.gd`)
- `enemy_type: String` — Typ-Kennzeichnung ("skeleton", "bat", "slime")
- `knockback_resistance: float` — 0.0 = voller Knockback, 1.0 = immun; skaliert `apply_knockback`
- `_add_animation_row(frames, name, path, count, fw, fh, speed, loop, row)` — lädt Frames aus einer bestimmten Zeile eines Sprite-Sheets

### Gegner-Typen
| Typ | Szene | HP | Speed | Besonderheit |
|-----|-------|----|-------|--------------|
| Skeleton | `base_enemy.tscn` | 20 | 80 | Standard, Enemy_Animations_Set |
| Bat | `bat_enemy.tscn` | 8 | 150 | Sinus-Flattern, spawnt als Schwarm 4-7, `Enemy Sprites 48x48/Enemy_015.png` |
| Slime (groß) | `slime_enemy.tscn` | 45 | 45 | KR 0.7, teilt sich bei Tod in 2 kleine |
| Slime (klein) | `slime_enemy.tscn` | 15 | 75 | KR 0.3, `is_small=true`, `can_split=false` |

### Spawn-System (`enemy_spawner.gd`)
- **Spawn-Tabelle**: 5 Zeitphasen (0-2min, 2-4, 4-6, 6-10, 10+), jede Phase hat weighted entries und lineares Interval-Lerp
- `register_enemy(enemy)`: verbindet `died_signal` + inkrementiert `enemy_count` — wird auch von Slime-Split aufgerufen
- **Zeitscaling**: ab Minute 1 → HP +8%/min, Damage +5%/min, Speed +2%/min (max 1.5×)
- `game_time` wird von `game_world` (Group `"game_world"`) gelesen

## Performance-Regeln
- `call_deferred()` für Node-Entfernung
- Max 80 gleichzeitige Gegner
- Object Pooling für Projektile wenn nötig
- Chunks entfernen die zu weit vom Spieler entfernt sind

## Aktueller Stand
- [x] Grundgerüst: Welt, Spieler, Gegner, Auto-Attack, XP, HUD, Game Over
- [x] Visual Polish: Partikel, Screenshake, Damage Numbers, Shader
- [x] Item/Upgrade-System (passive Upgrades + Level-Up-Screen)
- [x] Waffen-System: Knives, Garlic, Orbiter, Lightning
- [x] Verschiedene Gegnertypen: Skeleton, Bat (Schwarm), Slime (Split-Mechanik)
- [x] Zeitbasiertes Spawn-System mit Spawn-Tabelle + Stat-Scaling
- [ ] Hauptmenü