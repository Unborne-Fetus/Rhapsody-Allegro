# The Living Score — 0.8.0

All twelve bosses and four playable characters share a painted stage-fantasy atlas. Musical identities remain explicit: a percussion knight, glass opera singer and orchestral conductor lead the original trio. The nine song encounters retain their performer-inspired identities. Bram is a bell percussionist, Vex a punk violinist with bow-blades, Aria a concert violinist/duelist, and Lyra an electric guitarist with the only player rifle. Existing character stats and combat shapes remain intact.

`assets/performers-atlas.png` was generated with the built-in Image Generation tool and a second spacing pass. `scripts/stage_art.gd` maps fitted source rectangles to combat and menu portraits, keeping one image in memory. Idle motion, facing, movement bob and invulnerability opacity are runtime presentation. This is painted pose art, not a frame-by-frame animation set.

## Art prompt

Create one transparent 4×4 production sprite atlas in cohesive detailed hand-painted dark-fantasy comic style. Full-body three-quarter performers with strong outlines, expressive faces, jewel-tone stage costumes and recognizable musical instruments. Row 1: brass metronome percussion knight, cyan glass opera diva with tuning fork, white-haired conductor with baton and sheet music, silver-haired Tom Jones in wine velvet. Row 2: Elvis in white rhinestones and red cape, Village People police-costume singer, Quiet Riot frontman with long curls and striped trousers, Weather Girls singing duo in blue/silver gowns. Row 3: Irene Cara in pink dancer stagewear, Nina Simone in gold headwrap and indigo gown with keyboard, Eddie Johns in gold disco tailoring and afro, Edwin Starr in olive/gold soul-stage suit. Row 4: bell-armored Bram, punk violinist Vex, concert-duelist Aria with violin and saber, electric guitarist Lyra with guitar-rifle. No text, backgrounds or grid lines. Spacing edit: preserve identities and designs while keeping subjects within their atlas cells.

## Original boss scores

`tools/compose_boss_music.py` composes and renders twelve original sixteen-bar stereo loops, with twelve synchronized intensity stems. Each has a distinct root, tempo, motif and instrumentation drawn from orchestral, glass, funk, rock, metal, gospel, dance, jazz, disco or soul arrangements. There are no commercial recordings, samples, vocals or quotations from the named songs. Rebuilding these assets requires NumPy and ffmpeg; game runtime requires neither.

`scripts/sound.gd` owns two dedicated music players, separate from effect voices. Both stems start together and loop at the same duration. Phase zero plays the base arrangement; phases one and two smoothly introduce the intensity stem at increasing volume. Pause freezes both streams, leaving combat stops them, retry starts the selected score afresh, and the saved Boss Music toggle controls music independently of effects. Master volume controls both; zero mutes the bus.

## Form modulation

Top-down/side-view changes bridge over 1.25 seconds with smoothstep interpolation. Fighters travel from old to new staging positions, the floor grid compresses and releases, platforms rise or retreat, and a moving musical staff provides a clear visual cue. Simulation time, damage, attacks and held touch gestures are suspended during the bridge. Pausing freezes it; restarting clears it. Both campaign directions, training view changes and the tutorial's platform lesson use this behavior. Movement resumes at the exact target positions with a short protection window.

Validation includes actual imported/looping audio resources for all bosses, stream start/pause/resume/stop behavior, persistence of music settings, transition midpoint/destination checks, blocked combat during shifts, tutorial progression, native OpenGL visual captures and the existing phone-rotation checks. Physical mobile-browser playback remains a manual verification limit.
