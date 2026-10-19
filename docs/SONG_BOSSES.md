# Song encounters — v0.5

Four original bosses extend the existing roster. The full campaign is seven movements; Boss Practice → Song Encounters makes all four new encounters immediately available. Song titles and artists appear in selection, combat HUD and pause notes. Synthesized cues and vector art are original; there are no bundled recordings, lyrics or beat-timing requirements.

## Velvet Fuse — Tom Jones, Sexbomb

A tuxedo-clad crooner with a lit spherical fuse head, microphone and rose-colored velvet lounge. The encounter translates the song's swagger and explosive title into delayed explosive choreography.

- **Fuse Chain:** three to five fixed bomb marks detonate in sequence. Marks stop tracking as soon as warnings appear.
- **Velvet Trap:** a hollow blast surrounds a protected inner eye. The teal inner boundary identifies the safe pocket; outside the outer ring is also safe.
- **Heartbreaker:** staggered expanding waves retain an angular escape opening; a projectile fan tests dodging.
- **Close Sweep:** a telegraphed short-range punish.

Phases: Slow Burn → Chain Reaction → Grand Detonation. Later phases increase fuse and wave counts. The boss circles the player and links Velvet Trap after selected attacks.

## The Cinder King — Elvis Presley, Burning Love

A white stage suit, flaming crown and blazing cape in a fire-lit ballroom. Aggressive pursuit and fire trails give way to cooling windows.

- **Ember Dash:** a warned charge leaves a delayed burning trail.
- **Flame Fan:** divergent flame lanes and projectile embers.
- **Heartfire:** fixed floor marks ignite in a staggered row.
- **Close Sweep:** punishes remaining directly beside the boss.

Phases: Spark → Wildfire → Inferno. Four flame attacks build heat, followed by 3.8 seconds of overheat. The boss stops acting and takes 20% additional damage; already warned hazards still resolve. The HUD displays heat and remaining overheat time.

## The Everlasting Parade — Village People, Can't Stop the Music

A mirror-ball ringmaster and six spectral performers on a multicolored dance floor. The idea is continuous choreography, without requiring timed button presses.

- **Dance Floor:** alternating tiles light up; an entire column remains clear. In platform view, the ground tiles can be jumped over.
- **Six Step:** six visible performers aim narrow lanes, firing in staggered groups. A central volley tests dodging.
- **Spotlight:** four stationary columns activate around one completely open lane.
- **Close Sweep:** creates a local movement check.

Phases: Opening Number → Call and Response → Never-Ending Encore. The boss moves across the central stage. Later phases extend floor pressure and add Six Step follow-ups.

## The Feedback Tyrant — Quiet Riot, Cum On Feel the Noize

A masked giant with speaker armor and an angular guitar, backed by a wall of amplifiers. Dense sound attacks create a loud/quiet cycle.

- **Power Chord:** sequential sound rings leave a visible angular gap marked by teal edges.
- **Amplifier Wall:** three speaker lanes preserve an opening near the player's snapshotted height; a projectile chord can be dodged.
- **Stage Dive:** a warned rush and delayed landing explosion.
- **Close Sweep:** punishes hugging the amplifier armor.

Phases: Soundcheck → Crank It Up → Maximum Noize. Three loud attacks lead to 3.4 seconds of silence, freezing the boss so players can approach and punish. Existing waves still resolve. Later phases add rings and tighten their gaps.

## Testing and tuning

All new patterns are tested in both perspectives and all three phases. Tests check warnings, bounded geometry, safe eyes and wave gaps, floor jump clearance, six distinct performers, overheat damage, silence, projectile attacks, late checkpoints, practice isolation and a full seven-movement run. The stress test simulates one minute for each of 36 new boss/phase/difficulty combinations. Native OpenGL captures cover the roster, all four arenas, side views and pause notes.

Balance is intentionally configurable in `data/bosses.json` and `scripts/song_bosses.gd`. Human playtesting should judge approach windows for each character and overlapping hazard readability.

Song references: [Tom Jones discography](https://www.tomjones.com/blog/discography/reload), [Elvis Presley official catalog](https://www.elvisthemusic.com/music/burning-love/), [Village People discography](https://www.officialvillagepeople.com/discography.html), [Quiet Riot biography](https://www.quietriot.band/bio).
