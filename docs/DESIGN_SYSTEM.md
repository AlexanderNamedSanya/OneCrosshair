# Design system

Stroke edges now use a shared white alpha texture. Approved dimensions refer
to its half-alpha contour; a small transparent fringe surrounds that contour.
No geometry, spacing, timing or opacity redesign. See RENDERING_QUALITY.md.

Two independently centered layers: preset crosshair and resource ring. The five geometry/opacity controls are removed from the UI for release 1.0; commented code values live in Core/Config.lua.

- Dot uses a 1.5-unit design texture, rendered at 3 UI units with the custom 2x scale, with its existing Normal/Target/Block shapes, 250 ms geometry transition, 100 ms color transition and 130 ms feedback. Color/geometry priorities are unchanged.
- Resource geometry: circular quadrants, release radius 45.25, thickness 5, length 90% of a quarter circle. Manual code ranges: radius 20..100 (step .25), thickness 1..12 (step .5), length 0..100% (step 1). At zero all ring layers hide; at 100 four enabled full bars form a closed circle. Partial resource values still show their real fill. The crosshair never scales with these settings.
- Health top/red fills symmetrically; Magicka left/blue and Stamina right/green fill bottom to top. Bottom gray GCD fills center-out. Shield is purple and follows the Health path with thickness +2, above Health, respecting its visibility and the Resources toggle.
- Resources retain 150 ms interpolation. Low Resource Warning applies to HP/MP/Stamina at <=25%. A fading halo spans the entire configured attribute arc, including its empty section, outward from the solid outer edge by 200% of line thickness. Eight radial bands approximate the falloff; 64 segments approximate the circular path. No inward halo or dimming of other bars. Critical State is removed.
- Normal GCD: full translucent gray idle at .25 of HUD opacity; actual progress while active; full green once remaining time reaches min(ping,150 ms), latched until completion. Finite cast/channel uses its own elapsed progress and duration, but may cue green only when BOTH its remaining duration and any live GCD are within that same ping zone. End/cancel releases ownership immediately. This is a next-LA heuristic, not an authoritative engine queue signal.
- A 2000 ms channel at ping 100 stays gray through 1899 ms, turns entirely green at the first update >=1900 ms, and restores GCD/idle at 2000 ms. A 600 ms cast under a 1000 ms GCD has no premature cast green; normal GCD cues at 900 ms. Zero ping produces no pre-end cue. High ping is capped at 150 ms.
- Heavy keeps the previously approved single full-charge green frame at its actual end; early cancellation has no completion flash. Heavy, casts, channels and normal GCD share the GCD switch.
- Visibility remains ALWAYS, COMBAT_ONLY, DYNAMIC, OFF, with the existing 2 s hold/200 ms fade. OFF affects ring, not crosshair. Disabled features hide immediately.
- Settings preview: three isolated white Normal/Target/Block crosshairs plus enabled bars and shield. Static examples use HP 20%, MP 65%, Stamina 80%, shield 10%, bottom 60%; low HP demonstrates the warning. Toggles, opacity and geometry refresh immediately. Large rings scale down to fit each preview cell; live geometry remains exact. DYNAMIC/COMBAT_ONLY previews illustrate enabled bars without reading gameplay; OFF hides them.

Dimensions are ESO UI units and follow game UI scaling. Offline rendering and mocked control tests do not replace an in-game visual check.

## Crosshair presets (0.1.8)

| Preset | Normal | Target | Block |
| --- | --- | --- | --- |
| Dot (existing default) | One dot | Three upright dots | Three inverted dots |
| Rays / Лучи | Three radial strokes | Three open upright triangle corners | Three inverted triangle corners |
| Diamonds / Ромбы | One diamond | Three upright diamonds | Three inverted diamonds |
| ESO Default / Стандартный ESO | Actual native ESO reticle | Native targeting animation | No addon-specific Block shape |

Rays follows the first supplied screenshot, with six 1.2-unit native strokes and a 20-unit design envelope; stroke endpoints unfold and relocate over 250 ms. Diamonds follows the second screenshot with 5-unit texture controls, Target coordinates (0,-8),(-7,3),(7,3), Block (0,4),(-5,-3.5),(5,-3.5). These use the existing custom combat color and feedback rules. Native ESO preserves targeting, alpha and stealth; release 1.0 applies combat tint and suppresses the conflicting native hit-color timeline while active. All appearance sliders are removed from the UI. All presets remain compatible with the enabled resource-ring preview. New DDS assets are generated deterministically from geometric primitives; screenshots are references, not extracted bitmap assets.

As of 0.1.9, all custom preset dimensions above are design coordinates rendered at 2x: Dot 6 units, Diamonds 10-unit controls, Rays with a 40-unit silhouette envelope. Element spacing and feedback motion also double in all three states and the settings preview. Native ESO remains at its original size; resources remain unchanged. The proposed red hit flash was cancelled and is not included.

In 0.1.10, Rays transitions are actual geometric movement: Normal → Target splits each radial spoke into two corner arms; Target → Block relocates the corners into the inverted arrangement; release reverses toward the current underlying state. The second arm fades in only while separating from its overlapping partner. Interrupted transitions continue from the current pose. Dot/Diamonds retain their existing smooth point movement, and the 2x custom scale remains.

0.1.11 adds **Large Dots (5x) / Крупные точки (×5)** as a separate choice. One 30-unit dot in Normal, three in Target/Block. Design positions: Target (0,-10),(-9,6),(9,6); Block (0,10),(-9,-6),(9,-6). Larger spacing prevents overlap without enlarging the resource ring. Smooth transitions, color and feedback follow Dot. Existing Dot remains 6 units.

## Release 1.0 overrides

Earlier version dimensions above are historical. Current Dot diameter is 3 units and Large Dots 15, both halved from 0.1.11. Small-dot state coordinates are multiplied by 1.25; large-dot spacing is unchanged. Arc length 90%, radius 45.25, thickness 5, custom crosshair opacity .65, HUD opacity .50 are fixed from the saved player configuration. Edit Core/Config.lua and reload to change them. Native ESO becomes red (1,.15,.12) in combat and white otherwise with a 100 ms transition, preserving alpha; no added red hit flash.
