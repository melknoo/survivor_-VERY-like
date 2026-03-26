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
  attacks/        # Projektile, Attack-Manager
  pickups/        # XP-Gems etc.
  effects/        # Partikel, Damage Numbers, Shader
  ui/             # HUD, Game Over, Menüs
scripts/          # Standalone-Skripte (Spawner, WorldGen, Camera)
assets/           # Sprites, Tilesets, Fonts, Audio – VOR Implementierung analysieren
```

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

## Performance-Regeln
- `call_deferred()` für Node-Entfernung
- Max ~50 gleichzeitige Gegner
- Object Pooling für Projektile wenn nötig
- Chunks entfernen die zu weit vom Spieler entfernt sind

## Aktueller Stand
- [ ] Grundgerüst: Welt, Spieler, Gegner, Auto-Attack, XP, HUD, Game Over
- [ ] Visual Polish: Partikel, Screenshake, Damage Numbers, Shader
- [ ] Item/Upgrade-System
- [ ] Verschiedene Gegnertypen
- [ ] Verschiedene Waffen
- [ ] Hauptmenü