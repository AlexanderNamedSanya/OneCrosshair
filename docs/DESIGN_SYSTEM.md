# Design system

Two independent centered layers: preset crosshair and fixed resource ring. No user positioning, scale, colors, dimensions, thresholds or timing settings.

- Dot: 3 px points. Normal is one visible central point; Target triangle vertices `(0,-7),(-6,4),(6,4)`; Block downward triangle `(0,4),(-3.5,-2),(3.5,-2)`.
- Geometry: 250 ms smoothstep; color: 100 ms; direct-action feedback: 130 ms outward-and-return motion, generic 12% scale fallback.
- Crosshair color precedence: combat red, pursuit yellow when supported, otherwise white. Geometry precedence: Block, Target, Normal.
- Fixed 0.1.2 geometry is centralized in ResourceRing: cardinal radius 42.25, half-span 27, bow 9, stroke 4, 64 samples. Top/bottom `(27u, ±(42.25−9u²))`; left/right `(±(42.25−9u²), −27u)`, `u` from -1 to 1. Rotating one profile gives a nearly circular 84.5 × 84.5 centerline envelope while preserving separate rounded bars. Adjacent theoretical endpoints are about 8.84 units apart, leaving about 4.84 units between 4-unit strokes. Previous cardinal radii were 36 × 29 (72 × 58 envelope); their mean radius 32.5 increases exactly 30% to 42.25. Horizontal and vertical increases differ because the ellipse is equalized. Dot is unchanged.
- Health top/red shrinks symmetrically; Magicka left/blue and Stamina right/green fill bottom to top. Bottom GCD expands from center to both edges.
- Shield: purple, exact health centerline, 6-unit stroke (previously 4; still one unit thicker on either side of Health), above the health layer; follows health visibility and resources toggle.
- Resource interpolation: 150 ms. Low warning at <=25% only for Magicka/Stamina. Critical <=25% health: a separate 11-unit halo (previously 9, enlarged with the stroke) spans the entire health geometry at .12 × visible HUD alpha per sample, while the solid red fill still shows actual HP. Magicka/Stamina opacity ×0.35; no change to GCD or crosshair. Above the threshold or with Critical off, full-geometry glow is removed immediately. CriticalState behavior was confirmed in-game and remains unchanged.
- GCD: light gray, idle full bar at 25% of HUD opacity. Active fraction comes from actual ability global cooldown remaining/duration. During the derived LA availability window the ENTIRE bottom bar is green, including previously unfilled areas. End of GCD immediately restores idle. No gold, percentage threshold or separate LA hit effect. Heavy/Channel, when supported, overrides with light-gray progress.

The supplied 0.1.2 client trace identifies the shared ability GCD as the old readiness blocker. Version 0.1.3 exempts that matching timer while retaining state availability checks. In trace replay, green begins at row 3 (833 ms remaining), idle resumes at row 12, and the next GCD is green immediately because its gates already pass. These are observed state transitions, not timing thresholds. Geometry and CriticalState are unchanged; in-client confirmation of the fix remains required.

- Visibility: ALWAYS, COMBAT_ONLY, DYNAMIC, OFF. Combat exit/full resources hold for 2 s, fade 200 ms. Dynamic bottom appears while enabled timing is active. COMBAT_ONLY remains combat-gated. OFF affects the ring, not crosshair. Disabled individual features hide immediately.
- Settings: exact requested preset, two opacity, HUD and effects controls; no defaults button or advanced group. Heavy/Channel toggle explains its present capability limitation.
- Preview: three white labeled examples, follows preset and crosshair opacity, no gameplay simulation or controls.

Dimensions are ESO UI units and therefore follow game UI scaling. Desktop-generated assets do not constitute an in-game visual validation.
