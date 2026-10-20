# Foundation — initial systems through 0.8.4

Rhapsody: Allegro uses one Godot simulation for browser and desktop. The game combines top-down and side-scrolling musical boss fights. Combat has no required beat timing. This document also preserves historical implementation notes; the up-to-date art, animation and soundtrack details are in STAGE_ART_AND_AUDIO.md.

## Gameplay revision

Four characters replace in-fight set switching. Each has a locked weapon, ability, passive and drawback; see WEAPONS.md for values. The character selection guard also applies to pause, retries, intermissions and nested menus. Only Lyra / Voice creates ranged voice-wave projectiles, while the other characters use melee abilities. Parrying is deferred.

The eight-step tutorial advances on real movement, landed attacks, defensive events, platform collision and a rehearsal boss clear. Early target lessons are immortal. Practice shots are slow, incoming tutorial damage is halved and death retries the current lesson. Tutorial completion is a profile flag; normal records, unlocks and campaign checkpoints are preserved.

Boss health is now 1500 / 2100 / 2800, with shorter recovery and faster patterns. Bosses pursue distant players, punish close approaches with telegraphed circular sweeps and target mines at distant players. Later phases add separately warned follow-up attacks. Ordinary movement freezes during windup to preserve aim readability. Stagger lasts 1.25 seconds, grants +30% damage and has a seven-second lock. Higher difficulties increase damage, speed and density.

Gold-colored warning marks telegraph an approaching attack: they do not damage during the warning period, but the affected area becomes dangerous when activated. Active beams, mines and expanding waves require movement, jumping or dodging. Parry collision behavior is preserved but disabled. Hazard rendering is clipped to the arena. All fights retain three health phases, changing perspective at 67% and 33%, clearing attacks and granting protection. Platforms support buffered jumps, coyote time and dropping through by holding down.

Augmentation cards show a side reference panel on mouse hover, keyboard/controller focus or touch inspection. The panel explains the primary mechanic and a related mechanic. All eight upgrades map to authored definitions; Resonant Core explains how resonance is earned, the 100-point threshold and the break's damage, protection and attack clearing. Inspection does not choose an upgrade; the explicit CHOOSE button does.

## Run and save integrity

Title → character / difficulty → boss → results → augmentation → next boss, for twelve movements and eleven augmentation choices. Checkpoints store character, upgrades, difficulty, assist classification, seed and totals at the beginning of a movement. Retries roll back that movement's contribution. Final campaign completion clears its checkpoint. Training cannot kill participants or create records.

Profiles remain version 1 with defaults for new fields. Save writes use a temporary file and rename. Corrupt JSON recovers safely; malformed checkpoint values and duplicate or unknown upgrades are sanitized. Older weapon choices map to characters and missing choices default to Aria. Assist records remain separately classified even if assist is later turned off.

## Validation

Headless suites cover combat, all characters, projectile exclusivity, abilities, passives, selection locks, tutorial objectives and completion isolation, reference data and dispatched keyboard/mouse/multitouch input. Stress simulations cover every boss/difficulty with bounded objects and finite physics for 60 simulated minutes. Native OpenGL captures cover tutorial, characters, reference panels and the existing screens.

Web and Windows release exports share the tested source. The hosted package test checks byte-identical valid WebAssembly assembly, MIME, host size limits, asset fallthrough and failed-chunk handling. A Chromium smoke test is maintained for CI. Browser end-to-end testing was unavailable in this development environment, so physical browser/device input, audio and performance remain for player testing.

## Song expansion

The original indices 0–2 remain stable. Four song-inspired encounters are appended at 3–6; normal progression now ends at index 6. Roster data drives save bounds, unlock limits and finale behavior. Direct practice exposes the four additions immediately while keeping campaign unlocks separate. Existing checkpoints at original movements remain valid.

`encounters.gd` loads the shared roster. `song_bosses.gd` owns per-fight heat / volume state, custom patterns, movement destinations, vector figures and arenas. Retrying creates a fresh encounter state. Perspective changes and stagger cancel pending follow-up chains. Hazards warn before activation, are visible throughout their delay and obey the 24-object budget. Wave gaps account for the player's radius; hollow rings have collision-tested safe interiors. Floor tiles remain jumpable in side view. Every new boss has a projectile volley pattern.

Cinder's four flame attacks trigger 3.8 seconds of immobility and +20% incoming damage; existing fire still resolves. Tyrant's three loud attacks trigger 3.4 seconds of immobility while existing soundwaves resolve. These openings use simulation time and pause with the game. Pattern pressure and wave count increase by phase; volleys also use difficulty speed and density. The parade's floor pattern preserves a completely clear column, and spotlight lanes have explicit gaps.

See SONG_BOSSES.md for the concepts, attack catalog and source song attribution.

## Phone interface

Coarse touch devices select the phone interface at boot. Landscape keeps a 720-unit height and expands its logical width to the actual canvas aspect ratio. Portrait keeps a 720-unit width and expands its height for tall phones. A portrait camera frames the player and boss horizontally, zooming out promptly when they separate and easing closer when they approach. The clipped hazard layer receives the identical arena transform. Combat simulation retains its original arena coordinates.

Touch routing tracks the movement finger independently from right-thumb actions. Sliding into a new action activates it once; leaving the hit region clears held fire. Releasing or cancelling a touch, losing focus or rotating cannot leave a held action behind. Orientation changes pause encounters. Changes to the presentation size clear touch ownership and pause an active encounter. Menu actions use large targets and portrait cards.

Phone auto attacks are an optional saved input preference, enabled by default. They call the same existing strike / ranged-ability methods and never modify damage or timing. Lyra's automatic ranged ability reserves dodge energy, and the tutorial's ability objective still requires a manual skill input. Basic melee auto attacks can satisfy its three-hit objective. The manual strike button appears when auto is disabled. Character selection locks remain enforced in every phone menu.

Phone regressions dispatch simultaneous touch and drag events in both orientations, covering action slides, jump / drop gestures, target reach, auto-ranged energy reserve, manual control, contextual upgrade confirmation, focus / rotation cleanup and camera alignment. Native phone captures use 390×844 and 844×390 windows. Browser-specific touch feel, audio, fullscreen and wake-lock behavior still require physical device testing.

## Movement and deferred parry revision

Jump launch speed rises from 570 to 740 units/second with gravity unchanged at 1500. The nominal apex rises from about 108 to 183 units. The tutorial's first platform is now reachable from the floor through real jump physics. Coyote time, buffering and drop-through remain.

AUTO is a small top-left HUD button with a larger invisible touch target, independent of the movement area. The header shifts right to keep it readable. The former parry control is hidden in both touch layouts; the manual strike button uses that freed space when automatic attacks are off.

`combat_rules.gd` keeps parry disabled by default. Keyboard, controller, touch, automatic saber windows, stale timers and projectile collision all respect the gate. The implementation and opt-in legacy tests remain. The parry tutorial becomes a two-hit energy-recovery lesson, Golden Window is excluded from new choices, and old checkpoints convert it to an unowned active upgrade. Aria's current passive restores 8 extra energy on finishers, while her future riposte implementation is retained behind the gate.

## Rotation, side rails and facing

On touch browsers, `rhapsodyPrepareCanvas` runs before Engine creation and switches canvas sizing to external ownership. ResizeObserver, visual-viewport / window events and orientation settling callbacks synchronize the backing buffer to the canvas CSS rectangle times device-pixel ratio. A width/height MutationObserver also repairs Godot's initial project-size assignment after a slow download. Desktop retains Godot's normal adaptive policy. The game reads the same CSS rectangle on web, uses a reentry guard when rebuilding its logical viewport, and fills the full canvas without inaccessible engine letterboxing.

Landscape reserves at least 200 logical units per rail. Wider screens use their additional space for wider black rails. The arena and clipped hazards share a centered transform; HUD and menus adapt separately. Joystick and button hit areas live entirely inside the rails. Menus translate both their drawing and registered hit rectangles into the same centered coordinates. Portrait controls anchor to the bottom of the taller viewport. Opaque phone overlays prevent underlying HUD text from appearing through the result screen.

Phone facing follows the current boss direction independently from movement, input source and AUTO. Pending phone melee strikes also update their direction toward the boss; desktop attack commitment remains unchanged. Phone regression tests cover facing while retreating / jumping, repeated rotations in fights and completion menus, full viewport coverage and control containment inside both rails. `tests/phone_browser.cjs` covers canvas sizing at multiple pixel ratios, embedded viewport sizes, repeated rotation and late engine initialization without claiming a real browser playtest.


## Musical encore and mobile viewport — 0.7.0

The Godot root window, rather than a separately sampled CSS rectangle, supplies the logical aspect ratio. Phone presentation uses viewport scaling so all rendering and input share the same extent. The browser constrains the CSS canvas to the smaller of the document and visual viewport, subtracts safe-area insets, then derives the backing buffer at device pixel ratio. Resize observers, delayed orientation updates and late engine-boot repair remain. All action circles, including manual STRIKE and JUMP together, are tested against physical viewport bounds through repeated portrait, landscape and ultrawide rotations. AUTO stays top-left; parrying remains disabled.

Game packs use content-addressed filenames and an explicit `mainPack` engine setting to prevent a previous release's pack surviving a cached download. Five new non-parry upgrades keep all eleven intermissions selectable. Song movement speeds and sound pitches live in encounter data rather than a four-entry array. Existing saves retain original encounter indices; the new bounds extend to movement twelve.


The Living Score (0.8.0) adds painted musician art, twelve original boss scores, saved music preferences and a protected 1.25-second animated form modulation. See `docs/STAGE_ART_AND_AUDIO.md` for implementation and verification.
