# Rhapsody: Allegro

A 2D action boss rush that changes between top-down and side-scrolling combat during a fight. Built with **Godot 4.5.1 / GDScript**, with the same combat simulation on browser and desktop.

**[Play the browser build](https://rhapsody-allegro.r4f86c2gzg.chatgpt.site)** — private testing link; sign in with the owner account. No Godot installation needed to play.

## Playable foundation

- Three sequential bosses: **The Metronome**, **Glass Cantor**, and **The Conductor**. Each has a different attack sequence, health, speed, and visual identity.
- Each fight has three phases: top-down, side-scrolling with gravity/jumping, then top-down finale. Transitions clear hostile shots, reposition safely, and grant two seconds of protection.
- Directional three-hit melee combo, energy-based shooting, dodge with invulnerability, timed projectile reflection, and a charged resonance break.
- Telegraphs for fan volleys, radial bursts, charges, rain lanes, and crossfire. Side-scrolling projectiles use the same collision rules.
- Keyboard/mouse, keyboard-only auto-aim attacks, gamepad combat, and multitouch movement/action controls.
- Instant retries; sequential progression; unlocked-boss practice; clear rank, personal best time, and hit count.
- Saved settings and unlocks. Assist records are separate from standard records. Assist halves damage and slowly restores health.
- Pause on focus loss, adjustable effects volume, optional screen shake, fullscreen, optional practice metronome.
- Original vector prototype graphics and synthesized sound effects. No paid assets, copyrighted recordings, or network services required by gameplay.

This is a playable foundation, not a finished campaign. Story, final character art, bespoke boss animation, full songs/vocals, and deeper progression remain open for feedback. Music is not a combat requirement; the optional pulse is only a practice aid.

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick |
| Blade | Left mouse / K | X / Square |
| Fire | Hold right mouse / J | RT / R2 or RB / R1 |
| Dodge | Space | A / Cross |
| Parry | L | LB / L1 |
| Resonance break | E, full meter | Y / Triangle |
| Jump in side view | W / Up | Left stick up |
| Pause | Escape / P / top-right pause icon | Start |
| Fullscreen | F | — |
| Menu navigation | Up / Down / Tab, Enter | Start/confirm on main combat screens; mouse/keyboard for settings |

Mouse attacks aim at the pointer. Keyboard-only, touch, and gamepad attacks aim at the boss. Melee restores energy; shooting spends it. Dodge costs 24 energy. Parry lasts 0.2 seconds and reflects shots for increased damage. Burst costs 100 resonance, damages the boss, clears enemy bullets, and briefly protects you.

On touch screens, use the left side as a floating movement stick and the labeled buttons on the right. Landscape orientation is recommended. Hold FIRE to shoot; BLADE can be held for the combo.

## Develop and build

1. Install Godot **4.5.1 standard** and matching export templates.
2. Import `project.godot`, then press F6/F5 to play.
3. Export the `Web` or `Windows` preset. `build.bat` runs tests and exports both (set `GODOT` to your executable if it is not on PATH).

Command line:

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/combat_test.gd
mkdir -p build/web build/windows
godot --headless --export-release Web
godot --headless --export-release Windows
python3 tools/package_web.py
python3 tools/serve.py
```

Then open `http://localhost:8060`. Browser exports must be hosted over HTTP(S); a `file://` double-click cannot load Godot WebAssembly. The hosted play link avoids this setup. WebGL 2 is required. The export is single-threaded and needs no cross-origin isolation headers.

`tools/package_web.py` packages the actual Godot export into `dist/` and splits the engine into static chunks for hosts with per-file size limits. It does not introduce a separate JavaScript game. The standard unsplit export is in `build/web/`.

## Automatic checks and downloads

The **Build and Test Rhapsody** workflow imports the project, runs combat tests, exports Windows and Web, then boots the web export in Chromium, exercises keyboard combat and pause/resume, and uploads screenshots and both builds. Download them from the workflow's Actions page.

GitHub Pages deployment is optional: enable Pages with **GitHub Actions** as the source and set repository variable `ENABLE_GITHUB_PAGES=true`. Private-repository Pages availability depends on your GitHub plan; the private testing link above is independent of Pages.

The initial GitHub-hosted run could not start its build runner and produced no step logs. Local Godot regression tests and both exports passed; the automated browser test is provided but has not yet completed successfully.

## Source map

| File | Responsibility |
|---|---|
| `scripts/game.gd` | Scene flow, player actions, boss sequencing, arena and HUD rendering |
| `scripts/projectile.gd` | Projectile simulation and swept collision |
| `scripts/profile.gd` | Versioned saves, validated loading, unlocks and records |
| `scripts/sound.gd` | Bounded pool of original synthesized sound effects |
| `data/bosses.json` | Boss identity, health, timing, projectile speed, pattern sequence |
| `tests/combat_test.gd` | Combat, phase, save and stress regression checks |
| `tests/browser.cjs` | Real exported-browser smoke test for CI |
| `docs/FOUNDATION.md` | Design decisions, limits, feedback guide |

No third-party art or music assets are bundled. Godot's exported engine and default font retain their upstream licenses. No license for the original game source is granted by this repository yet.
