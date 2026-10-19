# Characters and sets, version 0.8.1

Each character owns one set for a full performance, including retries and intermissions. Select before starting. Q / controller B pauses to inspect the character roster; it cannot change equipment. All four are unlocked. Existing profile/checkpoint weapon indices migrate directly to the matching character.

| Character / set | Role | HP | Speed | Melee combo damage | Melee recovery | Ability damage / recovery / cost |
|---|---|---|---|---|---|---|
| Bram / Downbeat (Drummer) | Slow close-range heavy | 150 | 245 | 96 / 108 / 150 | .80 / .88 / 1.15s | Downbeat: 115 / 2.0s / 30 |
| Vex / Groove (Bassist) | Very fast close-range light | 80 | 375 | 11 / 12 / 18 | .105 / .105 / .17s | Slapback: 32 / .9s / 22 |
| Aria / Riff (Guitarist) | Balanced mid-range saber | 100 | 310 | 34 / 38 / 60 | .30 / .32 / .48s | Power Chord: 48 / 1.2s / 22 |
| Lyra / Voice (Singer) | Moderate cadence, long-range light | 75 | 290 | 18 / 20 / 28 | .36 / .38 / .50s | High Note: 12 / .44s / 10 |

Only Lyra's Voice set fires ranged sound-wave projectiles. Parrying is deferred, with its code preserved behind a release flag. Bosses retain their projectile patterns.

Bram slams in a 180-unit radius and takes 20% less damage. His movement and dodge recovery are slow. Vex lunges with slap-bass strikes; distortion stacks damage-over-time up to three times, dealing 3 damage per second per stack for three seconds. Further hits refresh the duration. Vex takes 15% extra damage and has low vitality. Aria sweeps within 200 units. Her Encore passive restores 8 extra energy on ordinary combo finishers; ordinary guitar attacks build 20% less stagger. Lyra sends sound waves up to 950 units and earns 25% extra damage beyond 400 units. She has the lowest vitality and takes 20% extra damage.

Melee damage resolves after a committed windup against the target's current position. Holding the attack repeats combos when ready. Dodging cancels windup without refunding recovery. Energy, resonance and stagger rewards depend on impact; Lifeline heals 5% of captured direct strike damage. Overtone boosts each character's ability by 20%, including melee skills.

The tutorial teaches movement, three landed strikes, character ability, perfect dodge, energy recovery, resonance, platform jumping and a 480-HP rehearsal sentinel. Objectives require actual gameplay events. Death restarts the current lesson. Completion is saved without creating boss records, unlocks or overwriting a campaign checkpoint.

Training retains damage totals, hit count, last impact, five-second average DPS and range guides. Choose another character from the title before starting another training session. G toggles guides and R resets statistics; touch has equivalent buttons.
