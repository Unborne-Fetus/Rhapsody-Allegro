# Rhapsody: Allegro

A Godot action boss rush that changes between top-down and side-scrolling combat. **Version 0.2** adds a complete run loop and substantially deeper combat to the original playable slice.

**[Play in your browser](https://rhapsody-allegro.r4f86c2gzg.chatgpt.site)** — private owner testing link. The game is a real single-threaded Godot WebAssembly export, sharing its simulation with the Windows build.

## What you can play

- **Three distinct bosses, nine boss/difficulty combinations.** The Metronome has clockwork volleys, charges and shockwaves; Glass Cantor controls space with prism beams, crystal rain and mines; The Conductor combines sweeps, spirals and crossfire. Each has a different silhouette and movement.
- **Three combat phases per fight.** At 67% and 33% health, the arena shifts between top-down movement and side-scrolling with gravity, jumping and one-way platforms. Transitions clear bullets/hazards and grant protection.
- **Three ranged weapons available immediately.** Needle fires accurate rapid shots; Chorus fires a three-shot spread; Rail spends more energy on a heavy precision bolt. Switching preserves recovery, so it cannot bypass fire rates.
- **Blade combos and dash strikes.** Three-hit melee combo, wider third hit, bonus reach/damage during a dodge. Successful melee restores energy, encouraging both ranges.
- **Parry, perfect dodge, resonance, stagger, style.** Reflect bullets for increased damage; narrowly dodge danger to gain resonance; spend a full meter on a clearing burst. Build stagger to interrupt the boss and open a two-second +30% damage window. Vary actions to grow style and score.
- **A full three-movement performance.** Choose Allegro, Virtuoso or Maestro; defeat a boss; pick one of three augmentations; continue with your build. Eight possible augmentations include blade/ranged damage, vitality/energy capacity, dodge efficiency, parry timing, healing-on-blade-hit and resonance gain.
- **Saved checkpoints and records.** Continue at the start of the current movement with your upgrades and totals. Boss personal bests are separated by difficulty and assist use. Retrying a cleared fight rolls back its contribution to prevent duplicate score.
- **Training arena.** Invulnerable player and immortal dummy, fast resonance regeneration, optional boss attacks, manual perspective switching, no unlocks or records. Try all three weapons safely.
- **A complete first-test interface.** Title, difficulty selection, boss select, augmentation interlude, combat guide, pause/retry, results, saved settings, reduced impact flashes, sound volume, screen shake and assist mode.
- **Keyboard/mouse, keyboard-only, controller and multitouch.** Controller menus support D-pad navigation. The game pauses on focus loss and clears virtual input to prevent stuck touches.

Art is original vector prototype art with animated boss silhouettes and a player character. Effects are original synthesized sounds. Music integration, final character art, story and a larger campaign remain open for feedback. The optional metronome is a practice aid; combat never requires matching a beat.

## Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD / arrows | Left stick |
| Blade / combo | Hold K / click left mouse | X / Square |
| Fire | Hold J / right mouse | RT / R2 or RB / R1 |
| Switch ranged weapon | Q | B / Circle |
| Dodge | Space | A / Cross |
| Parry | L | LB / L1 |
| Resonance break | E, full meter | Y / Triangle |
| Jump in side view | W / Up | D-pad Up or flick left stick up |
| Drop through a platform | S / Down | Left stick down |
| Pause | Escape / P / pause icon | Start |
| Combat guide | H | Pause menu |
| Fullscreen | F | — |
| Menu selection | Up / Down / Tab, Enter | D-pad, A / Cross |
| Training attacks | T | — |
| Training perspective | V | — |

Mouse attacks aim at the pointer. Keyboard-only, touch and controller attacks aim at the boss. Landscape is recommended for touch. Training also has ATK and VIEW touch buttons, plus controller-accessible pause options. Left side is a floating movement stick; labeled action buttons appear on the right, including weapon switching. In side view, the virtual stick can point down to drop through platforms.

## Build and develop

Use **Godot 4.5.1 standard** with matching export templates. Import `project.godot` and press F5. `build.bat` runs all three regression suites and exports Web and Windows; set `GODOT` to your executable path if it is not on PATH.

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/combat_test.gd
godot --headless --script res://tests/advanced_test.gd
godot --headless --script res://tests/input_test.gd
mkdir -p build/web build/windows
touch build/.gdignore
godot --headless --export-release Web
godot --headless --export-release Windows
python3 tools/package_web.py
node tests/package.cjs
python3 tools/serve.py
```

Open `http://localhost:8060`. Hosted play needs no development tools. Local Godot web exports require HTTP(S), not `file://`, and WebGL 2. The single-threaded export needs no cross-origin isolation headers.

The web packager preserves the actual engine bytes, splits them into assets below static-host limits, uses content-addressed filenames, and adds a branded loader with download progress. `dist/build-info.json` records engine and game hashes. `build/web/` retains the standard Godot export; `build/windows/` contains the desktop executable.

## Verification and automation

- **Combat tests:** base combat rules, all boss patterns, perspective shifts, protection, parry/burst, assist, save recovery and six minutes of stress simulation.
- **Advanced tests:** weapons, augmentation options, corrupted checkpoints, stagger, perfect-dodge gating, hazards, platform collision, coyote jumping, retry score rollback, campaign progression, training isolation, assist-record classification and **18 additional minutes** across all boss/difficulty combinations.
- **Input integration:** 20 checks dispatch keyboard, mouse and multitouch events through Godot, including portrait letterboxing, menu transitions, firing, pause/guide return paths, two-finger controls and mobile training toggles.
- **Native presentation:** `tests/presentation_test.gd` captures title, difficulty, training, all bosses, side view, touch, interlude, settings and guide using a real OpenGL renderer.
- **Hosted package test:** engine assembly must be byte-identical valid WebAssembly with correct MIME, size limits, asset fallthrough and readable missing-file failures.
- **Browser CI:** `tests/browser.cjs` boots the exported build in Chromium and exercises starting a run, movement, firing, dodge, weapon switching, pause/resume and the guide, with screenshots.

The GitHub Actions workflow exports both builds and uploads them and browser screenshots. The initial hosted runner failed before any build steps started, so no successful browser playtest is claimed. Local combat/advanced/input tests, real native rendering, and both exports have been verified. Browser/device-specific input, audio and performance still need first-player feedback.

Optional GitHub Pages: enable Pages with GitHub Actions as source and set `ENABLE_GITHUB_PAGES=true`. Availability for a private repo depends on the GitHub plan. The private play link above is independent of Pages.

## Source map

| File | Responsibility |
|---|---|
| `scripts/game.gd` | Scene flow, player actions, encounter sequencing and interface |
| `scripts/run_state.gd` | Difficulty/weapon/upgrade tuning, run totals and checkpoint validation |
| `scripts/hazard.gd` | Telegraph/active/lifetime/collision rules for area attacks |
| `scripts/hazard_view.gd` | Clipped hazard rendering that preserves HUD readability |
| `scripts/projectile.gd` | Projectile simulation and swept collision |
| `scripts/profile.gd` | Validated local saves, unlocks, difficulty and assist-separated records |
| `scripts/sound.gd` | Bounded voice pool of synthesized sound effects |
| `data/bosses.json` | Boss identity, health, timing and attack sequence |
| `docs/FOUNDATION.md` | Design and implementation notes |

No third-party art or recordings are bundled. Godot's exported engine and default font retain their upstream licenses. No license for the original game source is granted yet.
