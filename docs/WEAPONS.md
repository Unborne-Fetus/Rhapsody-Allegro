# Weapon sets, version 0.3

The user's four requested roles are implemented as complete melee/ranged pairs. The long-range role uses lower damage and moderate firing speed. All values below are base values before upgrades, stagger or assist; distances use the game's fixed logical arena units.

| Set | Role | Melee damage (combo) | Melee recovery (seconds) | Melee reach | Shot damage | Shot interval | Shot reach |
|---|---|---|---|---|---|---|---|
| Breaker | Slow, close, heavy damage | 96 / 108 / 150 | 0.80 / 0.88 / 1.15 | 110 / 115 / 135 | 80 | 0.90s | 260 |
| Flurry | Very fast, close, low damage | 11 / 12 / 18 | 0.105 / 0.105 / 0.17 | 88 / 94 / 106 | 8 | 0.11s | 220 |
| Cadence | Balanced speed, mid range, strong damage | 34 / 38 / 60 | 0.30 / 0.32 / 0.48 | 150 / 160 / 175 | 24 | 0.38s | 480 |
| Horizon | Moderate speed, long range, lower damage | 18 / 20 / 28 | 0.36 / 0.38 / 0.50 | 215 / 225 / 240 | 12 | 0.44s | 950 |

Breaker has a hammer and concussion cannon, Flurry twin knives and a flechette repeater, Cadence a saber and pulse carbine, Horizon a light spear and marksman rifle. The spear's narrow thrust trades melee damage for reach. The hammer has a broader arc, a visible 0.22–0.32 second windup, and the largest impact. Flurry's 0.015–0.03 second windups and no hit stop support rapid attacks. Cadence sits between these extremes.

Recovery includes windup; it is the minimum time from one activation to the next. Damage happens at the end of windup, using the captured direction but the current player/target positions. Missing is possible if the target moves away. Holding melee repeats attacks when recovery finishes. Dodge can cancel the windup, at the cost of forfeiting the attack while keeping recovery.

Shots have different size, speed and visual trails as well as finite range. Their centers cannot travel past the configured range from the player, including the 24-unit muzzle offset. Target hitboxes can contact a projectile near its endpoint; swept collision never extends beyond the clamped segment. Reflecting an enemy projectile does not impose a player weapon's range on it.

Switching via Q, controller B or the touch WEAPON button changes both attacks. A switch does not shorten either cooldown. Pending attacks retain their originating set's stats and appearance, and combo progression resets so rapid first hits cannot be used to skip directly to a heavy finisher. Starting-set preferences persist independently from the set captured in a run checkpoint.

Energy return, resonance and stagger per melee hit are tuned around hit impact and cadence. Lifeline healing is 5% of base strike damage, avoiding a flat heal per hit that would disproportionately favor the fast set. These values are deliberately easy to tune in `scripts/weapons.gd` after the first playtest.

Training has a five-second average DPS readout, last hit, total damage and hit count. The first few hits are still divided by five, so the readout is intentionally conservative before five seconds of sustained attacking. G toggles range guides; R clears the readout. Touch has RANGE and RESET buttons.
