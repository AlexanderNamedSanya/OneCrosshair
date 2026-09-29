# Temporary slot-1 diagnostic capture (0.1.2)

The client test proves the 0.1.1 readiness conjunction never passed in that test. It does **not** identify which operand failed. API signatures alone cannot establish those live values. Working GCD detection and the predicate have therefore been retained while adding an opt-in probe.

## In-game steps

1. `/reloadui` to load 0.1.2. Confirm the larger, thicker, rounder ring; Dot should be unchanged. Check shield alignment and, if practical, the already-correct Critical glow at low HP.
2. Target a training dummy with your usual weapon. Keep GCD enabled and a visibility mode that shows it in combat.
3. Enter `/ocgcd on`, close chat and use several ordinary instant abilities for 4–5 seconds, then your usual LA + ability sequence for another 4–5 seconds. Observe that the normal GCD fill still works and whether any green occurs. Avoid changing weapons during this first capture.
4. Enter `/ocgcd off`, then `/ocgcd summary`. Capture also stops after 15 seconds or 256 rows, evaluated on the next update or command; `off` is harmless if it has already stopped.
5. Enter `/ocgcd 1`, `/ocgcd 2`, etc. Each page prints at most eight sample lines. Return the summary and pages covering the start and end of a GCD, plus any change in `used`, `usable`, `fail`, or cooldown reaching zero. Also report weapon type and whether the sample was abilities-only or weaving.
6. Do not `/reloadui` before copying the results: the buffer is memory-only. A new `/ocgcd on` replaces the previous capture. Repeat with another weapon only after preserving the first results.

No ongoing output is printed per frame. Automatic output consists only of START/STOP notices; summary/pages are explicit commands. With capture off, no rows are collected. No settings, persistent data or permanent logging framework were added.

## Exact fields

| Field | Meaning |
| --- | --- |
| `t` | Milliseconds since capture start |
| `active`, `ready` | Current GCD/ready booleans used by presentation |
| `gcd=remaining/duration`, `source` | Selected live ability GCD timing and its physical slot 3..8 |
| `api` | All four functions required by the readiness predicate exist |
| `used` | Raw `IsSlotUsed(1)` |
| `usable` | Raw `IsSlotUsable(1)` |
| `fail` | Raw `ActionSlotHasNonCostStateFailure(1)` |
| `cd=remaining/duration/global/type` | All four raw `GetSlotCooldownInfo(1)` returns; milliseconds for the first two |
| `id`, `type`, `bar` | Slot-1 bound ID, slot type and active hotbar category, to contextualize the capture |

`nil` is kept as `nil`, not coerced to zero/false. Completion rows show `active=false`; LA predicate fields are nil there because only active-GCD frames evaluate readiness. The active GCD progress remains based on its own selected ability slot, not the slot-1 timer.

## Reading the summary

Counts are **observed active frames**, not durations, cooldown percentages or just stored rows. Rows are sampled every 100 ms, with additional predicate-state changes. Each gate is evaluated independently even if an earlier gate fails, so multiple blocked counts can overlap:

- `usedBlocked`: `used` false/nil.
- `usableBlocked`: `usable` false/nil.
- `failureBlocked`: `fail` truthy.
- `cooldownBlocked`: slot-1 remaining is nil or positive.
- `apiMissing`: required function missing.
- `ready`: frames when the original conjunction actually passed.

If `active=0`, the capture did not observe an active GCD while the gameplay HUD was updating; repeat with chat closed and abilities visibly filling the bottom bar. If `active>0`, compare each blocked count with it and inspect sample pages. For example, a gate blocked on every active frame is direct evidence that it prevents green in that capture. It does not by itself justify removing that check: its actual ESO semantics must be established before changing the predicate. If `ready>0` but the bar remains gray, report this separately; presentation/visibility then also needs investigation.

This probe does not hook attack inputs or use private APIs. It reuses documented public read functions already verified in the project's API snapshot. No actual client data has yet been received for 0.1.2, so the failing gate and a correct replacement condition are still unknown.
