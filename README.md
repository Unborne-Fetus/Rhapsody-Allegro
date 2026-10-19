# Rhapsody: Allegro

A Godot action boss rush that changes between top-down and side-scrolling combat. **Version 0.8.1 — Pixel Performers.** Twelve bosses retain their painted artwork, while the four playable musicians now have original pixel-art animation atlases with individually keyed walking, idle, jumping, attack and hurt poses. Each boss has an original looping score with phase-dependent intensity. Perspective changes now animate over 1.25 seconds with moving fighters, rising platforms and a musical-staff bridge. Mobile viewport fixes, the twelve-fight campaign, fixed character kits, higher jumps and deferred parrying remain.

**[Play in your browser](https://rhapsody-allegro.r4f86c2gzg.chatgpt.site)** — private owner testing link. The browser version is a single-threaded Godot WebAssembly export of the same simulation as Windows.

## Gameplay

- **Eight tutorial lessons:** movement, melee, character ability, perfect dodge, energy recovery, resonance, platform jumping and a rehearsal boss. Progress requires completing each objective. Death retries the lesson; campaign saves and records are preserved.
- **Four characters:** choose before the run. Each owns a set, ability, passive and drawback. Character choice stays locked through fights, retries and intermissions.
- **Only the Singer fires player sound-wave projectiles.** The other three musicians have melee abilities. Parrying is deferred; its implementation remains in source.
- **Harder bosses:** more health, faster pressure, pursuit, close-range sweeps, anti-kiting mines and later-phase chains. Every attack retains a warning. Stagger openings are shorter and cannot permanently lock a boss.
- **Contextual upgrade panels:** hover, focus or tap a card to read its core mechanics, including resonance, stagger and energy. Use CHOOSE to commit.
- **Twelve-movement campaign:** difficulty selection, augmentations between bosses, saved movement checkpoints, retry score rollback and separate difficulty / assist records.
- **Training:** immortal dummy, optional attacks, manual perspective changes, range guides and damage / DPS readouts. Select a character before entering.
- **Keyboard, mouse, controller and multitouch:** aspect-preserving scaling, portrait letterboxing, focus-loss pause, configurable volume, shake, flashes and assist mode.

## Play with two thumbs

Phones automatically get a dedicated interface in portrait or landscape. The left black rail in landscape is a floating movement stick; portrait controls stay below the arena. In side view, flick it upward to jump and downward to drop through platforms; a right-side JUMP button is also available. The right thumb can slide between large DODGE and ABILITY buttons without lifting. Holding ABILITY repeats it; BREAK spends full resonance.

**AUTO starts enabled on phones.** Basic melee attacks trigger only when the boss is within reach. the Singer also fires automatically from range while preserving enough energy for a dodge. Abilities, dodges and breaks remain manual. Tap the small top-left AUTO control to disable it and expose a manual STRIKE button; the setting persists. Auto attack uses the same damage, windups, cooldowns, energy and collision rules as manual input.

Portrait has large menu cards, a separate lower control area and a camera that frames both fighters. Landscape uses the full available canvas, with a central arena and black control rails on either side. Phone characters face the boss even while retreating, and phone strikes track the boss during windup. Rotating the phone pauses a fight, clears held input and rebuilds the layout and touch targets. Completion and pause menus are centered in the new orientation with opaque backgrounds. Upgrade cards use a large inspection list plus a separate confirmation button. The tutorial includes thumb-specific instructions. Safe-area padding keeps browser controls away from notches and home indicators, page gestures are disabled on the canvas, and supported browsers can keep the screen awake. Fullscreen is optional in Settings.

## Song encounters

Open **Boss Practice → Song Encounters** to try any of these immediately, or continue the full performance after The Conductor. The original three retain their indices and records. Practice clears create personal bests without advancing campaign unlocks.

| Boss | Inspiration | Signature gameplay |
|---|---|---|
| Velvet Fuse | Tom Jones — Sexbomb | Countdown bomb chains, hollow blast rings, expanding waves |
| The Cinder King | Elvis Presley — Burning Love | Burning dash trails, flame fans, four-attack heat cycle with +20% damage overheat opening |
| The Everlasting Parade | Village People — Can't Stop the Music | Six spectral performers, alternating floor tiles and open spotlight lanes |
| The Feedback Tyrant | Quiet Riot — Cum On Feel the Noize | Gapped speaker shockwaves, amplifier walls, stage dives and a three-attack silence cycle |

Each has three named phases, its own arena and silhouette, movement behavior, telegraphs, later-phase follow-ups and projectile volleys. Encounter notes in the pause menu explain the central mechanic. These are original interpretations with synthesized effects; recordings and lyrics are not bundled.

## Characters

| Character / set | Ability | Passive | Drawback |
|---|---|---|---|
| Bram / Downbeat (Drummer) | Heavy drum shockwave | 20% damage reduction; 150 HP | Slow movement and dodge recovery |
| Vex / Groove (Bassist) | Slap-bass lunge | Up to three lingering distortion stacks | 80 HP; +15% incoming damage |
| Aria / Riff (Guitarist) | Wide power-chord sweep | Finishers restore 8 extra energy | Normal strikes build 20% less stagger |
| Lyra / Voice (Singer) | Long-range sound-wave projectile | +25% damage beyond 400 units | 75 HP; +20% incoming damage |

Bram is a hard-hitting drummer; Vex a rapid bassist; Aria a balanced guitarist; and Lyra a ranged singer. Their existing damage, movement, energy and difficulty tuning are preserved. See [character tuning](docs/WEAPONS.md) for values. All are available immediately. Each playable musician has a separate silhouette and 36 distinct sprite poses (144 total). The 40×56-pixel cells are animated based on actual combat state, not a painted PNG moved side to side. Bosses keep their existing painted atlas and original synthesized effects.

## Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD / arrows | Left stick |
| Melee combo | Hold K / left mouse | X / Square |
| Character ability | Hold J / right mouse | RT / R2 or RB / R1 |
| Inspect locked character | Q | B / Circle |
| Dodge | Space | A / Cross |
| Resonance break | E at full meter | Y / Triangle |
| Jump / drop through | W / Up; S / Down | D-pad Up / stick up; stick down |
| Pause / guide | Escape / P; H | Start; pause menu |
| Menu focus / choose | Up / Down / Tab; Enter | D-pad; A / Cross |
| Training attacks / view / guides / reset | T / V / G / R | Pause options |
| Fullscreen | F | — |

Mouse attacks aim at the pointer. Keyboard-only, controller and touch aim at the boss. Touch uses a floating left stick and labeled right-side actions; landscape is recommended. Upgrade card bodies inspect, while their buttons choose. Combat never requires matching the optional practice pulse.

## Build and develop

Use **Godot 4.5.1 standard** with matching export templates. Import `project.godot` and press F5. `build.bat` runs all six regression suites and exports Web and Windows; set `GODOT` to your executable path if it is not on PATH.

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/combat_test.gd
godot --headless --script res://tests/advanced_test.gd
godot --headless --script res://tests/input_test.gd
godot --headless --script res://tests/weapon_test.gd
godot --headless --script res://tests/song_boss_test.gd
godot --headless --script res://tests/phone_test.gd
mkdir -p build/web build/windows
touch build/.gdignore
godot --headless --export-release Web
godot --headless --export-release Windows
python3 tools/package_web.py
node tests/package.cjs
node tests/phone_browser.cjs
python3 tools/serve.py
```

Open `http://localhost:8060`. Hosted play needs no development tools. Local Godot web exports require HTTP(S), not `file://`, and WebGL 2. The single-threaded export needs no cross-origin isolation headers.

The web packager preserves the actual engine bytes, splits them into assets below static-host limits, uses content-addressed filenames, and adds a branded loader with download progress. `dist/build-info.json` records engine and game hashes. `build/web/` retains the standard Godot export; `build/windows/` contains the desktop executable.

## Verification

The six headless suites cover combat, progression, dispatched input, character/tutorial rules and song encounters. Stress simulation includes 24 minutes for the original roster and 36 minutes across every new boss, phase and difficulty. Native OpenGL captures verify the tutorial, character roster, upgrade references, and phone menus / combat in both orientations. Both release exports and the WebAssembly package are checked locally. A browser smoke test is included in CI; browser end-to-end testing is unavailable in this environment, so no successful browser playtest is claimed.

GitHub Actions builds Web and Windows artifacts and runs the browser smoke test. Optional GitHub Pages hosting uses `ENABLE_GITHUB_PAGES=true`; the private play link above is independent of Pages.

## Source

`scripts/game.gd` owns encounter flow and interface. `assets/musicians.svg` contains crisp pixel-art pose cells; `scripts/pixel_performers.gd` selects frames and `scripts/stage_art.gd` continues to draw painted bosses. `characters.gd`, `weapons.gd`, `tutorial.gd` and `mechanics.gd` define the kits, objectives and contextual reference data. `phone_ui.gd` draws the thumb interface; phone routing and camera integration use the shared game simulation. `song_bosses.gd` owns the custom encounter mechanics, attacks and vector figures; `encounters.gd` provides shared roster bounds. `run_state.gd` handles upgrades / checkpoints; `profile.gd` handles local persistence. Projectile and hazard simulation are separate, with clipped hazard rendering. Boss data lives in `data/bosses.json`.

See [foundation notes](docs/FOUNDATION.md). No third-party art or recordings are bundled. Godot's engine and default font retain upstream licenses. No license for original game source has been granted yet.

Jump launch speed is 740 units/second, up from 570 (about 69% more height at unchanged gravity). Parry input, automatic parry windows and parry upgrades are disabled through `combat_rules.gd`; the code and legacy regression coverage are retained for future development. Existing Golden Window upgrades convert to an unowned active upgrade when a checkpoint loads.

Phone canvas sizing uses the actual CSS canvas rectangle and device-pixel ratio before Godot starts. Resize / orientation observers keep the buffer aligned after safe-area changes, iframe resizing and delayed engine boot. Deterministic Node tests cover these cases; native captures cover repeated portrait-to-wide-landscape rotation. Physical mobile browser testing remains unverified in this environment.

Art, audio and transition details: [The Living Score](docs/STAGE_ART_AND_AUDIO.md).
