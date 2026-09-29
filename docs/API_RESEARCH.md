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
| GCD | `GetSlotCooldownInfo(slot)` returns remaining, duration, global, globalSlotType; only global cooldowns on active ability slots are accepted; no 1000 ms assumption |
| Weaving | Cooldown information does not establish an authoritative Light Attack readiness window; no fabricated gold threshold |
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
