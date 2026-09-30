# Heavy / Channel / Cast reference audit (current release 0.1.6)

Primary reference: user-supplied CombatMetronome 1.7.7 and bundled DariansUtilities. The whole reference tree was searched for heavy/channel, cast duration, cancellation and adjustments, then the executable paths below were read. No dependency or reference addon files are shipped.

Classification: **A** = directly read API fact; **B** = state derived from multiple signals; **C** = empirical timing/ordering heuristic; **D** = ability/weapon exception; **E** = expiry/fallback. None of B/C/D/E is advertised as authoritative engine state.

## Source trace

| Reference source and function | Executed responsibility |
| --- | --- |
| `CombatMetronome.lua` initialization / `RegisterCM` | Starts Ability.Tracker; display loop at 1000/60 ms |
| `DariansUtilities/abilities/Ability.lua:Ability:ForId` | GetAbilityCastInfo -> channel/cast/delay; heavy identity from bound slot 2; toggle/ability exception classification |
| `Ability.Tracker:Start` | Registers slot, cooldown, incoming/outgoing combat, death, mount, hotbar, weapon lock and scribing events; tracker loop at 1000/30 ms |
| `HandleOutgoingCombatEvent` -> `NewEvent` -> `AbilityUsed` | Heavy BEGIN/BEGIN_CHANNEL path; queued skill combat confirmation; fade/failure/dodge paths |
| `HandleSlotUsed` -> `NewEvent` | Slots 3..8, toggle check, ordinary/crafted ID resolution, queued skill candidate |
| `GCDCheck`, `HandleCooldownsUpdated`, `Update`, `CanAbilityFire` | Cooldown confirmation, backdated start, late-poll fallback, block and queue expiry |
| `HandleIncomingCombatEvent`, `HandleBarSwap`, `HandleWeaponLockChange` | Intended CC/fade cancellation, bar swap, cast unlock |
| `RegisterJesusBeam`, `UnregisterJesusBeam` | Special beam effect-fade handling |
| `CancelCurrentEvent` | Clears tracker/display records and optionally supplies a GCD reason label |
| `DariansUtilities/abilities/Stacks.lua:GetCurrentNumStacksOnPlayer` | GetNumBuffs/GetUnitBuffInfo scan for Crux 184220 |
| `CMFunctions.lua:HandleAbilityUsed` | Stores display event, computes per-ability + global adjust |
| `CMProgressbar.lua:Update` | Computes remaining fraction, visual duration, timeout/stop conditions and optional channel colors |
| `CMFunctions.lua:OnCDStop`, `SetEventNil`, `ResetBarValues` | Stops display, clears event and calls tracker cancellation |
| `DariansUtilities/controls/Bar.lua:Update`, `CMUserInterface.lua` segment setup | Draws clipped remaining-time/ping segments, not an active attack detector |
| `CMMiscellaneous.lua`, `CMSettings.lua`, `CMSavedVariables.lua` | Defaults, user-adjustable timing offsets and persistence; no built-in weapon-duration correction dataset |

## Reference Heavy execution

1. Outgoing player `EVENT_COMBAT_EVENT`, heavy action-slot type, `ACTION_RESULT_BEGIN` or `ACTION_RESULT_BEGIN_CHANNEL`, and ability ID equal to `GetSlotBoundId(2)` -> `ForId` -> `NewEvent`. Same-ID active heavy is deduplicated. This is **B**, with a live weapon identity **A**, not mouse-down polling.
2. `ForId` reads `GetAbilityCastInfo(id)` (**A** metadata); the heavy duration is `delay`. Mend Wounds IDs are excluded from heavy identity (**D**). No generic weapon duration table is present in this source.
3. `NewEvent` starts heavy immediately at event receipt (**B/C**). `AbilityUsed` records ending = start + delay. `HandleAbilityUsed` adds the configurable global Heavy display adjustment (default +25 ms) plus per-ID adjustment (default empty).
4. `CMProgressbar:Update` displays `(duration - elapsed)/duration`, with duration = delay + adjustment, and an optional capped-ping segment. However, `time > event.ending and slotRemaining == 0` can stop it at the raw delay before the +25 ms display adjustment. `timeRemaining < 0` is another stop. The later elapsed >= duration+latency check does not universally extend the earlier timeout. These are **C/E**, not a charge-state query.
5. On cooldown updates, an active heavy ends if any normal GCD is positive, or otherwise if slot 2 is non-global and remaining == duration, including 0/0 (**B/C**). This is the reference's inferred early release/cancel path; there is no universal explicit release callback.
6. Matching combat EFFECT_FADED, block transition, dodge, bar swap, death, new accepted ability and selected failures also cancel (**B/D**). Timeout provides the final bound (**E**). Channeled Heavy damage ticks are not treated as completion by the reference.

## Reference Channel / Cast execution

1. `EVENT_ACTION_SLOT_ABILITY_USED` accepts slots 3..8, skips toggled actions and resolves crafted IDs. `GetAbilityCastInfo` returns channel flag and duration (**A**); positive cast/channel duration determines non-instant classification. The slot event creates a pending candidate, not proof of acceptance (**B**).
2. On `EVENT_ACTION_UPDATE_COOLDOWNS`, `GCDCheck` scans 3..8 for the first global timer. Start is backdated to now + remaining - duration. The reference accepts a recent start if start + full `GetLatency()` >= now (**B/C**). A same-frame full GCD can start directly; tracker polling with remaining/duration >0.9 is a fallback (**E**). A matching queued combat BEGIN or EFFECT_GAINED also confirms. Heavy separately recognizes BEGIN_CHANNEL.
3. Cast/channel `AbilityUsed` ending is start + max(delay,1000,remainingGCD). Display duration is max(detectedGCD or 1000,delay) plus adjustment. Default global non-instant display adjustment is +25 ms. Short casts therefore share a longer combined GCD display; channel color switches when actual cast time finishes. OneCrosshair must not copy that combined-owner behavior for a 600 ms cast.
4. Cast unlock before expected completion cancels. Block, dodge, bar swap, matching fades/errors, some target-death/immune paths, death and timeout terminate the display. There are ability-specific beam effects and Fatecarver duration adjustments; it is not a completely generic universal cast tracker.
5. Reference cancellation clears current tracker/display events. `OnCDStop` -> `SetEventNil` -> tracker cancellation releases remaining state. The optional GCD reason/icon is presentation, not a second engine GCD.

## Signals and constants retained or deliberately changed

| Mechanism | Class | OneCrosshair decision |
| --- | --- | --- |
| GetAbilityCastInfo channel flag and finite positive duration | A | Read fresh per action, no stale cache across weapon/scribing changes |
| Player heavy BEGIN/BEGIN_CHANNEL + equipped slot-2 identity | B | Retained; duplicate starts ignored |
| Slot candidate + accepted cooldown/combat signal | B/C | Retained; unchanged old GCD cannot confirm a queued press; new timer or matching combat evidence required |
| Start = now + remaining - duration; recency uses full GetLatency | B/C | Retained for accepted skills; combat-confirmed no-GCD start uses event time |
| Pending lifetime max(duration,1000) | E | Retained finite expiry; active owner expires at its own cast/charge duration |
| Heavy slot-2 non-global remaining==duration on cooldown event | B/C | Retained including 0/0, after start frame; never applied as a per-frame 0/0 poll |
| New GCD terminates Heavy | B/C | Require inferred new start later than Heavy start, so an already-running underlying GCD does not cancel the new overlay |
| Non-channeled Heavy direct hit with same ID | B | Additional conservative release evidence; never used for channeled Heavy ticks |
| Matching fades, failures, incoming CC, block, swap, weapon change/unlock, death, mount, sheathe | B | Clear owner on observed event/update; source/target/ID checks where relevant |
| Early on-cooldown rejection within 100 ms | C | Retained; failed later repeated press clears candidate without clearing the accepted older cast |
| Dodge ID 28549 + EFFECT_GAINED | D | Retained; no assumption that ACTION_RESULT_DODGED means the player rolled |
| Beam IDs 63029,63044,63046 | D | Effect-fade handling retained with matching effect begin timestamp and target, instead of unconditional skip-next-fade flag |
| Exhausting Fatecarver IDs 183122,193397 | D | +338 ms per Crux stack, buff ID 184220; snapshot at slot candidate before consumption, clamp 0..3 |
| Mend Wounds 13 IDs | D | Only exclusion data retained; do not misclassify toggled replacement attacks as finite Heavy charges |
| Meditate 103665,103492,103652 | D | Excluded from finite progress; reference forced delay=1000 is not meaningful completion for indefinite channel |
| +25 ms Heavy/cast display offset; per-ability user adjustments | C | Not imported: OneCrosshair owns the actual finite cast interval, not combined GCD/countdown display; no extra hold or fabricated padding |
| 300 ms dismount / 800 ms sheathe queue gates | C | Not imported: mounted/sheathed states cancel; candidate acceptance and finite expiry handle pending work |
| Reference 500/10/100 declarations named GRACE_PERIOD/EVENT_RECORD_DELAY/EVENT_FORCE_WAIT | None | No executed usage in Ability.lua; not timing mechanisms |

Exception data is isolated in `Effects/HeavyChannelData.lua`, including origin comments. Update that small module when future ESO versions change IDs/behavior. No fixed weapon timing guesses are introduced.

The reference's incoming CC expression `not sType == COMBAT_UNIT_TYPE_PLAYER` has Lua precedence `(not sType) == enum`; for numeric types it does not perform the intended inequality. That defect was not copied. OneCrosshair checks player target and CC result explicitly. The reference's beam unregister/skip-next assumptions and separate tracker/display event objects were also not transplanted.

## ESO compatibility boundary

Public functions: GetAbilityCastInfo, GetSlotBoundId, GetSlotType, GetAbilityIdForCraftedAbilityId, IsSlotToggled, GetSlotCooldownInfo, GetLatency, GetFrameTimeMilliseconds, GetActiveHotbarCategory, GetNumBuffs/GetUnitBuffInfo, IsBlockActive, IsUnitDead, IsMounted, ArePlayerWeaponsSheathed.

Registered events: EVENT_ACTION_SLOT_ABILITY_USED, EVENT_ACTION_UPDATE_COOLDOWNS, EVENT_COMBAT_EVENT, EVENT_EFFECT_CHANGED, EVENT_ACTION_SLOTS_ACTIVE_HOTBAR_UPDATED, EVENT_WEAPON_PAIR_LOCK_CHANGED, EVENT_PLAYER_DEAD, EVENT_MOUNTED_STATE_CHANGED, EVENT_PLAYER_ACTIVATED, EVENT_PLAYER_DEACTIVATED. Runtime continues the single existing 16 ms update subscription; the feature adds no second timer, controls, input hooks or automated gameplay.

Four reference-used result globals (ACTION_RESULT_BEGIN, ACTION_RESULT_BEGIN_CHANNEL, ACTION_RESULT_EFFECT_GAINED, ACTION_RESULT_EFFECT_FADED) are absent from the local public API 101051 enum snapshot. The reference uses them as client globals. They are explicitly nil-guarded, never supplied guessed numeric values. The temporary capability-printing probe was removed after client acceptance. Heavy start requires at least an emitted BEGIN variant; without it Heavy stays inactive. Cooldown-confirmed casts can still work. The API checker lists these exceptions explicitly; tests cover missing globals. This is a version-sensitive compatibility assumption, not an assertion of a documented universal active-cast API.

## OneCrosshair ownership and changes

`Effects/HeavyChannel.lua` owns pending confirmation and one state record: active, kind (heavy/channel/cast), progress, abilityId, duration, startMs/endMs and the one-frame Heavy completion marker. Diagnostic source/reason/timestamps and serial counters were removed. `Read(enabled, now)` retains its numeric-progress-or-nil presentation contract; the existing provider seam remains available for contract tests. `Stop` ends ownership; natural completion can retain a separately queued next candidate, while block/death/disable clear it. Full Heavy completion has the one green update explicitly approved for 0.1.6; channels/casts do not.

Runtime initializes the module, updates HeavyChannel before GCD diagnostics and applies the existing priority: Heavy/Channel/Cast gray progress > current GCD presentation > idle. Hidden HUD updates still expire/cancel timing, and deactivation clears it. GCD tracking continues independently while the overlay owns the visible bar. There is no normal GCD reset/restart or second green-window algorithm. Normal GCD/weaving math remains unchanged from the accepted 0.1.4 implementation. In 0.1.6 only diagnostics were removed from GCD; two tests now assert active state instead of the deleted diagnostic cycle counter.

No reference UI, settings, localization, SavedVariables, images, sounds, statistics, stack tracker, dependency library, remaining-time direction, max(GCD,cast) presentation or extra weaving window was copied. Only narrow mechanisms and necessary exception data were adapted into independent code.

Current cleanup changes are listed in CLEANUP_0_1_6.md; the reference algorithm research above remains applicable.

## Concrete timelines

These are examples using API-reported durations, not universal weapon timings. Progress = clamp((now-start)/duration). Normal visibility settings still apply; events update ownership immediately, rendering observes it on the next normal update.

| Heavy example: API duration 1000 ms | State |
| --- | --- |
| 0 ms, equipped Heavy BEGIN | gray 0%, owns bottom |
| 250 ms | gray 25% |
| 500 ms | gray 50% |
| 750 ms | gray 75% |
| 1000 ms | endpoint 100%; one full-green Heavy completion frame, then current GCD/idle on the next update |
| Alternative: release at 600 ms | matching release/cooldown signal ends ownership at 60%; current GCD/idle restored |

| Channel example: API duration 2000 ms | State |
| --- | --- |
| 0 ms, confirmed start | gray 0%, owns bottom |
| 500 ms | gray 25% |
| 1000 ms | gray 50%, even if the original GCD has already ended |
| 1500 ms | gray 75% |
| 2000 ms | endpoint 100%, then idle or current GCD |
| Alternative: block at 700 ms | owner ends on update; a 1000 ms underlying GCD shows actual 70% progress / 300 ms left |

A 600 ms cast finishes at 600 ms, not at the end of its 1000 ms GCD. If an overlay ends with only 80 ms GCD left and ping=100 ms, the existing GCD model immediately supplies full green. The single Heavy completion frame reuses the existing GCD green; channels/casts are not held. No text/icons or new colors are introduced.

## Validation and remaining limitations

The GCD/weaving and Heavy/channel behavior regressions remain; diagnostic-only tests were removed in 0.1.6. The new suite exercises native event starts, progress, release signatures, natural completion, incoming CC, block/dodge/swap, fade/failure/target death, weapon unlock, lifecycle, feature on/off, Heavy/channel transitions back to gray/green GCD or idle, queued confirmation/expiry, failed repeat input, duplicates, wrong source/target, crafted IDs, Crux, beam epochs, unsupported toggles, invalid metadata, absent result globals and cancellation/ownership restoration. Seven locale load orders and public-symbol checks also run. Mocks verify the state machine and presentation contracts, not real client event semantics.

There is no universal authoritative release/cancel query. A missed end signal can leave a finite progress estimate visible until its expected end, but cannot extend that owner indefinitely; duplicate Heavy BEGIN does not refresh the timer. Zero-duration/invalid metadata and excluded indefinite channels do not create an owner. Beam fade requires a correlated gain/update from the current effect epoch; missing gain events fall back to other cancellation signals/timeout. Other channels can have indistinguishable same-ID late fades; ID/target checks reduce but do not eliminate ambiguity. Very late starts, weapon-specific charge behavior, API changes and scribed variants beyond the reference corrections need client validation. No claim of universal production reliability is made based solely on mocks.

Client acceptance supplied by the user: Heavy start/progress/completion, early release, Block/Dodge cancellation; Channel start/progress/normal completion, movement without false cancellation, Block/Dodge interruption; correct bottom-bar ownership/restoration. Remaining heuristics and special-ability caveats above are retained for future API updates. After reloading 0.1.6, visually verify only the new one-frame Heavy completion polish and unchanged early-cancel behavior. No developer slash command or capture system remains.
