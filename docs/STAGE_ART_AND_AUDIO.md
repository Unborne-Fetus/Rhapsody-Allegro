# The Living Score — 0.8.4 pixel-art cast, musical bosses and presentation polish

All four playable musicians and **all twelve bosses** use low-resolution, transparent, nearest-neighbor pixel-art atlases. The boss designs follow their names, instruments and encounters: metronome automaton, glass soprano, baton conductor, velvet crooner, flaming rock king, disco parade leader, feedback guitarist, storm-singing sisters, rising stage star, regal piano empress, vinyl alchemist and soul marshal. They are original character designs inspired by music, not reproductions of real musicians' identities. The older painted sprites remain in Git history, but are no longer needed by the exported game.

## Four redesigned playable musicians

`assets/musician-band.png` is a **320×320 indexed transparent PNG** cut from the polished four-character concept sheet at `80×80` cells. It has four character columns (Bram the drummer; Vex the bassist; Aria the guitarist; Lyra the singer) and four independent pose rows (neutral idle, performance idle, left step, right step). Their hairstyles, outfits, microphones and instruments are distinct and remain coherent in every frame. The editor/source concept sheet is not required at runtime.

`scripts/pixel_performers.gd` keeps the existing combat-state frame selector, preserving input, attacks and jump logic, and maps the 36 engine state slots to the four **actually illustrated** poses. Do not treat those 36 states as 36 separate illustrated frames: the authored image contains **16 unique pixel-art frames total**. This distinction makes the asset count and animation coverage explicit. Mirroring supplies left/right facing; action frames follow the corresponding performance and stride poses. In version 0.8.4 the four attack-state frames advance proportionally to each musician's actual attack duration, preventing fast combos from repeatedly restarting the same pose. Gallery portraits can be scaled down with nearest-neighbor filtering so the full character fits inside each card.

## Twelve animated boss designs

`assets/bosses-pixel.png` is a **768×528 transparent, indexed PNG**. Columns are the 12 bosses in `data/bosses.json` order; rows are six *separate, hand-composed* poses per boss (idle A, idle B, travel A, travel B, attack windup, hit reaction). There are **72 boss frames**. The Storm Sisters are drawn as two distinct performers in their shared sprite cell. Their weapons/props are musical: microphones, drumsticks, turntables, guitars, batons, keys and stage costumes.

`scripts/stage_art.gd` draws the same boss texture in combat, practice listings, desktop title/menu screens and mobile galleries. It changes pose based on animation time, actual warned windups, attack release, stagger, stationary training behavior and damage, instead of shifting a single painted cutout. Opponents no longer appear to run while stationary or to miss the authored attack pose during most warnings. All attack telegraphs and hitboxes still come from the existing combat and hazard systems; sprite art is presentation-only. Texture filtering uses `CanvasItem.TEXTURE_FILTER_NEAREST`.

`tools/generate_boss_pixel_art.py` can regenerate the deterministic original twelve-boss atlas using Pillow and NumPy. Running it writes the indexed PNG to `assets/bosses-pixel.png`. The default build needs no Python and loads the prebuilt PNG directly.

## Two-pass user interface polish

Character-select portraits use 72% scale on desktop to avoid overlapping text; the original sprites and nearest-neighbor filter are unchanged. Active selection cards have stronger edge accents. A subdued, boss-color stage light separates dark boss sprites from the arena while retaining the same attack warning overlay and ECO particle limits. The home-screen boss now fits inside the illustrated frame.

The combat HUD reports whether a skill is ready or lacks energy. Phone control rings display recharging progress and dim when energy is insufficient, without replacing large thumb targets. Help text now makes the distinction between advance gold warning marks and genuinely safe escape openings unambiguous. Deferred parrying stays hidden in both touch layouts.

## Low-power drawing

The ECO RENDERER switch persists in the user profile. Web and mobile builds default to it on; desktop builds default to full detail. It reduces cosmetic particle budgets, background geometry and curve segments. It throttles CanvasItem redraws to approximately 30 Hz while fixed-step combat simulation remains at 60 Hz when hardware can sustain it. Godot itself is capped at 60 frames per second to avoid unnecessary high-refresh work. Danger telegraphs are never removed, including the landing silhouettes in the Raining Men encounter. Rendering and sound changes do not modify boss HP, weapon damage, timing constants, difficulty or recorded results. Cosmetic sparks use a separate random-number generator so the chosen rendering mode cannot consume gameplay randomness.

`scripts/sound.gd` caches up to 96 short generated tones by pitch, duration and gain, checking for an available voice before creating samples. Repeated UI and attack sounds reuse PCM. `scripts/game.gd` reuses UI panel style resources and removes expired visual instances in place rather than allocating filtered arrays each frame. `scripts/hazard_view.gd` maintains warning visibility in ECO mode with reduced outline segments.

## Original boss scores

`tools/compose_boss_music.py` composes and renders twelve original sixteen-bar stereo loops, with twelve synchronized intensity stems. Each has a distinct root, tempo, motif and instrumentation drawn from orchestral, glass, funk, rock, metal, gospel, dance, jazz, disco or soul arrangements. There are no commercial recordings, samples, vocals or quotations from the named songs. Rebuilding these assets requires NumPy and ffmpeg; game runtime requires neither.

`scripts/sound.gd` owns two dedicated music players, separate from effect voices. Both stems start together and loop at the same duration. Phase zero plays the base arrangement; phases one and two smoothly introduce the intensity stem at increasing volume. Pause and nested in-fight panels freeze both streams without restarting them, leaving combat stops them, retry starts the selected score afresh, and the saved Boss Music toggle controls music independently of effects. Master volume controls both; zero mutes the bus.

## Form modulation

Top-down/side-view changes bridge over 1.25 seconds with smoothstep interpolation. Fighters travel from old to new staging positions, the floor grid compresses and releases, platforms rise or retreat, and a moving musical staff provides a clear visual cue. Simulation time, damage, attacks and held touch gestures are suspended during the bridge. Pausing freezes it; restarting clears it. Both campaign directions, training view changes and the tutorial's platform lesson use this behavior. Movement resumes at the exact target positions with a short protection window.

Validation includes actual imported/looping audio resources for all bosses, stream start/pause/resume/stop behavior, persistence of music settings, transition midpoint/destination checks, blocked combat during shifts, tutorial progression, native OpenGL visual captures and the existing phone-rotation checks. Physical mobile-browser playback remains a manual verification limit.
