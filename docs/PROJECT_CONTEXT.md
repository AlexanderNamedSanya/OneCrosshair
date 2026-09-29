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

General pursuit detection, authoritative weaving/gold timing, and native Heavy/Channel start/end/cancellation are not verified and are deliberately inactive. The Heavy/Channel setting exists with a localized limitation tooltip. These are not claimed as complete features or emulated with guessed durations. The current milestone is ready for ESO client validation, not a claim of having been tested in-game.

## Next validation

Run the client matrix in API_RESEARCH.md. Prioritize actual LibAddonMenu layout, normal/target/block movement, vanilla restoration, resource stroke appearance, shield value changes, slot cooldown behavior and feedback action-ID correlation. Verify the API version of the installed client; the repository targets the inspected upstream live snapshot, not a guessed release number.

## Collaboration rules

Read ARCHITECTURE.md, DESIGN_SYSTEM.md and this document before follow-up work. Keep modules separated, update documentation when contracts change, and commit code changes. No source repository, client executable, or third-party addon library was provided in the initial workspace.
