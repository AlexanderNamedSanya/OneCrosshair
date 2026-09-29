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
| ResourceRing | Fixed ellipse and rounded sampled arcs, including coincident shield geometry |
| Resource + Health/Magicka/Stamina | Live fractions, stable palette and 150 ms smoothing |
| Shield | Shield fraction against maximum health, clamped and smoothed |
| GCD | Read active-bar cooldowns flagged global; no constant duration |
| Effects | Presentation rules and conservative feedback event correlation |
| Preview | Isolated Normal/Target/Block examples, immediate preset changes |
| Settings | Account-wide SavedVariables validation and LibAddonMenu UI |

## Preset contract

A preset registers `id`, a String ID `name`, `elements`, and `states.normal/target/block`. Each element can specify its own `texture`, `width/height` or `size`. Each state contains per-element `x`, `y`, `alpha`, `rotation`. Stable element indices preserve identity during movement. An absent state element fades out. The renderer imposes no element-count limit; textures can contain lines/arcs or other shapes. Dot uses three stable elements, with two fading out only as they converge in Normal to avoid opacity accumulation.

An optional pure presentation function `combatFeedback(index, x, y, pulse)` returns displaced coordinates. Without it the crosshair root pulses scale. Presets must not call gameplay APIs. To add a preset, add its file to the manifest, register it, and localize its name. Settings enumerate the registry; resources, state detection, GCD and preview logic require no edits.

## Timing limitations

HeavyChannel is a capability boundary, currently without a provider. A future verified provider's `Read(now)` returns `{active, startMs, endMs}` or nil each frame. Cancelled timing must become nil immediately, restoring the current GCD. This is an internal contract, not an invented ESO API. Pursuit and weaving readiness stay unasserted pending reliable evidence; see API_RESEARCH.md.

## UI ownership

No CVar, secure gameplay function, vanilla method replacement or external hidden request is changed. A post-hook reapplies decorative texture hiding after ESO refreshes it; it is inert outside replacement ownership. Leaving gameplay or deactivating restores visibility through the original reticle's `UpdateHiddenState`. Interaction prompts, stealth eye, padlock and game input are preserved.

Controls are pooled across preset changes; ring controls are allocated once. Arc writes are skipped when fill/color/opacity/glow are unchanged. Runtime does not depend on an OnUpdate handler on a hidden control.
