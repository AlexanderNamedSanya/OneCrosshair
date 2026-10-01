# Architecture

Rendering-quality pass: native ring/Rays lines now share the tintable
256×256 alpha-edge Stroke.dds. Anchors, chord counts and fill logic are retained;
line envelopes compensate for transparent margins to retain half-alpha width.
See [RENDERING_QUALITY.md](RENDERING_QUALITY.md) for the audit and client checks.

## Composition and load order

The manifest loads default String IDs, the selected locale, namespace, fixed release config, core services, registry/presets, rendering/HUD/effects, preview/settings, runtime, then the thin `OneCrosshair.lua` entry point. The entry point handles `EVENT_ADD_ON_LOADED`, opens account-wide SavedVariables and composes settings/runtime. No module requires or calls back into initialization.

`Core/Runtime.lua` coordinates one 16 ms update subscription and activation/deactivation events. Camera/UI/death/reticle visibility gates the whole gameplay overlay. Independent settings preview instances live under the settings panel. No gameplay code contains localized strings.

## Responsibilities

| Module | Responsibility |
| --- | --- |
| StateController | Live target, block and combat snapshot; unsupported pursuit is false |
| Animator | Smoothstep scalar interpolation, including interruption from current value |
| VisibilityController | Per-element visibility, 2 s hold and 200 ms fade; immediate OFF/disable |
| ReticleReplacement | Reversible hide of the vanilla decorative texture only |
| PresetRegistry | Ordered registry, ID lookup and default fallback |
| CrosshairController | Texture pool and animated preset coordinates/alpha/rotation; color and feedback |
| ResourceRing | Four configurable circular quadrants made from pooled native lines; coincident shield geometry; outward warning bands |
| Resource + Health/Magicka/Stamina | Live fractions, stable palette and 150 ms smoothing |
| Shield | Shield fraction against maximum health, clamped and smoothed |
| GCD | Read ability-type globals on physical slots 3..8; derive the latched next-LA ping-zone cue; own bottom presentation |
| AbilityTimings | Client-built non-instant skill table: morphs/ranks, chains, current scribing; fresh per-use metadata |
| HeavyChannel + HeavyChannelData | Independent finite Heavy/cast/channel owner; event-confirmed start, cancellation, timeout and isolated exceptions |
| Effects | Presentation rules and conservative feedback event correlation |
| Preview | Isolated Normal/Target/Block examples, immediate preset changes |
| Settings | Account-wide SavedVariables validation and LibAddonMenu UI |

## Preset contract

A preset registers `id`, a String ID `name`, `elements`, and `states.normal/target/block`. Each element can specify its own `texture`, `textureCoords` (left/right/top/bottom atlas UVs), `width/height` or `size`. Each state contains per-element `x`, `y`, `alpha`, `rotation`. Line elements specify `kind = "line"` and `thickness`; their states use `x/y/x2/y2/alpha`. Texture and line controls have separate reusable pools. Stable element indices preserve identity during movement. An absent state element fades out. The renderer imposes no element-count limit; textures can contain lines/arcs or other shapes. Dot uses three stable elements, with two fading out only as they converge in Normal to avoid opacity accumulation.

An optional pure presentation function `combatFeedback(index, x, y, pulse)` returns displaced coordinates. Without it the crosshair root pulses scale. Presets must not call gameplay APIs. To add a preset, add its file to the manifest, register it, and localize its name. Settings enumerate the registry; resources, state detection, GCD and preview logic require no edits.

## Timing limitations

HeavyChannel owns a native event-derived state plus the existing optional provider seam. `Read(enabled, now)` returns progress and a cast/channel ready flag, or nil. Its state exposes active/kind/progress, identity and interval. Slot candidates require cooldown/combat confirmation; Heavy requires a matching equipped attack BEGIN. Cancellation/expiry removes ownership, revealing current GCD without modifying it. State updates continue while HUD is hidden; deactivation clears active/pending timing. The sole runtime update loop services both modules. See HEAVY_CHANNEL_REFERENCE.md for signal classification, exceptions and limitations. Pursuit stays unasserted. Green is a latency-based cue: remaining GCD <= min(GetLatency(), 150 ms), latched until completion or a new observed cycle. It is a heuristic, not a server-certified input window. See WEAVING_REFERENCE.md.

`GCD.Presentation` returns fill/color/intensity: idle is full gray at .25; active is actual progress at 1; ready is full green at 1. Runtime delegates Heavy/cast/channel presentation to `HeavyChannel.Presentation(progress, ready)`. A finite cast/channel cues the next LA once `max(castRemaining, liveGCDRemaining) <= min(max(ping, 0), 150)`, latching until it ends or cancels. Heavy preserves its one approved full-charge green frame. Neither kind extends its timing interval. The single GCD setting enables all bottom timing. LowResource applies equally to Health/Magicka/Stamina, without side dimming.

`AbilityTimings.entries[abilityId]` records nonzero finite cast/channel metadata, localized name and narrow exclusions/corrections. The table rebuilds on activation, full skill updates, skill-line additions and leaving crafting. Each used ID is refreshed (including equipped Heavy and resolved scribing IDs), then copied into a per-action snapshot, preserving pre-consumption Crux. Catalog coverage and caveats are in UPDATE_0_1_7.md. No offline guessed duration list or reference-addon dependency is shipped.

## UI ownership

No CVar, secure gameplay function, vanilla method replacement or external hidden request is changed. A post-hook reapplies decorative texture hiding after ESO refreshes it; it is inert outside replacement ownership. Leaving gameplay or deactivating restores visibility through the original reticle's `UpdateHiddenState`. Interaction prompts, stealth eye, padlock and game input are preserved.

Controls are pooled across preset changes; ring controls are allocated once. Arc writes are skipped when fill/color/opacity/glow are unchanged. Glow writes are also skipped when only solid fill changes. Geometry is rebuilt only when its three dimensions change. Runtime does not depend on an OnUpdate handler on a hidden control.

## Geometry and timing ownership

Core/Config.lua owns fixed release radius 45.25, thickness 5, quarter-circle arc length 90%, custom crosshair opacity .65 and HUD opacity .50. Settings.Load overwrites legacy saved appearance values with these constants; all five appearance sliders are removed from the UI. ResourceRing uses the same config as its initialization fallback. Zero hides the ring root including shield and glow; 100 joins all four endpoints into a circle. Each quadrant has 64 line segments. Eight fading bands span the full attribute outward from its solid edge by twice its thickness; warning opacity is independent of resource fill. Shield retains a coincident centerline with two extra thickness units. Preview uses separate ring instances, static sample values and size-to-fit for unusually large dimensions.

GCD's active-bar cooldown selection and center-out progress are unchanged. HUD/GCD.lua owns the ping-zone threshold and cue latch; OneCrosshair.lua remains composition only. A rising cooldown or a prior sample whose remaining time elapsed identifies a new observed cycle, even without a zero frame. Hidden/deactivated gameplay clears the model through Runtime. The former slot-1 diagnostic reads and cycle counter are removed. No LA hit, weapon table, queue, additional event handler or update registration is required.


Version 0.1.6 removes the temporary diagnostic module, capture calls, slash command, history and debug-only source/reason/serial snapshots. The single runtime update and all remaining Heavy/Channel listeners serve gameplay. No debug chat output is shipped. Heavy full-release events may retain the owner only until its one completion frame; a subsequent accepted attack replaces it normally.

## Presets added in 0.1.8

Rays now uses six persistent native line controls (0.1.10), with animated start/end coordinates. Each paired set unfolds from one spoke into a corner; Block relocates the three corners into an inverted triangle. Diamonds uses three moving diamond textures with Dot-style feedback, preserving the single visible Normal element. Dot and saved preset IDs remain unchanged. Texture coordinates are set on every preset change, including full-UV reset when leaving an atlas preset, so pooled controls cannot retain a cropped sprite.

The ESO preset has `native = true`. Runtime releases decorative-reticle replacement and hides only its custom crosshair root, leaving the resource ring active. ESO owns its targeting animation and stealth/disguise visibility; the release combat-color layer is described below. In 1.0, NativeReticleColor applies the same 100 ms combat red/peace white transition while preserving native alpha. It snapshots/restores the original RGBA on ownership transitions and stops the native hit-color timeline while active, including through a guarded post-hook on OnImpactfulHit. Menu/death/hidden/deactivation/preset changes release ownership. No new custom hit flash is added. Switching back reacquires replacement normally. No native API/method is overridden.

The isolated ESO preview uses the first and last cells of the game's 16-cell `EsoUI/Art/Reticle/reticleAnim.dds`, at its native 64x64 control size. Block has no separate vanilla shape, so its preview shows the normal endpoint. The preview does not change the live reticle. Sources: [reticle.xml](https://github.com/esoui/esoui/blob/live/esoui/ingame/reticle/reticle.xml), [reticle.lua](https://github.com/esoui/esoui/blob/live/esoui/ingame/reticle/reticle.lua).

## Crosshair scale (0.1.9)

CrosshairController applies a fixed root scale of 2 to custom presets and 1 to native ESO preview. This doubles textures, spacing and positional feedback together; the existing scale-pulse multiplier composes with that base. Gameplay and preview share this renderer. ResourceRing is a sibling control and is unaffected. Preset data remains in its original design coordinates. No hit-color flash was implemented; the interrupted request was cancelled before any code changes.

## Geometric transitions (0.1.10)

Rays interpolates both endpoints over the existing 250 ms smoothstep. Normal has three overlapping pairs (one arm per pair hidden); Target opens both arms; Block moves persistent corners through a 60-degree triangular reorientation instead of sending opposite vertices through the center. Retargeting reads the current interpolated endpoints, so rapid target/block/release transitions stay continuous. Dot and Diamonds already move their persistent elements with this same animator and retain that behavior. The preview continues showing the three final states. No extra update loop, timing setting, native ESO animation change or red hit flash. Retired whole-state Rays DDS files are removed by the deployment allowlist.

## Large Dots (0.1.11)

`large_dot` is an independent preset reusing Disc.dds and the existing three-element animation/feedback contract. Its 15-unit design dots render at 30 UI units with the existing 2x root scale: five times the current Dot diameter. Target/Block spacing is increased to keep the larger dots separate. Existing Dot/default and other presets are unchanged.

## Release 1.0

Author metadata is oneDOK in both manifest and addon panel. Dot design size is 1.5 (rendered 3) with 25% wider state coordinates; Large Dots design size is 7.5 (rendered 15), with existing spacing. Both retain shared animation. Package generation follows manifest entries plus original DDS assets, verifies archive contents, and emits SHA-256; no reference, tooling or saved user data is distributed.
