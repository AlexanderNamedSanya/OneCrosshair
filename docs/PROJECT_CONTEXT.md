# Project context

OneCrosshair is an ESO addon replacing the decorative crosshair and adding a lightweight, independently sized contextual resource ring. The repository began empty; this milestone establishes modular source, documentation, tests and original textures.

## Implemented milestone

- Addon manifest/API 101051, LibAddonMenu-2.0 dependency, account-wide version-1 SavedVariables.
- English defaults and Russian String ID overrides selected through the manifest language macro. Empty default-fallback files cover other stock locales. No runtime language branching.
- Dot preset, registry-driven renderer with arbitrary element count and interpolated transitions; separate block/target and combat/color decisions.
- Live resource and shield display, low-resource warnings, real global cooldown visualization, conservative action-correlated feedback, common visibility modes.
- Automatic isolated three-state settings preview and reversible vanilla decorative-reticle hiding.
- Lua 5.1 mock contract suite, engine-symbol checks against inspected documentation, deterministic DDS generation.

## Current release: 0.1.9

The user cancelled the proposed red hit flash before implementation. All custom crosshairs (Dot, Rays, Diamonds) now render at twice their previous size, including element spacing and feedback movement, both live and in preview. Native ESO and resource-ring dimensions remain unchanged. Scaling composes with the existing feedback pulse. Existing 80 behavior scenarios pass; direct scale checks cover every preset/state, preview and feedback.

## Previous release: 0.1.8

Added Rays and Diamonds from the two user-supplied reference images, plus ESO Default which restores the actual game reticle. Existing Dot selection/default is preserved. The four presets are selected through the existing dropdown and appear in the existing three-state preview with bars. Custom variants retain animation/feedback; native ESO retains the game's behavior and disables custom crosshair opacity. Four small generated DDS assets are shipped; ESO art is referenced from the client, not copied.

Validation: 80 Lua 5.1 behavior scenarios, seven locale/manifest checks and engine symbol checks pass. New tests cover selection, state transitions, pooled UV reset, native/custom ownership switching, stealth/menu/deactivation and preview isolation. The custom silhouettes were visually inspected through offline rendering of their actual Lua/DDS output. ESO native art/behavior was checked against upstream reticle.xml/reticle.lua; final client rendering still needs `/reloadui` verification. No resource/GCD/Heavy timing changes in this release.

## Previous release: 0.1.7

The latest user request replaces Critical State entirely with Low Resource Warning for all three resources. The warning covers the whole attribute arc and extends outward by two stroke widths; no side dimming remains. Heavy/cast/channel belongs to the GCD switch, and legacy saved options are retired. Three temporary resource geometry sliders and enabled bars in all three preview examples are implemented.

Nonstandard timing is stored in a client-derived skill table (including morphs/ranks/chained IDs and current scribing), refreshed before use. The user explicitly selected the next-LA cue BEFORE cast/channel completion with ping compensation. Green requires both cast and live GCD remaining <= min(ping,150 ms); it stays until end/cancel. Short casts cannot cue while the GCD is still outside that zone. Normal GCD timing and the approved one-frame full Heavy completion remain unchanged. See UPDATE_0_1_7.md for coverage, exceptions and validation. New native-line geometry and the early cast/channel cue require client validation after reload; older confirmations below apply to earlier builds.

## Previous accepted runtime behavior (0.1.6)

The user accepted 0.1.5 in the ESO client: Heavy start/progress/full completion/early release/Block/Dodge; Channel start/progress/normal completion, movement without false cancellation, Block/Dodge; and bottom ownership/restoration. Critical Health and normal GCD/weaving are also confirmed. General pursuit detection remains inactive. Finite timing is still derived from events/API metadata/heuristics, not an authoritative universal progress API.

This cleanup removes the temporary diagnostic module, slash command, capture/history/paging/chat output, slot-1 observations, diagnostic cycle counter and Heavy source/reason/serial snapshots. Heavy/Channel is a supported On/Off feature without a warning tooltip. The user explicitly approved one full-green Heavy completion frame; early cancellation has none. Channel/Cast never gains a hold. Timing intervals, detection/cancellation paths and normal GCD threshold are unchanged. See CLEANUP_0_1_6.md for release details and HEAVY_CHANNEL_REFERENCE.md for useful reference research.

## Previous fix (0.1.4, now confirmed in-game)

Replaced 0.1.3's incorrect “LA currently usable” model with CombatMetronome 1.7.7's ping-zone heuristic: remaining GCD <= min(GetLatency(), 150 ms). Entire bottom bar becomes green and latches to this observed cycle; completion restores idle and a renewed timer starts gray. Previous LA events and slot-1 availability do not shift the threshold. Runtime clears stale latch state when hidden/deactivated. No reference dependency, settings or SavedVariables changes. See WEAVING_REFERENCE.md for execution trace, constants, limitations and timeline. The temporary trace probe used to verify this behavior was removed in 0.1.6. Regression suite includes the supplied trace, thresholds, latency changes, consecutive cycles and lifecycle.

## Previous follow-up (0.1.2)

- Centralized ResourceRing geometry: mean radius 32.5 -> 42.25 (+30%), equal horizontal/vertical radii instead of 36/29; stroke 2 -> 4, shield 4 -> 6, glow diameter 9 -> 11. Four separate bars, fill directions and Dot are preserved.
- A temporary memory-only trace probe helped establish the client cooldown semantics; removed in 0.1.6 after acceptance.
- Existing 19 behavior scenarios pass (only intended geometry assertions updated), plus five temporary-probe tests. CriticalState and its behavior assertions are unchanged.

## Follow-up: HUD corrections (0.1.1)

Four independent shallow curved bars replace the ellipse quadrants without enlarging Dot or adding settings. Critical health uses a separate full-length low-opacity halo while the solid red fill remains actual HP. GCD presentation now owns full-green readiness and instant idle restoration, using public LA-slot usability, failure and cooldown data. Corrected engine-to-Lua slot conversion (+1): physical 3..8 includes ultimate and excludes heavy slot 2; feedback's weapon-slot bound uses the same corrected convention. Item/collectible global cooldowns do not drive the ability GCD.

Heavy/Channel was re-investigated using the API snapshot, native action bar/bindings, installed LibCombat and upstream OptimalWeave. No universal reliable cancellation path was established, so no native provider was enabled. The detailed evidence matrix is in API_RESEARCH.md. Validation now includes 19 behavioral scenarios plus locale/load-order and API-symbol checks.

## Next validation

Confirm the 0.1.6 full Heavy completion frame and clean On/Off control after reload. Previously accepted gameplay behavior should remain the same. Verify the API version of the installed client; the repository targets the inspected upstream live snapshot, not a guessed release number.

## Collaboration rules

Read ARCHITECTURE.md, DESIGN_SYSTEM.md and this document before follow-up work. Keep modules separated, update documentation when contracts change, and commit code changes. No source repository, client executable, or third-party addon library was provided in the initial workspace.

## Automatic deployment

The user authorizes copying every addon update to `C:\Users\Public\Documents\Elder Scrolls Online\live\AddOns\OneCrosshair`. Run `tools/deploy.ps1` after changes; it copies runtime files and verifies their hashes, without deploying research/tests/docs or modifying other addons and SavedVariables. This is part of each update workflow, not a background file watcher. LibAddonMenu-2.0 was found in the target AddOns directory. Reload the ESO UI to load deployed changes.
