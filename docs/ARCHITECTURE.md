# Architecture

## Composition and load order

The manifest loads default String IDs, the selected locale, namespace, core services, registry/presets, rendering/HUD/effects, preview/settings, runtime, then the thin `OneCrosshair.lua` entry point. The entry point handles `EVENT_ADD_ON_LOADED`, opens account-wide SavedVariables and composes settings/runtime. No module requires or calls back into initialization.

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
| ResourceRing | Four fixed shallow bowed bars with rounded samples, coincident shield geometry, separate solid/glow layers |
| Resource + Health/Magicka/Stamina | Live fractions, stable palette and 150 ms smoothing |
| Shield | Shield fraction against maximum health, clamped and smoothed |
| GCD | Read ability-type globals on physical slots 3..8; derive the latched next-LA ping-zone cue; own bottom presentation |
| HeavyChannel + HeavyChannelData | Independent finite Heavy/cast/channel owner; event-confirmed start, cancellation, timeout and isolated exceptions |
| Effects | Presentation rules and conservative feedback event correlation |
| Preview | Isolated Normal/Target/Block examples, immediate preset changes |
| Settings | Account-wide SavedVariables validation and LibAddonMenu UI |

## Preset contract

A preset registers `id`, a String ID `name`, `elements`, and `states.normal/target/block`. Each element can specify its own `texture`, `width/height` or `size`. Each state contains per-element `x`, `y`, `alpha`, `rotation`. Stable element indices preserve identity during movement. An absent state element fades out. The renderer imposes no element-count limit; textures can contain lines/arcs or other shapes. Dot uses three stable elements, with two fading out only as they converge in Normal to avoid opacity accumulation.

An optional pure presentation function `combatFeedback(index, x, y, pulse)` returns displaced coordinates. Without it the crosshair root pulses scale. Presets must not call gameplay APIs. To add a preset, add its file to the manifest, register it, and localize its name. Settings enumerate the registry; resources, state detection, GCD and preview logic require no edits.

## Timing limitations

HeavyChannel owns a native event-derived state plus the existing optional provider seam. `Read(enabled, now)` returns progress or nil. Its state exposes active/kind/progress, identity and interval. Slot candidates require cooldown/combat confirmation; Heavy requires a matching equipped attack BEGIN. Cancellation/expiry removes ownership, revealing current GCD without modifying it. State updates continue while HUD is hidden; deactivation clears active/pending timing. The sole runtime update loop services both modules. See HEAVY_CHANNEL_REFERENCE.md for signal classification, exceptions and limitations. Pursuit stays unasserted. Green is a latency-based cue: remaining GCD <= min(GetLatency(), 150 ms), latched until completion or a new observed cycle. It is a heuristic, not a server-certified input window. See WEAVING_REFERENCE.md.

`GCD.Presentation` returns fill/color/intensity: idle is full gray at .25; active is actual progress at 1; ready is full green at 1. Runtime composes visibility and delegates active Heavy/Channel presentation to `HeavyChannel.Presentation`: gray below full progress, the existing GCD green for full progress. Heavy receives one user-approved completion frame at its unchanged end timestamp; the next read releases ownership. Channel/Cast is never extended. Early cancellation releases immediately without completion green. Hidden gameplay consumes no completion frame. `CriticalState.Read` supplies side dimming and a low-opacity full-geometry halo independently of health fraction; ResourceRing keeps solid and glow alpha separate.

## UI ownership

No CVar, secure gameplay function, vanilla method replacement or external hidden request is changed. A post-hook reapplies decorative texture hiding after ESO refreshes it; it is inert outside replacement ownership. Leaving gameplay or deactivating restores visibility through the original reticle's `UpdateHiddenState`. Interaction prompts, stealth eye, padlock and game input are preserved.

Controls are pooled across preset changes; ring controls are allocated once. Arc writes are skipped when fill/color/opacity/glow are unchanged. Runtime does not depend on an OnUpdate handler on a hidden control.

## Geometry and timing ownership

ResourceRing owns radius, half-span, bow, thickness, shield expansion, glow diameter and sample count in one local geometry table. Resource modules and preset sizes do not own or duplicate these values. All five solid layers (including shield) and glow anchors use the same positional profile.

GCD's active-bar cooldown selection and center-out progress are unchanged. HUD/GCD.lua owns the ping-zone threshold and cue latch; OneCrosshair.lua remains composition only. A rising cooldown or a prior sample whose remaining time elapsed identifies a new observed cycle, even without a zero frame. Hidden/deactivated gameplay clears the model through Runtime. The former slot-1 diagnostic reads and cycle counter are removed. No LA hit, weapon table, queue, additional event handler or update registration is required.


Version 0.1.6 removes the temporary diagnostic module, capture calls, slash command, history and debug-only source/reason/serial snapshots. The single runtime update and all remaining Heavy/Channel listeners serve gameplay. No debug chat output is shipped. Heavy full-release events may retain the owner only until its one completion frame; a subsequent accepted attack replaces it normally.
