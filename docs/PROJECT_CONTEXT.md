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

General pursuit detection and native Heavy/Channel start/end/cancellation are not verified and are deliberately inactive. The Heavy/Channel setting retains its localized limitation tooltip. GCD now derives green readiness from actual LA-slot availability during the current GCD; the API does not explicitly identify an optimal weaving window. These limitations are not emulated with guessed durations. The user has tested the initial build in-game; the follow-up changes have automated validation and still require another in-game visual/behavior pass.

## Follow-up: HUD corrections (0.1.1)

Four independent shallow curved bars replace the ellipse quadrants without enlarging Dot or adding settings. Critical health uses a separate full-length low-opacity halo while the solid red fill remains actual HP. GCD presentation now owns full-green readiness and instant idle restoration, using public LA-slot usability, failure and cooldown data. Corrected engine-to-Lua slot conversion (+1): physical 3..8 includes ultimate and excludes heavy slot 2; feedback's weapon-slot bound uses the same corrected convention. Item/collectible global cooldowns do not drive the ability GCD.

Heavy/Channel was re-investigated using the API snapshot, native action bar/bindings, installed LibCombat and upstream OptimalWeave. No universal reliable cancellation path was established, so no native provider was enabled. The detailed evidence matrix is in API_RESEARCH.md. Validation now includes 19 behavioral scenarios plus locale/load-order and API-symbol checks.

## Next validation

Run the client matrix in API_RESEARCH.md. Prioritize actual LibAddonMenu layout, normal/target/block movement, vanilla restoration, resource stroke appearance, shield value changes, slot cooldown behavior and feedback action-ID correlation. Verify the API version of the installed client; the repository targets the inspected upstream live snapshot, not a guessed release number.

## Collaboration rules

Read ARCHITECTURE.md, DESIGN_SYSTEM.md and this document before follow-up work. Keep modules separated, update documentation when contracts change, and commit code changes. No source repository, client executable, or third-party addon library was provided in the initial workspace.

## Automatic deployment

The user authorizes copying every addon update to `C:\Users\Public\Documents\Elder Scrolls Online\live\AddOns\OneCrosshair`. Run `tools/deploy.ps1` after changes; it copies runtime files and verifies their hashes, without deploying research/tests/docs or modifying other addons and SavedVariables. This is part of each update workflow, not a background file watcher. LibAddonMenu-2.0 was found in the target AddOns directory. Reload the ESO UI to load deployed changes.
