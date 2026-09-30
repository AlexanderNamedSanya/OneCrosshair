# OneCrosshair 0.1.6 cleanup / polish

Heavy/Channel 0.1.5 is accepted by the user in the ESO client: Heavy start/progress/completion/early release/Block/Dodge, Channel start/progress/completion/movement/Block/Dodge, and ownership restoration. The underlying reference-derived state remains a combination of events, API metadata and heuristics, not a universal authoritative ESO progress API.

## Changes

- Removed the diagnostic runtime module, slash command, capture/history/paging/summary/chat formatting, raw slot-1 reads, diagnostic cycle counter and Heavy source/reason/serial/stopped snapshots. Removed the diagnostic-only tests and guide; retained the supplied GCD trace as a standalone behavior test.
- Heavy/Channel remains the existing On/Off control. Removed the warning tooltip and its EN/RU string IDs; no added setting.
- Added `HeavyChannel.Presentation(progress)`: nil has no owner, progress <1 uses gray, progress >=1 draws **all** bottom geometry with the existing `GCD.readyColor` at full intensity.
- The user explicitly authorized **one green frame for a fully completed Heavy**. At the existing `now >= endMs` boundary, a visible active Heavy returns progress=1 once and marks that frame consumed. The next update releases ownership. A full release/fade/cooldown ending that arrives before rendering can preserve that single frame. The timing interval itself is unchanged. The next Heavy can start during this presentation frame without being mistaken for a duplicate start.
- Early Heavy release, Block, Dodge, interruption, disable and other cancellations never schedule a completion frame. Hidden gameplay skips it. An underlying GCD can independently restore green if its own weaving window is active.
- Channel/Cast receives **no timer extension, post-completion hold or forced flash**. The renderer supports full green only for an actually returned full-progress owner. The current native channel/cast reader terminates at its duration boundary, so completion green is normally not observable; it immediately reveals current GCD/idle. This deliberately prioritizes the accepted termination timing.
- Normal GCD selection, progress, cycle reset detection, latch and `remaining <= min(GetLatency(),150)` threshold are unchanged. GCD code edits only remove diagnostics. Two existing weaving assertions now inspect active state instead of the removed diagnostic cycle number; all scenarios and threshold assertions remain.

## Files

Runtime: `HUD/GCD.lua`, `Effects/HeavyChannel.lua`, `Core/Runtime.lua`, `Settings/Settings.lua`, `Localization/en.lua`, `Localization/ru.lua`, `OneCrosshair.txt`, `Core/Namespace.lua`; deleted `HUD/GCDDiagnostics.lua`. Detection exception data, ResourceRing and the entry point are unchanged.

Tests: retained behavior and weaving coverage, removed diagnostic-only cases, moved trace replay into `tests/gcd_trace.lua`, extended Heavy/Channel cases and adjusted the runner. Deployment explicitly removes only the retired diagnostic runtime file within the OneCrosshair destination and checks its absence; current runtime files still use hash verification. Documentation is updated; the API/reference investigation history remains where useful.

## Validation

64 Lua 5.1 behavior scenarios pass. This includes full progress/whole-bar green, one-frame consumption, full release events arriving before rendering, cancellation non-flashes, Channel/Cast no-hold behavior, correct restored gray/green GCD, feature On/Off, immediate next Heavy, no debug output and no extra update loop. Manifest initialization in all seven locales and public API-symbol checks pass, retaining the four explicitly guarded reference-result exceptions.

Runtime source audit finds no diagnostic command/capture/storage/formatting or obsolete capability-warning strings. Only removal assertions in tests and the explicit retired-file entry in deployment mention deleted diagnostics. No listeners existed solely for diagnostics; all remaining timing listeners still serve accepted gameplay behavior.

After reload, visually check the newly authorized single Heavy completion frame, which is one normal update (nominally 16 ms, frame-rate dependent). Previously accepted detection/cancellation does not need to be recharacterized; confirm that early cancellation remains flash-free. Channel completion intentionally may have no visible green. No broad timing redesign, extra latency window or new color was introduced.
