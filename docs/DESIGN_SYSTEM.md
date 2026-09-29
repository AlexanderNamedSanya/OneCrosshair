# Design system

Two independent centered layers: preset crosshair and fixed resource ring. No user positioning, scale, colors, dimensions, thresholds or timing settings.

- Dot: 3 px points. Normal is one visible central point; Target triangle vertices `(0,-7),(-6,4),(6,4)`; Block downward triangle `(0,4),(-3.5,-2),(3.5,-2)`.
- Geometry: 250 ms smoothstep; color: 100 ms; direct-action feedback: 130 ms outward-and-return motion, generic 12% scale fallback.
- Crosshair color precedence: combat red, pursuit yellow when supported, otherwise white. Geometry precedence: Block, Target, Normal.
- Four independent shallow bowed bars, within 72 × 58 UI units, with the existing 2-unit rounded stroke. For `u` from -1 to 1: top/bottom `(26u, ±(29−6u²))`; left/right `(±(36−6u²), −18u)`. Adjacent theoretical endpoints are about 6.4 units apart, leaving about 4.4 units between 2-unit strokes. This flattens the bars instead of splitting an ellipse into quadrants; sample count and Dot geometry are unchanged.
- Health top/red shrinks symmetrically; Magicka left/blue and Stamina right/green fill bottom to top. Bottom GCD expands from center to both edges.
- Shield: purple, exact health centerline, 4-unit stroke (one unit thicker on either side), above the health layer; follows health visibility and resources toggle.
- Resource interpolation: 150 ms. Low warning at <=25% only for Magicka/Stamina. Critical <=25% health: a separate 9-unit halo spans the entire health geometry at .12 × visible HUD alpha per sample, while the solid red fill still shows actual HP. Magicka/Stamina opacity ×0.35; no change to GCD or crosshair. Above the threshold or with Critical off, full-geometry glow is removed immediately.
- GCD: light gray, idle full bar at 25% of HUD opacity. Active fraction comes from actual ability global cooldown remaining/duration. During the derived LA availability window the ENTIRE bottom bar is green, including previously unfilled areas. End of GCD immediately restores idle. No gold, percentage threshold or separate LA hit effect. Heavy/Channel, when supported, overrides with light-gray progress.
- Visibility: ALWAYS, COMBAT_ONLY, DYNAMIC, OFF. Combat exit/full resources hold for 2 s, fade 200 ms. Dynamic bottom appears while enabled timing is active. COMBAT_ONLY remains combat-gated. OFF affects the ring, not crosshair. Disabled individual features hide immediately.
- Settings: exact requested preset, two opacity, HUD and effects controls; no defaults button or advanced group. Heavy/Channel toggle explains its present capability limitation.
- Preview: three white labeled examples, follows preset and crosshair opacity, no gameplay simulation or controls.

Dimensions are ESO UI units and therefore follow game UI scaling. Desktop-generated assets do not constitute an in-game visual validation.
