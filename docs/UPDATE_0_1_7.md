# OneCrosshair 0.1.7

## Skill timing table

`HUD/AbilityTimings.lua` owns `OneCrosshair.AbilityTimings.entries[abilityId]`:

| Field | Meaning |
| --- | --- |
| abilityId / name | Client ID and localized ability name |
| channeled | Cast metadata distinguishes channel from cast |
| baseDuration | Positive finite client cast/channel duration in milliseconds |
| duration | Snapshot duration after the existing Fatecarver correction |
| crux | Fatecarver Crux stacks sampled before the action consumes them |
| excluded | Known indefinite toggles, which cannot give a finite next-LA endpoint |

`Rebuild` enumerates every active skill exposed by the player's skill catalog: all skill types/lines, base and both morphs, four ranks, chained ability IDs, and currently configured scribed abilities. Instant skills (cast duration zero) use normal GCD and do not need a row. Passives are excluded. A duration equal to 1000 ms still belongs in the table if the skill has a real cast/channel: “nonstandard” here means non-instant activation, not merely duration unequal to 1000.

The table is built from the installed client rather than an unverifiable hardcoded list of skill names and patch-sensitive durations. It rebuilds on activation, full skill updates, line additions and crafting exit. `Refresh` re-reads each used ID before timing it, including equipped Heavy and scribing resolution; this covers runtime transformations even when their IDs were absent from the enumerated catalog. Per-action timing copies the row, so later table refreshes do not change a running action.

**Coverage limit:** this is all player abilities exposed by the current client's catalog plus observed runtime IDs, not NPC abilities, other characters' unavailable skill trees or every possible uncrafted scribing combination. No real-client table dump is available from the offline test environment. Unknown/missing/non-finite durations do not fabricate a timer.

Primary API reference: [ESO UI documentation](https://github.com/esoui/esoui/blob/live/ESOUIDocumentation.txt). APIs used: GetNumSkillTypes, GetNumSkillLines, GetNumSkillAbilities, IsCraftedAbilitySkill, GetCraftedAbilitySkillCraftedAbilityId, GetAbilityIdForCraftedAbilityId, IsSkillAbilityPassive, GetSkillAbilityId, GetProgressionSkillProgressionId, GetSpecificSkillAbilityInfo, GetProgressionSkillMorphSlotChainedAbilityIds, GetAbilityCastInfo and GetAbilityName. The inspected snapshot is API 101051. Existing reference analysis remains in HEAVY_CHANNEL_REFERENCE.md and WEAVING_REFERENCE.md.

## Green cue and exceptions

The existing event-confirmed action starts/cancellations are preserved. Cast/channel `Read` checks:

`max(endMs - now, current ability GCD remaining) <= min(max(GetLatency(), 0), 150)`

On first true, ready latches for that action and the entire bottom bar turns green. It releases at the actual endpoint or cancellation; no artificial post-end hold. The user explicitly selected an early next-LA cue. This is a capped latency heuristic, not an authoritative engine weaving window. A finite action can expire without a visible green update when ping is zero or updates skip the final window.

| Scenario, ping 100 ms | Gray progress | Full green | Completion |
| --- | --- | --- | --- |
| Ordinary 1000 ms GCD | 0..899 ms | 900..999 ms | 1000 ms: translucent idle |
| 2000 ms channel, 1000 ms GCD | 0..1899 ms | 1900..1999 ms | 2000 ms: current GCD/idle |
| 600 ms cast under 1000 ms GCD | Cast 0..599; GCD 600..899 | 900..999 ms via GCD | Cast ends 600; GCD ends 1000 |

Boundaries appear on the next update (nominally 16 ms). Consecutive actions reset the latch; confirmed replacement/cancel paths still release ownership immediately. Previous LA presence/hit does not alter the threshold. Heavy retains its separately approved single full-charge green frame, with no early-cancel flash.

Existing corrections/exclusions remain: Fatecarver IDs 183122/193397 add 338 ms per pre-use Crux (0..3); Meditate and Mend Wounds variants are indefinite and excluded; beam fade epoch/target matching and all prior cancellation/error filters are preserved. These narrow exception tables remain in HeavyChannelData. No reference UI, settings, textures, SavedVariables or dependency was copied.

## HUD and settings

- Removed Critical State module, control, labels, dimming and halo. Saved option fields are retired on load.
- Low Resource Warning now covers the entire HP/MP/Stamina arc, independent of its fill. Eight fading radial bands extend outward by two line thicknesses, from nominal R+t/2 through R+2.5t. Native 64-segment curves have subpixel polygon approximation at the boundaries.
- The GCD switch controls normal GCD, Heavy and cast/channel. The separate Heavy/Channel option is removed; the existing GCD value is authoritative during migration.
- Temporary sliders: thickness 1..12 (default 4), radius 20..100 (default 42.25), arc length 0..100% (default 85). Zero hides every ring layer, including warning/shield; 100 closes four full arcs into a circle.
- All three crosshair previews include enabled resource/GCD/shield bars and respect opacity, dimensions and OFF. They use isolated sample values; low HP demonstrates the warning. Large dimensions fit the preview without scaling the real HUD or crosshair.

## Validation and deployment

75 Lua 5.1 behavior scenarios, seven locale/manifest initialization checks and engine symbol validation pass. Added boundary/latch/cancel tests, short-cast GCD gating, catalog morph/rank/chain/scribing coverage, fresh metadata, exception handling, ring closure/zero length, outward glow dimensions, preview isolation and saved-setting migration. Existing normal GCD weaving and Heavy cancellation/completion regressions remain covered.

An offline image generated from actual mocked Lua line endpoints was visually inspected; it is not an ESO screenshot. In-game checks after `/reloadui`: long channel final ping zone, short cast then GCD, LA→Skill repetition, Heavy completion/cancel, low HP/MP/Stamina with partial bars, geometry extremes and settings preview. Changes are installed with tools/deploy.ps1; it verifies SHA-256 hashes and removes only the explicitly retired CriticalState/GCDDiagnostics files. Other addons and SavedVariables are untouched by deployment.
