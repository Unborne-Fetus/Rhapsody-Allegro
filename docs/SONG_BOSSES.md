# Song encounters — v0.7.0

Nine musical bosses extend the original trio. The full campaign is twelve movements; Boss Practice makes all nine musical encounters immediately available. Desktop browsing uses three song pages; phone browsing cycles all twelve bosses. Song titles and artists appear in selection, combat HUD and pause notes. Synthesized cues and vector art are original; there are no bundled recordings, lyrics or beat-timing requirements.

## Velvet Fuse — Tom Jones, Sexbomb

A silver-haired Tom Jones portrait with goatee, open shirt, dark tailoring and microphone in a rose-colored lounge. The encounter translates the song's swagger and explosive title into delayed explosive choreography.

- **Fuse Chain:** three to five fixed bomb marks detonate in sequence. Marks stop tracking as soon as warnings appear.
- **Velvet Trap:** a hollow blast surrounds a protected inner eye. The teal inner boundary identifies the safe pocket; outside the outer ring is also safe.
- **Heartbreaker:** staggered expanding waves retain an angular escape opening; a projectile fan tests dodging.
- **Close Sweep:** a telegraphed short-range punish.

Phases: Slow Burn → Chain Reaction → Grand Detonation. Later phases increase fuse and wave counts. The boss circles the player and links Velvet Trap after selected attacks.

## The Cinder King — Elvis Presley, Burning Love

An Elvis portrait with black pompadour, sideburns, white flared jumpsuit and jeweled gold belt in a fire-lit ballroom. Aggressive pursuit and fire trails give way to cooling windows.

- **Ember Dash:** a warned charge leaves a delayed burning trail.
- **Flame Fan:** divergent flame lanes and projectile embers.
- **Heartfire:** fixed floor marks ignite in a staggered row.
- **Close Sweep:** punishes remaining directly beside the boss.

Phases: Spark → Wildfire → Inferno. Four flame attacks build heat, followed by 3.8 seconds of overheat. The boss stops acting and takes 20% additional damage; already warned hazards still resolve. The HUD displays heat and remaining overheat time.

## The Everlasting Parade — Village People, Can't Stop the Music

A police-costumed lead singer and six performers in distinct stage costumes on a multicolored dance floor. The idea is continuous choreography, without requiring timed button presses.

- **Dance Floor:** alternating tiles light up; an entire column remains clear. In platform view, the ground tiles can be jumped over.
- **Six Step:** six visible performers aim narrow lanes, firing in staggered groups. A central volley tests dodging.
- **Spotlight:** four stationary columns activate around one completely open lane.
- **Close Sweep:** creates a local movement check.

Phases: Opening Number → Call and Response → Never-Ending Encore. The boss moves across the central stage. Later phases extend floor pressure and add Six Step follow-ups.

## The Feedback Tyrant — Quiet Riot, Cum On Feel the Noize

A Kevin DuBrow-inspired performer with long brown curls, open vest and striped stage trousers, backed by amplifiers. Dense sound attacks create a loud/quiet cycle.

- **Power Chord:** sequential sound rings leave a visible angular gap marked by teal edges.
- **Amplifier Wall:** three speaker lanes preserve an opening near the player's snapshotted height; a projectile chord can be dodged.
- **Stage Dive:** a warned rush and delayed landing explosion.
- **Close Sweep:** punishes hugging the amplifier armor.

Phases: Soundcheck → Crank It Up → Maximum Noize. Three loud attacks lead to 3.4 seconds of silence, freezing the boss so players can approach and punish. Existing waves still resolve. Later phases add rings and tighten their gaps.

## Testing and tuning

All new patterns are tested in both perspectives and all three phases. Tests check warnings, bounded geometry, safe eyes and wave gaps, floor jump clearance, six distinct performers, overheat damage, silence, projectile attacks, late checkpoints, practice isolation and a full twelve-movement run. The stress test simulates one minute for each of 81 musical boss/phase/difficulty combinations. Native OpenGL captures cover the roster, all nine arenas, side views and pause notes.

Balance is intentionally configurable in `data/bosses.json` and `scripts/song_bosses.gd`. Human playtesting should judge approach windows for each character and overlapping hazard readability.

Song references: [Tom Jones discography](https://www.tomjones.com/blog/discography/reload), [Elvis Presley official catalog](https://www.elvisthemusic.com/music/burning-love/), [Village People discography](https://www.officialvillagepeople.com/discography.html), [Quiet Riot biography](https://www.quietriot.band/bio).


## The Storm Sisters — The Weather Girls, It’s Raining Men

A duo with dark curls and blue/white gowns on a cloud-framed rooftop. **Downpour** warns of descending human silhouettes with a full clear column. **Thunder Clap** drops vertical lanes in sequence. **Eye of the Storm** combines a safe inner shelter with an escaping ring gap. Phases: Forecast → Cloudburst → Hallelujah Storm.

## The Star Ascendant — Irene Cara, Fame

Dark curls, a pink headband and dancer's stagewear among stars and spotlights. **Audition** locks a horizontal and vertical spotlight before firing. **Star Run** charges along a warned lane with a delayed landing. **Curtain Call** activates floor curtains around a full safe aisle. Phases: Audition → Breakout → Immortal Encore.

## The Spellbound Empress — Nina Simone, I Put a Spell on You

A high gold headwrap, hoop earrings and purple evening gown in a piano-key hall. **Piano Keys** alternates warned floor chords around safe keys. **Spell Circle** casts two staggered hollow rings. **Blue Note** sends sequential horizontal beams. Phases: Incantation → Deep Blue → Sovereign Spell.

## The Disco Alchemist — Eddie Johns, More Spell on You

A 1970s afro, sunglasses, mustache and gold stage jacket against concentric record grooves. **Vinyl Cut** creates waves with angled gaps. **Disco Spell** lays a ring of small seals around the frozen target. **Bass Line** fires four staggered vertical lanes. Phases: Needle Drop → More Spell → Endless Groove.

## The Soul Marshal — Edwin Starr, War

Close natural hair, mustache and olive/gold stage suit. **Drumline** leaves a clear column between marching beams. **Crossfire** alternates aimed beams from opposing sides. **Ceasefire** delivers a final warned blast and gapped wave, then pauses the boss for 2.8 seconds. Phases: The Question → Call and Response → Ceasefire.

All five encounters retain a local warned cleave, platform middle phase and final top-down phase. They add fifteen attack patterns, unique arenas, custom movement and tactical notes. Art is hand-drawn vector caricature, not photographic portraiture. No commercial recordings or lyrics are included.

Additional references: [The Weather Girls](https://www.theweathergirlsofficial.com/), [Nina Simone catalog](https://www.ninasimone.com/albums/i-put-a-spell-on-you/), [Eddie Johns record](https://discofunkcollection.bandcamp.com/album/more-spell-on-you).
