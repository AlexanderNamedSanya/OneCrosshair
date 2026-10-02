# Rendering-quality pass

## Current correction after failed client acceptance

Client follow-up showed the sides mirrored: ESO texture rotation has the
opposite sign to the renderer's screen-space polar angles. The rotation
conversion now negates that angle for solid frames and warnings, restoring
Magicka left and Stamina right while keeping their lower endpoints fixed.

The supplied ESO screenshot shows visible stair steps after commit `98e4540`.
That pass did not achieve the requested smoothness; smoothing the native line
texture was insufficient. Its report below is historical, not the current
default renderer. The screenshot establishes the failure, but does not expose
the engine's UV orientation/filter implementation or isolate a single cause.

The default ring now uses **complete curved alpha masks**, not chord controls.
`Rendering/ArcRenderer.lua` isolates rendering; HUD/ResourceRing.lua selects
that path and preserves its state-module interface. No resource, timing,
visibility, preset or SavedVariables module was changed.

Two original white BC3/DXT5 atlases, `Assets/ArcFill.dds` and `ArcShield.dds`,
are each 2048×4096 with 65 populated 256×256 cells for fractions 0..1 in 1/64
steps. `ArcWarning.dds` is one uncompressed 256×256 white alpha mask. Atlas
memory is 16 MiB total plus 256 KiB for the warning, shared by every ring.
Normal controls are 117.5 UI units square, so source cells are downscaled.
Transparent margins prevent neighboring atlas cells from contaminating edges.

Generator `tools/generate_arcs.py` reads Core/Config.lua. Its radial signed
distance and angular cap distance produce a .7-UI-unit smoothstep coverage
transition centered on the original boundaries. BC3 retains intermediate alpha;
RGB remains white. Source radius 45.25, resource thickness 5, Shield thickness
7, and full span 81 degrees are unchanged. Angular end caps are antialiased too.
The warning retains the full attribute and outward two-thickness envelope,
with a continuous quadratic falloff replacing the eight radial steps.

Every solid arc owns two pre-created CT_TEXTURE controls. UVs select adjacent
curved frames and opacity interpolates them; source-over compensation avoids
dimming their shared solid interior. Only the fill edge interpolates, with no
rectangular clipping or per-frame asset generation. Textures use documented
SetTextureCoords, SetTextureRotation about (.5,.5), and TEX_BLEND_MODE_ALPHA.
Same-level creation order places the second frame above the first. Health and
Shield stay centered at the top. Bottom stays centered at the bottom. For
Magicka/Stamina each selected frame rotates about the ring center so its lower
endpoint stays fixed as the upper endpoint advances. Zero fill has zero solid
alpha; full-green states use the entire bottom frame. Warning rotation is
static and its opacity stays independent of the actual resource fill.

The unchanged nominal angles and pure `ArcRenderer.Range` calculation preserve
symmetric HP depletion, side bottom-up fill, and center-out GCD/Heavy/channel.
Crossfading is a close angular approximation between adjacent frames, not an
engine polar mask. Antialiased overlap can differ slightly from ideal linear
coverage at translucent boundaries. Verify it visually during slow fills.

There are now **13 controls per default ring** (10 solids, 3 warnings), versus
1,856 before; live plus three previews uses 52 rather than 7,424. No per-frame
tables, textures or controls are created. Existing fill/color/glow caches remain.
GPU texture memory increases; actual client performance is still unmeasured.
No snapping or UI-scale setting was introduced. Dot/Rays/feedback are unchanged
from the preceding commit and remain independent of ResourceRing.

Manual geometry edits retain their existing exact procedural behavior through
the lazily created `Rendering/SegmentedArcRenderer.lua` fallback. To get smooth
curved textures for changed radius/thickness/length, rerun the generator. The
generated `Rendering/ArcAssets.lua` describes the baked geometry, so stale
assets cannot silently stretch the wrong thickness or gaps. Normal released
settings match the shipped assets and never allocate the fallback.

Changed: HUD/ResourceRing.lua, manifest, deployment folder allowlist, Config
comments, renderer-coupled test assertions and the three project docs. Added:
Rendering/{ArcAssets,ArcRenderer,SegmentedArcRenderer}.lua, three DDS assets,
tools/generate_arcs.py and tests/arc_assets.py. Old renderer geometry remains
available in the fallback and Git baseline for comparison.

Validation: existing Lua 5.1 behavior scenarios and seven locale/API checks pass;
new renderer checks cover control count, zero/full/intermediate fill, opacity,
atlas UV bounds, symmetric centers, fixed lower side endpoints, Shield
alignment and switching into/out of geometry fallback. Decoded DDS pixel tests
verify BC3, 65 monotonic fill frames, fill proportions, intermediate alpha,
white RGB, original radius/thickness and outward warning. An offline preview
of the actual compressed assets was visually inspected; it is not ESO output.

After `/reloadui`, inspect the four full curved contours and caps first, then
HP symmetry, bottom-up side fills, Shield overlap, full low-resource warnings,
and center-out GCD/Heavy/channel with full-green readiness. Check slow progress
for frame stepping, opacity pulsing, atlas bleed or reversed side rotation;
test preview, OFF/fades and multiple ESO UI scales. Gameplay cancellation,
ownership and cue timing should remain unchanged. **The new in-game visual
acceptance is still pending; passing tests does not establish smoothness.**

## Historical first attempt (rejected in client)

Baseline renderer: Git revision `e2922bc224d4f66c318f3c10cef087f741bb7826`.
This preserves the old source and exact geometry for comparison. Client visual
acceptance is pending; mocked controls cannot demonstrate engine antialiasing.

## Audit

| Element | Before | Geometry and dynamic presentation |
| --- | --- | --- |
| Health | 64 untextured CT_LINE chords | radius 45.25, thickness 5, top 81 degrees, symmetric threshold |
| Magicka / Stamina | 64 CT_LINE chords each | same radius/thickness/span; bottom to top |
| GCD / Heavy / cast / channel | one shared 64-chord bottom arc | same dimensions; center out; full green readiness |
| Shield | 64 coincident CT_LINE chords | Health anchors and thresholds, thickness 7, draw level 4 |
| Low-resource warning | 8 radial bands × 64 CT_LINE chords per resource | width 1.25; radii 48.375 through 57.125; full attribute independent of fill |
| Critical Health | no current separate module | retired before this task; low-HP warning retains full Health geometry |
| Dot / Large Dot | three pooled CT_TEXTURE controls using 64×64 Disc.dds | rendered diameters 3 / 15; Disc already has white RGB and alpha-softened circular edges |
| Target / Block | preset-defined movement of persistent controls | Dot triangle coordinates and 250 ms transition unchanged |
| Rays | six pooled CT_LINE strokes | nominal thickness 1.2, rendered 2.4 with root scale 2; animated endpoints |
| Diamonds | three CT_TEXTURE controls, 128×128 Diamond.dds | rendered 10-unit controls; hard source polygon edge is a possible secondary aliasing source; unchanged in this ring-focused pass |
| ESO Default | game-owned reticle texture animation | native art, dimensions and animation unchanged |
| Combat Feedback | positions or root scale of existing preset controls | no separate feedback asset; 130 ms pulse and fractional movement unchanged |

Ring center remains CENTER on its parent. Chord endpoints are trigonometric
fractional UI coordinates; at release dimensions each chord is about 1 unit
long. Circular chord sag is only about .0028 units. Warning bands add hard
radial boundaries. The old ring has no source texture resolution, UV sampling,
or alpha ramp: native primitive coverage determines its edge. These are the
principal code-level contributors to the reported stair steps; the precise
client rasterizer/filtering contribution cannot be measured offline.

Native lines orient their geometry from their two anchors, without explicit
texture rotation. Texture presets use SetTextureRotation around the default
center (current preset rotations are zero). Dimensions and animation can be
fractional. Live ring scale is inherited from ESO; preview size-to-fit may
add a fractional scale. Custom crosshair root scale is 2, including feedback
displacements. Dot/diamond source textures are downscaled at normal UI scales,
not enlarged beyond their source resolution.

## Supported approaches and choice

The inspected local `.reference/API.txt` and current upstream both target
[API 101051](https://github.com/esoui/esoui/blob/live/ESOUIDocumentation.txt).
LineControl supports SetTexture, SetTextureCoords, SetThickness, tint, blend
mode and fractional anchors. TextureControl supports UVs, rotation and vertex
UVs. Control supports SetMaskTexture and mask thresholds. GetUIGlobalScale
and GetUICustomScale are documented. No per-control texture-filter selection
or general arbitrary angular fill method was found in these control contracts.
Do not assume a documented scale getter provides a screen-pixel snap transform.

[Native reticle.xml](https://github.com/esoui/esoui/blob/live/esoui/ingame/reticle/reticle.xml)
uses centered 64-unit texture controls and a 16-cell animation, supporting
texture-based silhouettes as a native technique. Existing addon Dot already
demonstrates tintable alpha textures without coupling presets to resources.

Investigated: more chords (does not soften edges); full high-resolution arc
textures (good silhouette, but require a new angular-fill implementation);
mask thresholds/UV clipping (available, but rectangular clipping is unsuitable
for these fill directions and no general polar clipping contract is exposed);
rotated texture quads (possible, but requires replacing endpoint geometry);
and textured native lines. The chosen hybrid textures the existing lines,
preserving their independently tested geometry and coverage. No mask controls,
new renderer module or guessed API is needed. This is an edge-quality pass,
not a claim that the engine now supersamples native geometry.

## Asset and fill details

`Assets/Stroke.dds` is one original 256×256 uncompressed RGBA white mask,
generated by `tools/generate_stroke.py`. U is constant; V has smoothstep alpha
ramps across the outer 10% on either side. No color is baked in. Transparent
pixels also have white RGB to avoid dark filtering fringes. Source dimensions
are substantially larger than the normal ring chord length and stroke width.
Existing native blend behavior is retained; no unsupported filtering override.

Half-alpha contours are at V=.05/.95. SetThickness uses nominal thickness/.9
to keep that apparent width: 5 for resources, 7 for Shield, 1.25 per warning
band, and 1.2 in Rays design coordinates. At radius 45.25 the resource's
half-alpha radial edges remain approximately 42.75 / 47.75; texture support
extends about .278 units beyond each edge. Warning support has a similarly
small fringe, while its nominal envelope remains outward-only. Alpha has no
longitudinal fade, which would turn one-unit ring chords into dashed strokes.
Hard terminal caps and native chord joins remain possible residual artifacts.

Fill uses the original per-chord alpha coverage, not rectangular cropping:
`clamp((fill - threshold)*64 + .5)`. Health and Shield use `abs(2*t-1)`;
bottom uses the same thresholds in its bottom orientation; sides use `t`.
Thus HP depletes from ends to center, sides grow bottom-up, and bottom grows
center-out. Full green uses fill=1 as before. Full warning geometry is
independent of resource fill. Shield calculations, all ownership/timing,
visibility, fades, settings, SavedVariables and localization are unchanged.

No pixel snapping was added. Independent rounding would deform one-unit
chords and jitter moving Rays/Dot. Alpha coverage supplies soft edges without
changing anchors, center, gap angles, fill thresholds or animation timing.
UI-scale behavior remains inherited; no addon scale/resolution setting.

Control counts are unchanged: 320 solids + 1,536 warning lines = 1,856 per
ring (7,424 across live plus three settings previews); Rays still uses six.
The shared texture has 256 KiB of base pixel data. Texture/UV writes occur
at creation/preset selection only. Existing geometry/draw caches and per-frame
loops remain; no texture generation, control allocation or new update loop
during combat. Actual GPU filtering/performance requires client verification.

## Validation and client acceptance

Existing behavior tests are retained. Geometry assertions now measure the
texture's half-alpha width instead of its transparent control envelope.
`tests/rendering.lua` additionally checks texture assignments, unchanged
control count, tint/opacity, six fill samples and symmetric Health/Shield/bottom
coverage. `tests/run.py` includes it. DDS inspection checks white RGB,
transparent edges, opaque center, intermediate alpha and constant U coverage.
The Lua 5.1 behavior suite, seven locale initialization checks and public API
symbol checks pass. These checks do not establish visual acceptance.

After `/reloadui`, compare with the baseline at the same resolution/UI scale:

- Full ring: same center, radius, gaps and apparent thickness; inspect inner
  and outer curves for reduced stair steps, dotted seams or dark joins.
- Drain/recover HP: symmetric ends; Shield stays coincident; low HP shows the
  whole outward warning independently of the short actual fill.
- Drain/recover MP and Stamina: bottom-up fill and full warning alignment.
- GCD, Heavy and finite casts/channels: center-out fill, entire bottom green,
  original cancellation and immediate GCD restoration.
- Dot Normal/Target/Block and feedback: unchanged size, spacing and timing;
  Rays: inspect all orientations and interrupted transitions for edge quality.
- Check normal and reduced/increased ESO UI scales, settings previews, fades,
  OFF and disabled features. No combat stutter or geometry jitter.

If native line UV orientation/filtering or terminal seams prevent a materially
smoother appearance in the client, this pass has not met visual acceptance.
Use that observation to evaluate a dedicated curved-texture renderer; do not
declare success based on tests or segment count.
