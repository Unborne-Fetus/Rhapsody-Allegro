# Foundation, version 0.3

Rhapsody: Allegro is a zero-budget Godot action boss rush with hybrid melee/ranged combat and top-down/side-scrolling changes. This foundation expands gameplay while leaving story, setting, final art and soundtrack decisions open. Music integration is deferred; no commercial recordings or rhythm-gated combat are added.

## Run structure

Title → difficulty selection → boss → results → choose augmentation → next boss. Three bosses complete a performance. The current movement checkpoint stores difficulty, accumulated totals, assist classification, upgrades, a stable selection seed, and the equipped weapon set. Checkpoints occur at the start of a movement; they do not restore the exact middle of an attack.

A failed fight can be retried freely. Replaying after a clear first restores the run totals from that fight's beginning, so repeat clears cannot inflate a run score. Completing the final movement clears the checkpoint. Boss practice is separate from run progression; the training arena awards no unlocks or records and cannot kill either participant.

Upgrade offerings are stable for a run/checkpoint and sampled from eight unowned augmentations. No duplicate choices or already-owned choices appear. New performances can offer different builds. Augmentations apply only to that run.

## Combat systems

Default player speed is 310 units/second. Dodge costs 24 energy, grants 0.23 seconds of protection, moves for 0.17 seconds and recovers for 0.48 seconds. Quickstep changes cost/recovery to 18/0.36. Successful blade hits restore 13 energy; passive regeneration is 16/second.

Four complete sets now define both melee and ranged combat; see `WEAPONS.md` for the tuning table. Cadence is the balanced default. Range is enforced in projectile simulation by clamping each step to remaining travel, preserving swept collision only along that clamped segment.

Melee attacks capture a set-specific windup, recovery, direction, combo step, reach, arc, damage and rewards at activation. Damage resolves after windup against the current target position. Set swapping preserves pending attacks and both cooldowns while resetting combo progression. Dodge cancels a pending windup without refunding recovery. The fast set has no hit stop; heavier sets have more pronounced impact. Melee can be held on keyboard, mouse or touch; menu clicks are latched until release so starting/resuming a game does not accidentally attack.

Reward scaling keeps fast attack counts from multiplying healing, energy, resonance and stagger disproportionately. Lifeline restores 5% of the captured base strike damage. Ranged resonance, style and stagger rewards scale with hit damage; rapid low-damage projectiles cannot multiply meter simply through hit count.

Parry lasts 0.2 seconds (0.28 with Golden Window), reflects a bullet for 28 damage, and grants energy/resonance/stagger. Perfect dodges grant resonance once per dash. Burst spends 100 resonance for 135 damage, clears hostile shots and area attacks, and protects for 0.7 seconds.

Blade hits, reflected bullets and ranged hits build stagger. A full meter interrupts windup/charge and opens a two-second +30% damage window, with a five-second lock before another stagger. Style rewards changing action type more than repeating one action, decays over time and drops when hit. Style affects score, not damage.

## Encounters and fairness

All bosses have three health phases, shifting at 67% and 33%. Shifts remove projectiles/hazards, reposition both sides and give two seconds of protection. Distinct motion and attack sequences define the bosses. Virtuoso/Maestro increase attack speed, damage and fan density; they preserve telegraphs and the same control language.

Area hazards are separate simulation objects. Beam lanes, mines and expanding waves cannot damage during their warning stage. Lifetimes and object budgets are bounded. Rendering occurs within a clipped Control layer, preventing large attack shapes from covering the HUD. Gold outlines signal warnings; boss-colored attacks are active. Area attacks require movement, jumping or dodging; only projectiles can be reflected.

Side view has three one-way platforms, buffered jumps and a short coyote-time grace. Descending players land on platforms; holding down skips them. The floor remains safe from falls. The arena retains one logical 1280×720 coordinate system with aspect-preserving scaling across browser/native builds.

## Save integrity

Profiles remain version 1 for backwards compatibility with the original prototype; additional fields have defaults. Writes use a temporary file followed by rename. Corrupt JSON falls back safely. Unknown/duplicate augmentation IDs are removed when restoring a checkpoint. The current assist toggle is stored separately from whether a run has ever used assist. Difficulty and assist records are separated, and turning assist off after benefiting from it cannot relabel that fight as standard.

## Rendering and verification

Original vector figures provide a player silhouette, a clockwork sentinel, a crystalline singer, and a conductor with marionette strings. These remain prototype art. Real native OpenGL captures are part of presentation verification. Impact flashes and screen shake can be reduced independently.

Regression coverage spans 258 checks across base combat, new mechanics, run transitions and dispatched keyboard/mouse/multitouch events, plus 24 minutes of combined simulation, with object bounds checked across nine boss/difficulty combinations. The web packager's content-addressed chunk loader is tested for byte identity, valid WebAssembly, MIME, host asset limits, normal resource fallthrough and failed chunk handling.

A real exported-browser smoke test is included for CI. The GitHub-hosted runner has failed before starting its job, so browser end-to-end verification remains a known gap. Safari, physical controller variations, multitouch ergonomics and low-power mobile performance still need human playtesting.

## Next design work

First-player feedback should drive camera scale, movement feel, damage/readability, usefulness of platforms, and weapon balance. After those settle, split bespoke boss logic into separate encounter scenes, add final character animation and hand-authored arenas, and decide how music belongs in the game. Retain one Godot simulation for browser and desktop.

## Weapon iteration and training

The Arsenal compares four sets side by side, with melee combo damage, shot damage/cadence and both ranges. Profiles remember the chosen starting set; checkpoints capture the current set at the start of the saved movement. Older checkpoints default to Cadence. Training exposes range circles and clipped swing effects, total/hit/last-hit counters and a rolling five-second DPS average. Resetting those statistics does not restart the fight.
