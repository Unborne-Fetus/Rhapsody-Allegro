# Foundation, version 0.4

Rhapsody: Allegro uses one Godot simulation for browser and desktop. The prototype combines action boss fights with top-down / side-scrolling transitions. Combat has no required beat timing. Final art, story and soundtrack remain open for feedback.

## Gameplay revision

Four characters replace in-fight set switching. Each has a locked weapon, ability, passive and drawback; see WEAPONS.md for values. The character selection guard also applies to pause, retries, intermissions and nested menus. Only Lyra / Horizon creates friendly projectiles, including reflected shots. Other parries absorb hostile bullets.

The eight-step tutorial advances on real movement, landed attacks, defensive events, platform collision and a rehearsal boss clear. Early target lessons are immortal. Practice shots are slow, incoming tutorial damage is halved and death retries the current lesson. Tutorial completion is a profile flag; normal records, unlocks and campaign checkpoints are preserved.

Boss health is now 1500 / 2100 / 2800, with shorter recovery and faster patterns. Bosses pursue distant players, punish close approaches with telegraphed circular sweeps and target mines at distant players. Later phases add separately warned follow-up attacks. Ordinary movement freezes during windup to preserve aim readability. Stagger lasts 1.25 seconds, grants +30% damage and has a seven-second lock. Higher difficulties increase damage, speed and density.

Gold hazard warnings never damage. Active beams, mines and expanding waves require movement, jumping or dodging; only projectiles can be parried. Hazard rendering is clipped to the arena. All fights retain three health phases, changing perspective at 67% and 33%, clearing attacks and granting protection. Platforms support buffered jumps, coyote time and dropping through by holding down.

Augmentation cards show a side reference panel on mouse hover, keyboard/controller focus or touch inspection. The panel explains the primary mechanic and a related mechanic. All eight upgrades map to authored definitions; Resonant Core explains how resonance is earned, the 100-point threshold and the break's damage, protection and attack clearing. Inspection does not choose an upgrade; the explicit CHOOSE button does.

## Run and save integrity

Title → character / difficulty → boss → results → augmentation → next boss. Checkpoints store character, upgrades, difficulty, assist classification, seed and totals at the beginning of a movement. Retries roll back that movement's contribution. Final campaign completion clears its checkpoint. Training cannot kill participants or create records.

Profiles remain version 1 with defaults for new fields. Save writes use a temporary file and rename. Corrupt JSON recovers safely; malformed checkpoint values and duplicate or unknown upgrades are sanitized. Older weapon choices map to characters and missing choices default to Aria. Assist records remain separately classified even if assist is later turned off.

## Validation

Headless suites cover combat, all characters, projectile exclusivity, abilities, passives, selection locks, tutorial objectives and completion isolation, reference data and dispatched keyboard/mouse/multitouch input. Stress simulations cover every boss/difficulty with bounded objects and finite physics for 24 simulated minutes. Native OpenGL captures cover tutorial, characters, reference panels and the existing screens.

Web and Windows release exports share the tested source. The hosted package test checks byte-identical valid WebAssembly assembly, MIME, host size limits, asset fallthrough and failed-chunk handling. A Chromium smoke test is maintained for CI. Browser end-to-end testing was unavailable in this development environment, so physical browser/device input, audio and performance remain for player testing.
