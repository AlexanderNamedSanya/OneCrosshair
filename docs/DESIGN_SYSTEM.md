# Design system

Two independent centered layers: preset crosshair and fixed resource ring. No user positioning, scale, colors, dimensions, thresholds or timing settings.

- Dot: 3 px points. Normal is one visible central point; Target triangle vertices `(0,-7),(-6,4),(6,4)`; Block downward triangle `(0,4),(-3.5,-2),(3.5,-2)`.
- Geometry: 250 ms smoothstep; color: 100 ms; direct-action feedback: 130 ms outward-and-return motion, generic 12% scale fallback.
- Crosshair color precedence: combat red, pursuit yellow when supported, otherwise white. Geometry precedence: Block, Target, Normal.
- Ring centerline ellipse: 72 × 62 UI units, 2-unit rounded stroke. Four 80-degree arcs with 10-degree gaps. Generated antialiased disc samples create continuous arcs and soft optional halos.
- Health top/red shrinks symmetrically; Magicka left/blue and Stamina right/green fill bottom to top. Bottom GCD expands from center to both edges.
- Shield: purple, exact health centerline, 4-unit stroke (one unit thicker on either side), above the health layer; follows health visibility and resources toggle.
- Resource interpolation: 150 ms. Low warning at <=25% only for Magicka/Stamina. Critical <=25% health: health glow, Magicka/Stamina opacity ×0.35, no change to GCD or crosshair.
- GCD: light gray, idle full arc at 25% of HUD opacity. Active fraction comes from actual global cooldown remaining/duration. Gold is reserved for verified weaving readiness and currently not activated.
- Visibility: ALWAYS, COMBAT_ONLY, DYNAMIC, OFF. Combat exit/full resources hold for 2 s, fade 200 ms. Dynamic bottom appears while enabled timing is active. COMBAT_ONLY remains combat-gated. OFF affects the ring, not crosshair. Disabled individual features hide immediately.
- Settings: exact requested preset, two opacity, HUD and effects controls; no defaults button or advanced group. Heavy/Channel toggle explains its present capability limitation.
- Preview: three white labeled examples, follows preset and crosshair opacity, no gameplay simulation or controls.

Dimensions are ESO UI units and therefore follow game UI scaling. Desktop-generated assets do not constitute an in-game visual validation.
