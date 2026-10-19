# Rhapsody: Allegro

A Godot action boss rush that changes between top-down and side-scrolling combat. **Version 0.5** adds four song-inspired encounters to the existing three-boss roster, with a seven-movement campaign and direct practice access. The tutorial, locked character kits and contextual upgrade explanations remain.

**[Play in your browser](https://rhapsody-allegro.r4f86c2gzg.chatgpt.site)** — private owner testing link. The browser version is a single-threaded Godot WebAssembly export of the same simulation as Windows.

## Gameplay

- **Eight tutorial lessons:** movement, melee, character ability, perfect dodge, parry, resonance, platform jumping and a rehearsal boss. Progress requires completing each objective. Death retries the lesson; campaign saves and records are preserved.
- **Four characters:** choose before the run. Each owns a set, ability, passive and drawback. Character choice stays locked through fights, retries and intermissions.
- **Only Horizon fires player bullets.** The other three characters have melee abilities and absorb parried projectiles. Lyra can reflect them.
- **Harder bosses:** more health, faster pressure, pursuit, close-range sweeps, anti-kiting mines and later-phase chains. Every attack retains a warning. Stagger openings are shorter and cannot permanently lock a boss.
- **Contextual upgrade panels:** hover, focus or tap a card to read its core mechanics, including resonance, stagger and energy. Use CHOOSE to commit.
- **Seven-movement campaign:** difficulty selection, augmentations between bosses, saved movement checkpoints, retry score rollback and separate difficulty / assist records.
- **Training:** immortal dummy, optional attacks, manual perspective changes, range guides and damage / DPS readouts. Select a character before entering.
- **Keyboard, mouse, controller and multitouch:** aspect-preserving scaling, portrait letterboxing, focus-loss pause, configurable volume, shake, flashes and assist mode.

## Song encounters

Open **Boss Practice → Song Encounters** to try any of these immediately, or continue the full performance after The Conductor. The original three retain their indices and records. Practice clears create personal bests without advancing campaign unlocks.

| Boss | Inspiration | Signature gameplay |
|---|---|---|
| Velvet Fuse | Tom Jones — Sexbomb | Countdown bomb chains, hollow blast rings, expanding waves |
| The Cinder King | Elvis Presley — Burning Love | Burning dash trails, flame fans, four-attack heat cycle with +20% damage overheat opening |
| The Everlasting Parade | Village People — Can't Stop the Music | Six spectral performers, alternating floor tiles and open spotlight lanes |
| The Feedback Tyrant | Quiet Riot — Cum On Feel the Noize | Gapped speaker shockwaves, amplifier walls, stage dives and a three-attack silence cycle |

Each has three named phases, its own arena and silhouette, movement behavior, telegraphs, later-phase follow-ups and parryable volleys. Encounter notes in the pause menu explain the central mechanic. These are original interpretations with synthesized effects; recordings and lyrics are not bundled.

## Characters

| Character / set | Ability | Passive | Drawback |
|---|---|---|---|
| Bram / Breaker | Heavy area slam | 20% damage reduction; 150 HP | Slow movement and dodge recovery |
| Vex / Flurry | Knife lunge | Up to three bleeding stacks | 80 HP; +15% incoming damage |
| Aria / Cadence | Saber sweep with parry window | Parry empowers next strike by 50% | Normal strikes build 20% less stagger |
| Lyra / Horizon | Long-range marksman shot | +25% shot damage beyond 400 units | 75 HP; +20% incoming damage |

Bram is slow and close with high impact; Vex is extremely fast and close with light hits; Aria has balanced mid-range saber attacks; Lyra has long reach and modest shot damage / cadence. See [character tuning](docs/WEAPONS.md) for values. All are available immediately. Original vector prototype art and synthesized effects remain; final animation, music, story and campaign expansion are open for feedback.

## Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD / arrows | Left stick |
| Melee combo | Hold K / left mouse | X / Square |
| Character ability | Hold J / right mouse | RT / R2 or RB / R1 |
| Inspect locked character | Q | B / Circle |
| Dodge | Space | A / Cross |
| Parry | L | LB / L1 |
| Resonance break | E at full meter | Y / Triangle |
| Jump / drop through | W / Up; S / Down | D-pad Up / stick up; stick down |
| Pause / guide | Escape / P; H | Start; pause menu |
| Menu focus / choose | Up / Down / Tab; Enter | D-pad; A / Cross |
| Training attacks / view / guides / reset | T / V / G / R | Pause options |
| Fullscreen | F | — |

Mouse attacks aim at the pointer. Keyboard-only, controller and touch aim at the boss. Touch uses a floating left stick and labeled right-side actions; landscape is recommended. Upgrade card bodies inspect, while their buttons choose. Combat never requires matching the optional practice pulse.

## Build and develop

Use **Godot 4.5.1 standard** with matching export templates. Import `project.godot` and press F5. `build.bat` runs all five regression suites and exports Web and Windows; set `GODOT` to your executable path if it is not on PATH.

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/combat_test.gd
godot --headless --script res://tests/advanced_test.gd
godot --headless --script res://tests/input_test.gd
godot --headless --script res://tests/weapon_test.gd
godot --headless --script res://tests/song_boss_test.gd
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

## Verification

The five headless suites cover combat, progression, dispatched input, character/tutorial rules and song encounters. Stress simulation includes 24 minutes for the original roster and 36 minutes across every new boss, phase and difficulty. Native OpenGL captures verify the tutorial, character roster and upgrade references. Both release exports and the WebAssembly package are checked locally. A browser smoke test is included in CI; browser end-to-end testing is unavailable in this environment, so no successful browser playtest is claimed.

GitHub Actions builds Web and Windows artifacts and runs the browser smoke test. Optional GitHub Pages hosting uses `ENABLE_GITHUB_PAGES=true`; the private play link above is independent of Pages.

## Source

`scripts/game.gd` owns encounter flow and interface. `characters.gd`, `weapons.gd`, `tutorial.gd` and `mechanics.gd` define the kits, objectives and contextual reference data. `song_bosses.gd` owns the custom encounter mechanics, attacks and vector figures; `encounters.gd` provides shared roster bounds. `run_state.gd` handles upgrades / checkpoints; `profile.gd` handles local persistence. Projectile and hazard simulation are separate, with clipped hazard rendering. Boss data lives in `data/bosses.json`.

See [foundation notes](docs/FOUNDATION.md). No third-party art or recordings are bundled. Godot's engine and default font retain upstream licenses. No license for original game source has been granted yet.
