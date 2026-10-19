# Foundation, version 0.6

Rhapsody: Allegro uses one Godot simulation for browser and desktop. The prototype combines action boss fights with top-down / side-scrolling transitions. Combat has no required beat timing. Final art, story and soundtrack remain open for feedback.

## Gameplay revision

Four characters replace in-fight set switching. Each has a locked weapon, ability, passive and drawback; see WEAPONS.md for values. The character selection guard also applies to pause, retries, intermissions and nested menus. Only Lyra / Horizon creates friendly projectiles, including reflected shots. Other parries absorb hostile bullets.

The eight-step tutorial advances on real movement, landed attacks, defensive events, platform collision and a rehearsal boss clear. Early target lessons are immortal. Practice shots are slow, incoming tutorial damage is halved and death retries the current lesson. Tutorial completion is a profile flag; normal records, unlocks and campaign checkpoints are preserved.

Boss health is now 1500 / 2100 / 2800, with shorter recovery and faster patterns. Bosses pursue distant players, punish close approaches with telegraphed circular sweeps and target mines at distant players. Later phases add separately warned follow-up attacks. Ordinary movement freezes during windup to preserve aim readability. Stagger lasts 1.25 seconds, grants +30% damage and has a seven-second lock. Higher difficulties increase damage, speed and density.

Gold hazard warnings never damage. Active beams, mines and expanding waves require movement, jumping or dodging; only projectiles can be parried. Hazard rendering is clipped to the arena. All fights retain three health phases, changing perspective at 67% and 33%, clearing attacks and granting protection. Platforms support buffered jumps, coyote time and dropping through by holding down.

Augmentation cards show a side reference panel on mouse hover, keyboard/controller focus or touch inspection. The panel explains the primary mechanic and a related mechanic. All eight upgrades map to authored definitions; Resonant Core explains how resonance is earned, the 100-point threshold and the break's damage, protection and attack clearing. Inspection does not choose an upgrade; the explicit CHOOSE button does.

## Run and save integrity

Title → character / difficulty → boss → results → augmentation → next boss, for seven movements and six augmentation choices. Checkpoints store character, upgrades, difficulty, assist classification, seed and totals at the beginning of a movement. Retries roll back that movement's contribution. Final campaign completion clears its checkpoint. Training cannot kill participants or create records.

Profiles remain version 1 with defaults for new fields. Save writes use a temporary file and rename. Corrupt JSON recovers safely; malformed checkpoint values and duplicate or unknown upgrades are sanitized. Older weapon choices map to characters and missing choices default to Aria. Assist records remain separately classified even if assist is later turned off.

## Validation

Headless suites cover combat, all characters, projectile exclusivity, abilities, passives, selection locks, tutorial objectives and completion isolation, reference data and dispatched keyboard/mouse/multitouch input. Stress simulations cover every boss/difficulty with bounded objects and finite physics for 60 simulated minutes. Native OpenGL captures cover tutorial, characters, reference panels and the existing screens.

Web and Windows release exports share the tested source. The hosted package test checks byte-identical valid WebAssembly assembly, MIME, host size limits, asset fallthrough and failed-chunk handling. A Chromium smoke test is maintained for CI. Browser end-to-end testing was unavailable in this development environment, so physical browser/device input, audio and performance remain for player testing.

## Song expansion

The original indices 0–2 remain stable. Four song-inspired encounters are appended at 3–6; normal progression now ends at index 6. Roster data drives save bounds, unlock limits and finale behavior. Direct practice exposes the four additions immediately while keeping campaign unlocks separate. Existing checkpoints at original movements remain valid.

`encounters.gd` loads the shared roster. `song_bosses.gd` owns per-fight heat / volume state, custom patterns, movement destinations, vector figures and arenas. Retrying creates a fresh encounter state. Perspective changes and stagger cancel pending follow-up chains. Hazards warn before activation, are visible throughout their delay and obey the 24-object budget. Wave gaps account for the player's radius; hollow rings have collision-tested safe interiors. Floor tiles remain jumpable in side view. Every new boss has a parryable volley pattern.

Cinder's four flame attacks trigger 3.8 seconds of immobility and +20% incoming damage; existing fire still resolves. Tyrant's three loud attacks trigger 3.4 seconds of immobility while existing soundwaves resolve. These openings use simulation time and pause with the game. Pattern pressure and wave count increase by phase; volleys also use difficulty speed and density. The parade's floor pattern preserves a completely clear column, and spotlight lanes have explicit gaps.

See SONG_BOSSES.md for the concepts, attack catalog and source song attribution.

## Phone interface

Coarse touch devices select the phone interface at boot. Logical presentation is 1280×720 in landscape and 720×1280 in portrait. A portrait camera frames the player and boss horizontally, zooming out promptly when they separate and easing closer when they approach. The clipped hazard layer receives the identical arena transform. Combat simulation retains its original arena coordinates.

Touch routing tracks the movement finger independently from right-thumb actions. Sliding into a new action activates it once; leaving the hit region clears held fire. Releasing or cancelling a touch, losing focus or rotating cannot leave a held action behind. Orientation changes pause encounters. Browser chrome changes within one orientation preserve thumb ownership. Menu actions use large targets and portrait cards.

Phone auto attacks are an optional saved input preference, enabled by default. They call existing melee / rifle methods and never modify damage or timing. Rifle fire reserves dodge energy, and the tutorial's ability objective still requires a manual skill input. Basic melee auto attacks can satisfy its three-hit objective. The manual strike button appears when auto is disabled. Character selection locks remain enforced in every phone menu.

Phone regressions dispatch simultaneous touch and drag events in both orientations, covering action slides, jump / drop gestures, target reach, auto rifle energy reserve, manual control, contextual upgrade confirmation, focus / rotation cleanup and camera alignment. Native phone captures use 390×844 and 844×390 windows. Browser-specific touch feel, audio, fullscreen and wake-lock behavior still require physical device testing.
