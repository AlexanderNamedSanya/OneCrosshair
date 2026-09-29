# Project context

OneCrosshair is an ESO addon replacing the decorative crosshair and adding a lightweight, independently sized contextual resource ring. The repository began empty; this milestone establishes modular source, documentation, tests and original textures.

## Implemented milestone

- Addon manifest/API 101051, LibAddonMenu-2.0 dependency, account-wide version-1 SavedVariables.
- English defaults and Russian String ID overrides selected through the manifest language macro. Empty default-fallback files cover other stock locales. No runtime language branching.
- Dot preset, registry-driven renderer with arbitrary element count and interpolated transitions; separate block/target and combat/color decisions.
- Live resource and shield display, warning/critical effects, real global cooldown visualization, conservative action-correlated feedback, common visibility modes.
- Automatic isolated three-state settings preview and reversible vanilla decorative-reticle hiding.
- Lua 5.1 mock contract suite, engine-symbol checks against inspected documentation, deterministic DDS generation.

## Known incomplete behaviors

General pursuit detection and native Heavy/Channel start/end/cancellation remain deliberately inactive. The Heavy/Channel setting retains its localized limitation tooltip. The user tested 0.1.1 in-game: GCD progress works, the ready bar never turns green, and Critical Health is correct. Which slot-1 gate fails is not yet known. The original ready predicate is retained pending observed evidence; 0.1.2 adds temporary diagnostics without claiming a green-state fix or guessing a timing threshold.

## Current follow-up (0.1.2)

- Centralized ResourceRing geometry: mean radius 32.5 -> 42.25 (+30%), equal horizontal/vertical radii instead of 36/29; stroke 2 -> 4, shield 4 -> 6, glow diameter 9 -> 11. Four separate bars, fill directions and Dot are preserved.
- Temporary `/ocgcd on`, `off`, `summary`, and numeric page commands capture all readiness operands independently. No additional settings, SavedVariables fields, localization changes, events, or update registrations.
- Existing 19 behavior scenarios pass (only intended geometry assertions updated), plus five temporary-probe tests. CriticalState and its behavior assertions are unchanged.
- Next user action: follow `docs/GCD_DIAGNOSTICS.md` in ESO and return the summary plus representative pages before `/reloadui`; evidence is memory-only. Heavy/Channel remains unavailable.

## Follow-up: HUD corrections (0.1.1)

Four independent shallow curved bars replace the ellipse quadrants without enlarging Dot or adding settings. Critical health uses a separate full-length low-opacity halo while the solid red fill remains actual HP. GCD presentation now owns full-green readiness and instant idle restoration, using public LA-slot usability, failure and cooldown data. Corrected engine-to-Lua slot conversion (+1): physical 3..8 includes ultimate and excludes heavy slot 2; feedback's weapon-slot bound uses the same corrected convention. Item/collectible global cooldowns do not drive the ability GCD.

Heavy/Channel was re-investigated using the API snapshot, native action bar/bindings, installed LibCombat and upstream OptimalWeave. No universal reliable cancellation path was established, so no native provider was enabled. The detailed evidence matrix is in API_RESEARCH.md. Validation now includes 19 behavioral scenarios plus locale/load-order and API-symbol checks.

## Next validation

Run the client matrix in API_RESEARCH.md. Prioritize actual LibAddonMenu layout, normal/target/block movement, vanilla restoration, resource stroke appearance, shield value changes, slot cooldown behavior and feedback action-ID correlation. Verify the API version of the installed client; the repository targets the inspected upstream live snapshot, not a guessed release number.

## Collaboration rules

Read ARCHITECTURE.md, DESIGN_SYSTEM.md and this document before follow-up work. Keep modules separated, update documentation when contracts change, and commit code changes. No source repository, client executable, or third-party addon library was provided in the initial workspace.

## Automatic deployment

The user authorizes copying every addon update to `C:\Users\Public\Documents\Elder Scrolls Online\live\AddOns\OneCrosshair`. Run `tools/deploy.ps1` after changes; it copies runtime files and verifies their hashes, without deploying research/tests/docs or modifying other addons and SavedVariables. This is part of each update workflow, not a background file watcher. LibAddonMenu-2.0 was found in the target AddOns directory. Reload the ESO UI to load deployed changes.
