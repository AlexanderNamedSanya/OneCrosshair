# CombatMetronome reference analysis and OneCrosshair 0.1.4

Reference: user-supplied **CombatMetronome 1.7.7**, including its bundled DariansUtilities. Analysis follows executable branches, not comments. The reference folder remains local and unmodified; no reference source is shipped or required by OneCrosshair.

## Actual execution path

1. `CombatMetronome.lua` initializes `Util.Ability.Tracker`, calls `Start`, and registers its own display update at 1000/60 ms. `DariansUtilities/abilities/Ability.lua:Tracker:Start` registers a 1000/30 ms tracker update and ability/cooldown/combat/lifecycle events.
2. `Tracker:HandleSlotUsed` accepts physical slots 3..8, rejects toggled abilities, resolves ordinary/crafted IDs and calls `Ability:ForId` then `NewEvent`. `ForId` obtains cast/channel duration from `GetAbilityCastInfo`. `NewEvent` queues the candidate; a same-frame cooldown trigger at full GCD can start it directly. This is the addon's inferred event queue, not access to an authoritative engine input queue.
3. `Tracker:GCDCheck` scans 3..8 using `GetSlotCooldownInfo` and returns the first global timer, including remaining/duration and their ratio. `HandleCooldownsUpdated` checks whether the queued ability can fire, backdates its start to `now + remaining - duration`, and accepts a recent start when `eventStart + GetLatency() >= now`. `Update` has a fallback with remaining/duration > 0.9. That 0.9 tests the **start** of a GCD; it is not the next-LA threshold. Outgoing matching BEGIN/BEGIN_CHANNEL combat events provide another start path.
4. `Tracker:AbilityUsed` transfers the queued record into an active event, records the detected GCD duration, and calls `CallbackAbilityUsed` -> `CMFunctions.lua:CombatMetronome:HandleAbilityUsed` (around line 366). The latter stores `currentEvent`, applies per-ability plus instant/heavy/cast adjustment, and sets sound flags. No preceding LA is required.
5. `CMProgressbar.lua:CombatMetronome:Update` (line 44) samples `L = min(GetLatency(), sv.maxLatency)` (lines 89-93), unless ping display is disabled. For the default ordinary instant-ability path, `D = max(detectedGCD or 1000, ability.delay) + adjustment`, elapsed = now - event.start, and remaining = D - elapsed (lines 258-261). Defaults give adjustment 0 for instant skills.
6. At lines 369-370 the progress segment gets remaining/D and the ping segment gets L/D. `CMUserInterface.lua` configures segment 1 with ping color and segment 2 with progress color and `clip=true`. `DariansUtilities/controls/Bar.lua:Bar:Update` sorts the clipping segment last and draws each span up to `min(segment.progress, clippingMaximum)`. Once remaining/D <= L/D, the normal-colored span has zero width and the entire remaining span is the ping zone.

Thus the derived visual crossover for an ordinary instant ability is **0 < remaining <= min(GetLatency(), 150 ms)**. CombatMetronome does not emit an explicit “weaving-ready” event, nor does it paint a full fixed-width green bar. OneCrosshair deliberately maps entry into that reference visual zone to the requested full green bar, then latches it.

## Inputs, constants, configuration and limitations

- Relevant public APIs: `GetSlotCooldownInfo`, `GetFrameTimeMilliseconds`, `GetLatency`; reference event attribution also uses `GetSlotBoundId`, `GetSlotType`, crafted-ability ID mapping, `GetAbilityCastInfo`, weapon/block/mount state and combat results.
- Reference tracker events: `EVENT_ACTION_SLOT_ABILITY_USED`, `EVENT_ACTION_UPDATE_COOLDOWNS`, filtered incoming/outgoing `EVENT_COMBAT_EVENT`, `EVENT_PLAYER_DEAD`, `EVENT_MOUNTED_STATE_CHANGED`, `EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED`, `EVENT_PLAYER_COMBAT_STATE`, `EVENT_WEAPON_PAIR_LOCK_CHANGED`, `EVENT_END_CRAFTING_STATION_INTERACT`. Beam handling additionally observes effects. These broader systems are unnecessary for the isolated instant-GCD cue.
- Defaults in `CMMiscellaneous.lua`: `maxLatency=150`, `dontShowPing=false`, `gcdAdjust=0`, `globalHeavyAdjust=25`, `globalAbilityAdjust=25`, empty `abilityAdjusts`, `trackGCD=false`, `expandDynamically=false`. Reference `CMSettings.lua` exposes max latency (0..1000 ms), GCD/global/per-ability adjustments and ping display controls. OneCrosshair adds no settings.
- The 150 ms value is a cap on the displayed latency zone, not a claimed universal animation or queue threshold. Latency is the full reported `GetLatency()` value: no division by two, smoothing, previous-hit average or extra fixed safety margin. The event-start recency check uses uncapped latency; the visible zone uses capped latency.
- The reference uses a 1000 ms baseline/fallback for ordinary abilities and event completion, not a fixed 1000 ms timer for all animation types. Its queued-event housekeeping also uses 300 ms after dismount, 800 ms after sheathing, and a max(ability delay, 1000) expiry. Declared `GRACE_PERIOD=500`, `EVENT_RECORD_DELAY=10` and `EVENT_FORCE_WAIT=100` have no executable usage in this file; they do not define the cue.
- Optional sound tick/tock has separate offsets and policies (defaults: disabled, tick offset 200, tock offset 300, forced tick time 500). It is not the ping-zone algorithm. Sample-mode display values 0.7 and 0.071 are preview values, not timing thresholds.
- Optional no-current-event `trackGCD` path normalizes ping by 1000 while progress uses actual duration. For non-1000 ms GCDs its crossover differs. OneCrosshair preserves its actual-duration detector and uses milliseconds directly, matching the ordinary ability path rather than importing that normalization discrepancy.
- Cast/channel/heavy behavior can use ability and weapon metadata, adjusted duration, channel colors, dynamic scaling and cancellations. Exception maps include Mend Wounds, Meditate (forced 1000 ms delay), Jesus Beam (effect handling), Fatecarver (338 ms added per Crux stack), and crafted-ability mapping. These do not define the instant-skill ping zone and were not imported.
- `HandleOutgoingCombatEvent` recognizes LA/weapon-attack combat results (GAINED/DAMAGE/CRITICAL_DAMAGE, non-player target), deduplicates within a frame and calls `CallbackLightAttackUsed` -> `CMLATracker.lua:LATracker:HandleLightAttacks`. This updates statistics/counts/inter-attack intervals. Those values are not read by the progress/ping calculation. Early, late or missed LA does not shift the reference visual cue; neither does skill-only use.
- Reference queue/cancel paths account for overwrite, block, death, roll dodge, failed casts, bar swaps and some ability effects. They infer action acceptance from ordering and results. No private API is required for the adapted cue. Public timer/latency data does **not** authoritatively identify a server-accepted next-LA input window; event ordering, special-case IDs and effect assumptions in the broader tracker are empirical/version-sensitive.

The heuristic places an input cue shortly before cooldown expiry to account for network delay. This is useful timing guidance, not proof that a particular input succeeds under lag, stun, resource failure or animation lock. Above 150 ms ping the reference deliberately caps compensation; a long frame can skip the whole visible cue.

## Adaptation

`HUD/GCD.lua` keeps OneCrosshair's existing selection of the greatest positive ability/crafted-ability global cooldown among physical slots 3..8 and its center-out progress. The detector remains more selective than the reference's first-global-slot scan. Each active update samples latency, clamps it to 0..150 ms and enters green when remaining <= lead. Green stays latched until zero/no GCD or a new observed timer. A rising remaining value or expiration of the previous sample before the next update resets the cycle. `Core/Runtime.lua` clears stale model state when gameplay is hidden/deactivated.

Timer corrections that increase remaining are conservatively treated as a new observed cycle; no authoritative engine cycle ID is available here. Source-slot changes alone do not reset the cue. Missing/zero/negative latency produces no new pre-end cue; no invented minimum is substituted. An already-entered cue stays latched if ping later drops. No slot-used/usable/failure condition gates it; the temporary raw slot observations were removed in 0.1.6. Completion returns full gray at .25 intensity on the next update. Existing visibility policy still applies.

Not copied: reference UI/colors/textures/settings/SavedVariables/localization, dependency library, ability queue, cast/channel/heavy tracker, exception tables, LA statistics, sounds, resources/stacks or unrelated features. `OneCrosshair.lua`, geometry, CriticalState and other gameplay systems are unchanged. Heavy/Channel remains its existing unsupported-provider boundary.

## Concrete timeline and repeating weave

For a 1000 ms GCD and constant reported ping **100 ms**, theoretical boundaries are:

| Elapsed | Remaining | OneCrosshair |
| --- | --- | --- |
| 0 ms | 1000 ms | Ability starts GCD, gray progress at center |
| 0..<900 ms | >100 ms | Gray expands toward both ends |
| 900 ms | 100 ms | Entire bar green: press NEXT LA |
| 900..<1000 ms | 100..>0 ms | Remains fully green, even if LA is pressed |
| 1000 ms | 0 ms | Full translucent gray idle |

Actual transitions happen on the first observing runtime update (nominal 16 ms). At ping >=150 ms green begins at 850 ms; at 50 ms it begins at 950 ms. There is no single fixed cue time independent of latency.

For LA -> Skill -> LA -> Skill: the first skill starts a gray cycle; its late ping zone cues the second LA; that attack does not clear green. The next accepted skill starts a fresh gray cycle, even if the update loop never samples a zero between GCDs. Skill without prior LA has the same cycle. A missed cue is not extended beyond GCD completion, and an early/late LA does not reschedule it.

## Validation

Lua 5.1 mocked tests cover boundary inclusivity, whole-bar presentation, completion, variable durations, cap/zero/missing/negative latency, live latency changes and latch, consecutive GCDs without zero, long sample gaps, skill-only/early/late/missed LA, hidden/deactivated runtime and the user's 16-row trace. Existing resource, geometry, critical, visibility, feedback and diagnostic contracts still run. Manifest loads in seven locales; shipped engine symbols are checked against API 101051 when the local snapshot exists. Tests do not depend on CombatMetronome. The user subsequently confirmed normal GCD/weaving in ESO. Version 0.1.6 removes diagnostics without changing this timing model.
