# Foundation notes

## Accepted direction

Rhapsody: Allegro (formerly Project Eclipse) is a zero-budget Godot action boss rush. Hybrid melee/ranged combat and top-down/side-scrolling changes form its identity. Music integration is a later design decision. The prototype deliberately does not require rhythm accuracy or select a final soundtrack, setting, or story.

## First slice

Three movements share a consistent player toolset. Boss definitions are data-driven while attack implementations live in one encounter controller. Split those implementations into individual boss scenes when bespoke bosses and animation replace the geometric prototype. Projectiles and profile/audio services are already isolated so their tests and behavior can survive that change.

The compact vector presentation is temporary game art, with a deliberate charcoal, parchment, coral, mint and gold visual language. The arena has a fixed logical 1280×720 layout that scales with the viewport. Portrait mobile layouts remain a testing target; landscape is the intended combat layout.

## Combat contract

- Player speed: 310 units/second. Floor at y=560 in side view; gravity 1500 and jump velocity -570.
- Dodge: 24 energy, 0.17 second movement burst, 0.23 second protection, 0.48 second cooldown.
- Combo: 30 / 30 / 55 damage, 128-unit range check with a directional opening; visible arc indicates attack direction. Third hit has longer recovery.
- Fire: 9 damage, 3 energy, 0.14 second interval. Passive energy regeneration 16/second. Successful melee restores 13 energy.
- Parry: 0.2 second window, 0.85 second cooldown; reflected shot deals 28 damage and grants resonance/energy.
- Incoming bullets: 12 damage; boss collision 14, charge 22. Post-hit protection lasts 0.85 seconds.
- Burst: 100 resonance, 135 damage, bullet clear, 0.7 second protection.
- Phase boundaries: below 67% and 33% health. Bullet reset and two-second protection on either change.

These values are tuning defaults, not final balance commitments. Boss projectiles and effects are bounded; fast projectiles use swept segment collision. Simulation delta is clamped after long browser stalls so a resumed tab cannot teleport objects through the arena.

## Verification

The headless combat suite exercises all boss patterns, both perspective transitions, protection and damage, energy gating, reflection, burst, gravity, swept collisions, assist, save round-trip and corrupt-save recovery. It also advances each boss through two minutes of simulation and checks bounded projectile counts and finite positions. The browser CI covers boot, beginning combat, movement/shooting/dodge and pause/resume with screenshots.

Manual feedback is still needed for combat feel, boss difficulty, touch ergonomics, gamepad hardware variations, Safari audio, and low-power mobile WebGL performance. A successful export and deterministic tests do not measure those qualities.

## Next feedback priorities

1. Does movement/dodging feel responsive? Is the camera scale right?
2. Should melee carry more or less risk relative to shooting?
3. Does the side-scrolling transition feel purposeful? Should encounters contain more platforming?
4. Which boss patterns are readable or frustrating?
5. What character silhouette, world setting, and music relationship should the next slice explore?

Keep the browser and native builds on one Godot project. Avoid separate gameplay implementations and avoid embedding commercial music while the soundtrack direction is undecided.
