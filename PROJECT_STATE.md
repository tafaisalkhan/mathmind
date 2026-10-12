# Math Mind Project State

## Project

- Godot project: `C:\Users\Supreme Traders\Documents\interview\mathmind`
- Engine: Godot 4.7.2 under `Downloads\Godot_Engine`.
- Main scene: `scenes/main.tscn`.
- Menu: `scenes/menu.tscn`.
- World selector: `scenes/level_select.tscn`.

## Navigation

Intended flow: `Menu Play` -> `level_select.tscn` -> choose a world card -> `main.tscn`.

Worlds in `scripts/level_select.gd`: Jungle 1-200, Ice Land 201-400, Ocean 401-600, Mountain 601-800, Volcano 801-1000. The previous card-based selector is restored. Do not replace it with a new Easy/Medium/Hard selector without explicit user confirmation.

`scripts/menu.gd` Play must open `level_select.tscn`, not `main.tscn` directly.

## Audio

`scripts/audio_manager.gd` uses `assets/sound/background_music.wav`, `coin_sound.wav`, `level_complete.mp3`, `level_fail.mp3`, and `star_sound.mp3`. `scripts/main.gd` has hooks for level start, coin, completion, and failure. Preserve them.

## Puzzle rendering issue

Reported issue: selected levels sometimes show no equation numbers or draggable bank numbers. Fix this in `scripts/main.gd`, `scripts/grid_tile.gd`, `scripts/number_tile.gd`, or the level-data path—not by changing navigation. `main.gd` gets `cells` and `bank` from `LevelDataScript.get_level(level_num)`, then instantiates `scenes/grid_tile.tscn` and `scenes/number_tile.tscn` into the GridContainer and BankContainer.

## Validation

Use the actual executable:

`C:\Users\Supreme Traders\Downloads\Godot_Engine\Godot_v4.7.2-stable_win64.exe`

Headless editor check:

```powershell
& 'C:\Users\Supreme Traders\Downloads\Godot_Engine\Godot_v4.7.2-stable_win64.exe' --headless --editor --path . --quit
```

Windows testing is requested. An Android device is connected, but do not switch to device testing unless asked.

## Collaboration rules

- Preserve the existing world selector and audio behavior.
- Inspect the running puzzle screen and data path before changing menus.
- Test the actual Windows project after edits.
## Latest handoff (2026-10-12)

### Puzzle rendering fix

- The blank equation/bank issue was hardened at the data-to-UI boundary.
- `scripts/grid_tile.gd` converts `val` and `target` values to strings.
- `scripts/number_tile.gd` converts bank values to strings.
- `scripts/main.gd` preloads `scenes/grid_tile.tscn` and `scenes/number_tile.tscn` as fallbacks when exported scene references are unavailable.
- Godot headless editor and headless runtime checks completed without reported errors.

### Audio status

- `AudioManager` is an autoload and uses the files in `assets/sound`.
- `background_music.wav` starts when music is enabled.
- `star_sound.mp3` plays at level start.
- `coin_sound.wav` plays when reward coins arrive.
- `level_complete.mp3` plays on victory.
- `level_fail.mp3` plays when the player reaches zero coins.
- Music and SFX default to enabled and are persisted in `GameState`.
- The user asked to play the sounds they placed in `assets/sound`; verify audible playback on the physical device and only change event mappings if requested.

### Android device deployment

- Physical device: Realme RMX3760, serial `0H74119I23101F6F`.
- Package: `com.mathmind.game`.
- APK: `build/mathmind-debug.apk`.
- A fresh debug APK was exported, installed successfully with `adb install -r`, and launched through `com.godot.game.GodotAppLauncher`.
- The application process was confirmed running after launch.
