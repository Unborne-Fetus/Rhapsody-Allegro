# Rhapsody: Allegro

A Godot action boss rush that changes between top-down and side-scrolling combat. **Version 0.8.3 — Pixel Stage.** All four playable musicians and all twelve bosses now have distinct, transparent retro pixel-art sprites, rather than painted cutouts. The musician classes have four original poses each; every boss has six distinct poses for idle, movement, windups and damage. Each boss has an original looping score with phase-dependent intensity. Perspective changes now animate over 1.25 seconds with moving fighters, rising platforms and a musical-staff bridge. Mobile viewport fixes, the twelve-fight campaign, fixed character kits, higher jumps and deferred parrying remain.

**[Previous browser testing link](https://rhapsody-allegro.r4f86c2gzg.chatgpt.site)** — may not contain the current repository changes. A GitHub Pages launch path is prepared on `main/docs`, but the current version is **not deployed** until a successful Web export is pushed through `PUBLISH-PAGES.bat` and Pages is enabled.

## GitHub Pages — playable Web deployment on main

The public-facing browser URL, **once GitHub Pages is enabled and a Web export is pushed**, will be:

`https://unborne-fetus.github.io/Rhapsody-Allegro/`

GitHub Pages is prepared for **Deploy from a branch → `main` → `/docs`**. No `gh-pages` branch is necessary. The `docs/.nojekyll` marker tells GitHub Pages to serve the static export without running a Jekyll build; the `docs/index.html` launcher opens the full Godot game at `docs/play/index.html` **only when the built files actually exist**. Until then, it explicitly displays that the Web build is pending, rather than pretending to be playable.

### Publish from Windows without a GitHub Actions runner

1. Pull the latest `main` branch on your Windows computer. Keep the repository on `main`.
2. Double-click **`PUBLISH-PAGES.bat`**. It runs the official local Godot 4.5.1 Web/Windows exports and all six regression suites, then stages the real Web runtime in `docs/play/`. With Git installed and configured, it commits **only** the GitHub Pages files and pushes to `origin/main`.
3. **Once per repository:** GitHub repository **Settings → Pages → Build and deployment → Source: Deploy from a branch → Branch: main → Folder: /docs → Save**. GitHub Pages can then serve the published game directly from the only development branch.
4. Wait for GitHub Pages to publish, then visit the URL above. The launcher automatically opens the full-screen responsive Godot browser export rather than embedding it inside another iframe.

To prepare the site files without a Git push, run `PUBLISH-PAGES.bat STAGE` **after** a successful build, then commit `docs/play`, `docs/index.html` and `docs/.nojekyll` with GitHub Desktop. The source Web export remains available in `build/web/`; the optional split-WASM static package is created in `dist/` if Python 3 is installed. The staging script prefers the compressed static package.

**Important:** The game repository is currently **private**. GitHub Pages on a private repository requires an eligible plan (GitHub Pro or higher); GitHub Free supports Pages from **public** repositories. Do **not** make the game source public just to follow these instructions unless you intentionally want the entire repository and its history public. GitHub Pages output itself is publicly accessible even when source remains private. GitHub Actions billing is blocking the normal CI runners, so the local export-and-push route avoids those build minutes; whether GitHub accepts the Pages deployment still depends on the repository's Pages entitlement. If the Pages settings cannot be enabled for your account, the files remain prepared but the new URL is **not live**. See [GitHub's Pages publishing documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

**Branch cleanup:** All five feature pull requests (#1–#5) have already been merged into `main`. Their leftover branch references can be safely deleted through the repository's **Branches** page. Publishing the Web game adds no new branch.

## Gameplay

- **Eight tutorial lessons:** movement, melee, character ability, perfect dodge, energy recovery, resonance, platform jumping and a rehearsal boss. Progress requires completing each objective. Death retries the lesson; campaign saves and records are preserved.
- **Four characters:** choose before the run. Each owns a set, ability, passive and drawback. Character choice stays locked through fights, retries and intermissions.
- **Only the Singer fires player sound-wave projectiles.** The other three musicians have melee abilities. Parrying is deferred; its implementation remains in source.
- **Harder bosses:** more health, faster pressure, pursuit, close-range sweeps, anti-kiting mines and later-phase chains. Every attack retains a warning. Stagger openings are shorter and cannot permanently lock a boss.
- **Contextual upgrade panels:** hover, focus or tap a card to read its core mechanics, including resonance, stagger and energy. Use CHOOSE to commit.
- **Twelve-movement campaign:** difficulty selection, augmentations between bosses, saved movement checkpoints, retry score rollback and separate difficulty / assist records.
- **Training:** immortal dummy, optional attacks, manual perspective changes, range guides and damage / DPS readouts. Select a character before entering.
- **Keyboard, mouse, controller and multitouch:** aspect-preserving scaling, portrait letterboxing, focus-loss pause, configurable volume, shake, flashes and assist mode.

## Low-end PC and phone performance

**ECO RENDERER** is available in Settings on desktop and phones. It starts enabled on browser and mobile installations, and is optional on desktop. The preference saves with your normal local profile; turning it off restores full decorative detail.

Eco mode refreshes the drawn scene at approximately 30 fps while gameplay input, projectiles, collisions and warning lifetimes use fixed 60 Hz simulation steps (subject to hardware performance). It reduces background geometry and curved-effect detail, caps cosmetic sparks at 80 rather than 300, and keeps stage danger zones, bullets, attack warnings, character animation frames and combat rules intact. The sound system reuses short audio samples instead of recalculating waveforms repeatedly. Menus reuse their drawing resources, and expired visual effects are removed without per-frame array-copy allocations. Both modes limit the game's maximum frame rate to 60 to avoid wasting resources on high-refresh screens.

On very weak devices, reducing the browser window resolution, closing GPU-heavy tabs, or toggling screen shake and impact flashes off can help further. ECO does not change difficulty or score eligibility. No specific minimum hardware specification or measured FPS gain is claimed yet.

## Play with two thumbs

Phones automatically get a dedicated interface in portrait or landscape. The left black rail in landscape is a floating movement stick; portrait controls stay below the arena. In side view, flick it upward to jump and downward to drop through platforms; a right-side JUMP button is also available. The right thumb can slide between large DODGE and ABILITY buttons without lifting. Holding ABILITY repeats it; BREAK spends full resonance.

**AUTO starts enabled on phones.** Basic melee attacks trigger only when the boss is within reach. the Singer also fires automatically from range while preserving enough energy for a dodge. Abilities, dodges and breaks remain manual. Tap the small top-left AUTO control to disable it and expose a manual STRIKE button; the setting persists. Auto attack uses the same damage, windups, cooldowns, energy and collision rules as manual input.

Portrait has large menu cards, a separate lower control area and a camera that frames both fighters. Landscape uses the full available canvas, with a central arena and black control rails on either side. Phone characters face the boss even while retreating, and phone strikes track the boss during windup. Rotating the phone pauses a fight, clears held input and rebuilds the layout and touch targets. Completion and pause menus are centered in the new orientation with opaque backgrounds. Upgrade cards use a large inspection list plus a separate confirmation button. The tutorial includes thumb-specific instructions. Safe-area padding keeps browser controls away from notches and home indicators, page gestures are disabled on the canvas, and supported browsers can keep the screen awake. Fullscreen is optional in Settings.

## Song encounters

Open **Boss Practice → Song Encounters** to try any of these immediately, or continue the full performance after The Conductor. The original three retain their indices and records. Practice clears create personal bests without advancing campaign unlocks.

| Boss | Inspiration | Signature gameplay |
|---|---|---|
| Velvet Fuse | Tom Jones — Sexbomb | Countdown bomb chains, hollow blast rings, expanding waves |
| The Cinder King | Elvis Presley — Burning Love | Burning dash trails, flame fans, four-attack heat cycle with +20% damage overheat opening |
| The Everlasting Parade | Village People — Can't Stop the Music | Six spectral performers, alternating floor tiles and open spotlight lanes |
| The Feedback Tyrant | Quiet Riot — Cum On Feel the Noize | Gapped speaker shockwaves, amplifier walls, stage dives and a three-attack silence cycle |

Each has three named phases, its own arena and silhouette, movement behavior, telegraphs, later-phase follow-ups and projectile volleys. Encounter notes in the pause menu explain the central mechanic. These are original interpretations with synthesized effects; recordings and lyrics are not bundled.

## Characters

| Character / set | Ability | Passive | Drawback |
|---|---|---|---|
| Bram / Downbeat (Drummer) | Heavy drum shockwave | 20% damage reduction; 150 HP | Slow movement and dodge recovery |
| Vex / Groove (Bassist) | Slap-bass lunge | Up to three lingering distortion stacks | 80 HP; +15% incoming damage |
| Aria / Riff (Guitarist) | Wide power-chord sweep | Finishers restore 8 extra energy | Normal strikes build 20% less stagger |
| Lyra / Voice (Singer) | Long-range sound-wave projectile | +25% damage beyond 400 units | 75 HP; +20% incoming damage |

Bram is a hard-hitting drummer; Vex a rapid bassist; Aria a balanced guitarist; and Lyra a ranged singer. Their existing damage, movement, energy and difficulty tuning are preserved. See [character tuning](docs/WEAPONS.md) for values. All are available immediately. Each musician has four independent illustrated poses (16 unique frames total), mapped to combat idle, walk, jump, attack and hurt states. The boss gallery and combat use a separate 72-frame pixel-art atlas (six distinct poses for each of twelve bosses). Sprites are transparent, nearest-neighbor filtered and lightweight for the browser/phone build.

## Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD / arrows | Left stick |
| Melee combo | Hold K / left mouse | X / Square |
| Character ability | Hold J / right mouse | RT / R2 or RB / R1 |
| Inspect locked character | Q | B / Circle |
| Dodge | Space | A / Cross |
| Resonance break | E at full meter | Y / Triangle |
| Jump / drop through | W / Up; S / Down | D-pad Up / stick up; stick down |
| Pause / guide | Escape / P; H | Start; pause menu |
| Menu focus / choose | Up / Down / Tab; Enter | D-pad; A / Cross |
| Training attacks / view / guides / reset | T / V / G / R | Pause options |
| Fullscreen | F | — |

Mouse attacks aim at the pointer. Keyboard-only, controller and touch aim at the boss. Touch uses a floating left stick and labeled right-side actions; landscape is recommended. Upgrade card bodies inspect, while their buttons choose. Combat never requires matching the optional practice pulse.

## Build and develop

**Windows (no administrator installation required):** download or clone the repository, then double-click **`PLAY.bat`**. On first use, it downloads the official Godot 4.5.1 standard editor into the ignored `tools/.portable-godot/` folder and runs the actual game project. No GitHub Actions, export templates or Python are needed just to play. You can set the `GODOT` environment variable to an existing Godot 4.5.1 editor executable to skip the editor download.

To make standalone releases, double-click **`build.bat`**. On first build, the script also downloads the official Godot 4.5.1 export templates (a large archive) and installs the two required targets in your user profile. The script exports real Godot Windows and Web builds, creates `build/Rhapsody-Allegro-Windows.zip` and `build/Rhapsody-Allegro-Web.zip`, and then runs the six regression suites. The exported **`build/windows/Rhapsody-Allegro.exe`** runs without the Godot editor. Python 3 is optional for CDN-friendly Web packaging; without it, the raw Web export remains in `build/web/`. `PLAY-WEB.bat` launches the local browser version after building (Python 3 required). Use `build.bat FAST` only for an unverified quick export.

**Corrupt export-template download recovery:** If you previously saw `End of Central Directory record could not be found` in `build/last-build-error.txt`, rerun `build.bat` after updating `main`. The portable installer now compares Godot's official export template against its 1,355,592,535-byte size and SHA-256 digest, resumes partial downloads with `curl.exe`, deletes invalid completed files, and extracts into a temporary folder before installing. You do not need to manually delete the old `.tpz` archive. The large template download is only needed for the first export, not to play with `PLAY.bat`. Windows and **non-threaded Web** release templates are both installed.

**GitHub-hosted Actions warning:** A job that fails in seconds with **zero steps and no assigned runner** has not reached Godot. This project has had that issue on its private repository. Check the repository owner's GitHub Actions usage/runner authorization and account billing status, or build locally using the scripts above. Local Windows builds do **not** consume GitHub Actions minutes. No completed hosted release should be assumed until its build logs and downloadable artifacts exist.

**Linux and macOS developers:** use **Godot 4.5.1 standard** with matching export templates. Import `project.godot`, press F5 to play, or run the commands below to export.

```sh
godot --headless --editor --import --quit
godot --headless --script res://tests/combat_test.gd
godot --headless --script res://tests/advanced_test.gd
godot --headless --script res://tests/input_test.gd
godot --headless --script res://tests/weapon_test.gd
godot --headless --script res://tests/song_boss_test.gd
godot --headless --script res://tests/phone_test.gd
mkdir -p build/web build/windows
touch build/.gdignore
godot --headless --export-release Web
godot --headless --export-release Windows
python3 tools/package_web.py
node tests/package.cjs
node tests/phone_browser.cjs
python3 tools/serve.py
```

Open `http://localhost:8060`. Hosted play needs no development tools. Local Godot web exports require HTTP(S), not `file://`, and WebGL 2. The single-threaded export needs no cross-origin isolation headers.

The web packager preserves the actual engine bytes, splits them into assets below static-host limits, uses content-addressed filenames, and adds a branded loader with download progress. `dist/build-info.json` records engine and game hashes. `build/web/` retains the standard Godot export; `build/windows/` contains the desktop executable.

## Verification

The six headless suites cover combat, progression, dispatched input, character/tutorial rules and song encounters. Stress simulation includes 24 minutes for the original roster and 36 minutes across every new boss, phase and difficulty. Native OpenGL captures verify the tutorial, character roster, upgrade references, and phone menus / combat in both orientations. Both release exports and the WebAssembly package are checked locally. A browser smoke test is included in CI; browser end-to-end testing is unavailable in this environment, so no successful browser playtest is claimed.

GitHub Actions builds Web and Windows artifacts and runs the browser smoke test. Optional GitHub Pages hosting uses `ENABLE_GITHUB_PAGES=true`; the private play link above is independent of Pages.

## Source

`scripts/game.gd` owns encounter flow and interface. `assets/musician-band.png` contains 16 character poses; `assets/bosses-pixel.png` contains 72 boss poses; `scripts/pixel_performers.gd` and `scripts/stage_art.gd` select the appropriate image cells in character menus, boss galleries and live combat. `characters.gd`, `weapons.gd`, `tutorial.gd` and `mechanics.gd` define the kits, objectives and contextual reference data. `phone_ui.gd` draws the thumb interface; phone routing and camera integration use the shared game simulation. `song_bosses.gd` owns the custom encounter mechanics, attacks and vector figures; `encounters.gd` provides shared roster bounds. `run_state.gd` handles upgrades / checkpoints; `profile.gd` handles local persistence. Projectile and hazard simulation are separate, with clipped hazard rendering. Boss data lives in `data/bosses.json`.

See [foundation notes](docs/FOUNDATION.md). No third-party art or recordings are bundled. Godot's engine and default font retain upstream licenses. No license for original game source has been granted yet.

Jump launch speed is 740 units/second, up from 570 (about 69% more height at unchanged gravity). Parry input, automatic parry windows and parry upgrades are disabled through `combat_rules.gd`; the code and legacy regression coverage are retained for future development. Existing Golden Window upgrades convert to an unowned active upgrade when a checkpoint loads.

Phone canvas sizing uses the actual CSS canvas rectangle and device-pixel ratio before Godot starts. Resize / orientation observers keep the buffer aligned after safe-area changes, iframe resizing and delayed engine boot. Deterministic Node tests cover these cases; native captures cover repeated portrait-to-wide-landscape rotation. Physical mobile browser testing remains unverified in this environment.

Art, audio and transition details: [The Living Score](docs/STAGE_ART_AND_AUDIO.md).
