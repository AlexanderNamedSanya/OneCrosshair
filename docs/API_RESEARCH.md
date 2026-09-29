# API research and verification

Inspected 2026-09-30. Upstream `live/ESOUIDocumentation.txt` declares API **101051**. Local research copies are ignored under `.reference`; they are not addon dependencies.

## Primary sources

- [ESO engine API documentation](https://github.com/esoui/esoui/blob/live/ESOUIDocumentation.txt)
- [ESO reticle implementation](https://github.com/esoui/esoui/blob/live/esoui/ingame/reticle/reticle.lua)
- [ESO power shield implementation](https://github.com/esoui/esoui/blob/live/esoui/ingame/unitattributevisualizer/modules/powershield.lua)
- [LibAddonMenu implementation](https://github.com/sirinsidiator/ESO-LibAddonMenu/blob/master/LibAddonMenu-2.0/LibAddonMenu-2.0.lua)
- [LibAddonMenu custom control](https://github.com/sirinsidiator/ESO-LibAddonMenu/blob/master/LibAddonMenu-2.0/controls/custom.lua)

## Decisions

| Requirement | Verified signal / decision |
| --- | --- |
| Block | `IsBlockActive()` polled; reevaluate underlying target every update |
| Any target | `DoesUnitExist("reticleover")` plus `GetGameCameraInteractableInfo()` for interactable fixtures; no hostile-only filter |
| Combat | `IsUnitInCombat("player")` |
| Pursuit | No general pursuit flag verified; never infer from attackability, stealth detection, bounty or combat |
| Resource values | `GetUnitPower("player", COMBAT_MECHANIC_FLAGS_*)` returns current/max/effectiveMax; fraction uses max |
| Shield | `GetUnitAttributeVisualizerEffectInfo("player", ATTRIBUTE_VISUAL_POWER_SHIELDING, STAT_MITIGATION, ATTRIBUTE_HEALTH, COMBAT_MECHANIC_FLAGS_HEALTH)`; nullable value defaults to zero |
| GCD | `GetSlotCooldownInfo(slot)` returns remaining, duration, global, globalSlotType; require global and ability/crafted-ability source on physical slots 3..8; no 1000 ms assumption |
| Weaving | No explicit optimal-window API. Derive availability from used/usable LA slot 1, no non-cost state failure, and remaining cooldown <=0, only during an active ability GCD; full green presentation, not a percentage threshold |
| Heavy/Channel | `GetAbilityCastInfo` is ability metadata, not current cast state. A general reliable current cast and cancellation API was not found in the inspected public surface. Do not start timers from metadata alone |
| Feedback | `EVENT_ACTION_SLOT_ABILITY_USED(slot)` arms a short-lived action record; player-source `EVENT_COMBAT_EVENT` accepts direct damage/critical/shielded/blocked results only and consumes the record |
| Vanilla reticle | `RETICLE.reticleTexture` is distinct from prompts/stealth. `RequestHidden` hides the entire reticle control, so it is unsuitable. Hide only texture, post-hook `UpdateHiddenState`, restore when overlay stops owning it |
| Settings preview | LibAddonMenu `LAM-PanelOpened` / `LAM-PanelClosed`; no OnShow override on its panel |

Missing functions for optional shield/GCD return neutral values. Stock state APIs are required for the targeted manifest version. Future versions must be revalidated; there are no invented API names or hidden/private gameplay calls.

## Automated verification

`tests/run.py` executes the real addon files in manifest order in **Lua 5.1**, against an explicit mock interface. It covers all stock locale paths, account-wide save creation, target/block priority, transition interruption, visibility hold/fade, variable-duration GCD/local cooldown exclusion, shield clamping, arc directions, effect thresholds, direct/periodic/incoming event filtering, capability fallback/cancel contract, preview isolation and variable preset count, reticle restoration, and resources/GCD toggle independence.

When the upstream documentation copy is present it also checks referenced engine function names and enum/event names. Mocks verify our contracts; they cannot prove in-game event semantics, secure UI restrictions, rendered layout or texture support.

## Required ESO client matrix (not yet executed)

1. Cold load and `/reloadui` with EN and RU; no missing files, Lua errors, or String ID issues. Switch characters and check account-wide settings persist.
2. Center geometry against friendly players, friendly NPCs, hostile NPCs and fixtures. Change targets while blocking, release over target and empty space; inspect smooth transitions.
3. Combat entry/exit; critical and low thresholds; full/empty resources and recovering to full. Confirm 2 s holds and fades in each mode.
4. Apply/refresh/expire shield, shield > max health, resources toggle, health hidden. Verify one coincident overlay.
5. Different ability cooldowns, weapon swap, potions, global cooldown end, failed skills. Confirm timing follows relevant global cooldown and never potion/local timers.
6. Successful LA/HA/direct ability, DoT/HoT ticks, incoming damage, proc damage, multi-target/multi-hit abilities, delayed projectiles. Confirm conservative pulse filtering.
7. Settings open/close/switch panels, scroll, preset and opacity changes. Preview stays white and does not affect gameplay; no reset button.
8. Keyboard/gamepad, UI scale, camera/menu transitions, death, loading, stealth/disguise, interactions. Confirm no duplicate normal crosshair and all vanilla prompts/stealth/padlock remain usable.
9. Disable addon and reload; ensure vanilla presentation is fully restored. Check coexistence with other reticle addons separately.

## Follow-up audit: GCD and Heavy/Channel

### Additional primary implementations inspected

- [Native action bar](https://github.com/esoui/esoui/blob/live/esoui/ingame/actionbar/actionbar.lua): `ZO_ActionBar_IsUltimateSlot` and slot loops use engine constants +1 for physical Lua indices.
- [Native action button](https://github.com/esoui/esoui/blob/live/esoui/ingame/actionbar/actionbutton.lua): `UpdateCooldown` reads all four cooldown returns; `UpdateUsable` separates state failures and cooldown; `UpdateFailure` uses `ActionSlotHasNonCostStateFailure`.
- [Native bindings](https://github.com/esoui/esoui/blob/live/esoui/ingame/globals/bindings.xml): attack input calls private `PrepareAttack()` on down and `PerformAttack()` on up. Input calls are not authoritative action success or cancellation notifications.
- Installed `AddOns/LibCombat/LibCombat.lua`: `GetSkillRegistrationData`, `onAbilityUsed`, `onAbilityFinished`, `onActionSlotAbilityUsed`, `DirectHeavyAttacks`, and per-ability conversion tables. Read as an implementation example, without adding it as a dependency or copying its code.
- [OptimalWeave main.lua](https://github.com/VollstaendigerName/OptimalWeave/blob/main/OptimalWeave/main.lua): its `slot == 1` LA handling and physical ability range 3..8 corroborate slot mapping. Its configurable thresholds, latency compensation and metadata-based channel timer are not adopted as authoritative progress.

### GCD cause and exact current mechanism

Previously `Read` unconditionally reset `gold=false` and never assigned true. Runtime also only colored the filled fraction, so simply turning that flag on would not satisfy a full-bar ready state. Another defect was treating zero-based `ACTION_BAR_FIRST_NORMAL_SLOT_INDEX`/`ACTION_BAR_ULTIMATE_SLOT_INDEX` as physical Lua indices; this scanned 2..7 rather than 3..8.

There are no GCD start/completion events registered by this addon. The existing 16 ms loop reads the active bar's physical ability slots 3..8. A positive remaining time with positive duration, global=true and `globalSlotType` equal to `ACTION_TYPE_ABILITY` or `ACTION_TYPE_CRAFTED_ABILITY` establishes activity. Progress is `1 − remaining/duration`; zero remaining across qualifying slots ends it on the next frame. The greatest positive qualifying remaining time is used to avoid a slot-specific cooldown masking global data. A local cooldown or an item/collectible global does not qualify.

While this GCD is active, slot 1 must pass all of `IsSlotUsed`, `IsSlotUsable`, `not ActionSlotHasNonCostStateFailure`, and `GetSlotCooldownInfo(1).remaining <= 0`. This conjunction defines the derived ready window. Green covers the whole bottom geometry at active opacity, recalculated each frame without latching across cycles. No duration or percentage is assumed, no LA impact drives it, and it cannot stay green after GCD ends. Missing optional readiness APIs leave the bar gray. The documented signals establish client-reported usability/cooldown, not guaranteed server acceptance or optimal animation cancellation; actual slot behavior during each weapon/channel still needs an in-client trace. If a client reports no usable LA before GCD ends, no earlier green window is invented.

### Heavy/Channel evidence matrix

| Candidate | Available information | Missing information / decision |
| --- | --- | --- |
| `EVENT_ACTION_SLOT_ABILITY_USED`, `GetSlotBoundId` | Physical slot notification and ability identity; useful for action correlation | Does not supply authoritative charging progress, actual end time, or a universal release/cancel event; can include queued action handling in existing addons |
| `GetAbilityCastInfo` | Nullable channeled flag and metadata duration | Metadata is not a snapshot of an active cast, actual charge speed/start, or early cancellation |
| `EVENT_COMBAT_EVENT` | Source/target identity, action-slot category, result, ability ID and hitValue | Hit results can establish success after the fact, not continuously active charging. `ACTION_RESULT_INTERRUPT` is not a universal notification for voluntary release, block/roll/bar-swap cancellation |
| LibCombat BEGIN / EFFECT_GAINED / EFFECT_FADED patterns | Demonstrate ability-specific start/end correlation and special treatment of direct heavy IDs | These `ACTION_RESULT_*` constants are absent from the inspected 101051 public enum list (not proof they never exist in a client). This code also needs conversion/exception tables and inferred endings; it does not prove general immediate cancellation coverage for OneCrosshair |
| `EVENT_EFFECT_CHANGED`, `GetUnitBuffInfo` | Effect begin/end times, changes and identities | Effect lifetime may outlast a cast or omit the charging action entirely; no verified per-ability whitelist mapping effect removal to every channel cancellation |
| `EVENT_POWER_UPDATE` | Current/max resource changes | Regeneration, costs and returns are not unique to heavy/channel start, end or cancel |
| `GetSlotCooldownInfo`, `IsSlotUsable`, `ActionSlotHasNonCostStateFailure` | Cooldown and aggregate availability | An unavailable slot does not identify the blocking action or its progress; becoming usable is not a unique Heavy/Channel completion signal |
| `EVENT_ACTION_SLOT_STATE_UPDATED`, `EVENT_ACTION_UPDATE_COOLDOWNS`, `EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED` | Slot state/cooldown/bar changes | No complete active cast record, charge duration or universal interruption semantics |
| Native `PrepareAttack` / `PerformAttack`, animation facilities | Private input entry points; public animation facilities animate addon UI controls | Button edges do not prove accepted gameplay state; no verified public player charge/animation-progress reader. No hooks or overrides of private gameplay functions added |

**Decision:** keep Heavy/Channel intentionally unavailable and retain the localized tooltip. A reliable narrower alternative could be an explicitly verified per-ability effect/ combat-event mapping, or a supported library that guarantees start, current timing, voluntary cancellation, interruption and end across the required weapons/skills. Current evidence does not establish that guarantee; timeouts or metadata timers would produce false progress after cancellation. The existing provider boundary and gray-over-green priority remain tested but do not imply native functionality.

### Follow-up validation

The Lua 5.1 suite passes 19 behavioral cases plus manifest/localization initialization and symbol checks. New cases cover readiness at arbitrary progress (driven only by state), readiness failure/absence, item-global rejection, ultimate slot inclusion, full-geometry glow with empty solid HP, glow removal, endpoint separation, gray Heavy priority over green GCD, immediate restoration, and critical isolation from GCD/crosshair. No new gameplay events, recurring subscriptions or controls are allocated by the patch; pool sizes and SavedVariables/settings/localization/load order remain unchanged.

In-client acceptance still required: visually inspect separated bars at the user's UI scale; compare 10% solid HP against full critical halo; test slot-1 ready states with different weapons, block/roll/target changes and channels; confirm gray idle precisely at observed GCD completion. No claims of an in-client test of this patch are made.
