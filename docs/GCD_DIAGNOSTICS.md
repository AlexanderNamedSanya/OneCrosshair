# GCD diagnostics (0.1.5)

`/ocgcd on` starts a memory-only 15-second capture. `/ocgcd off` stops it, `/ocgcd summary` prints frame counters, and `/ocgcd 1`, `/ocgcd 2`, etc. print eight records per page. Maximum 256 records, periodic active samples every 100 ms plus input/cycle/ready transitions and completion. No extra update/event registrations or SavedVariables. Disabled by default.

After `/reloadui`, compare skill-only and LA -> Skill repetitions. Both should expand gray before the late ping-zone cue. The whole bar should turn green near the end, stay green after pressing LA, and return to gray idle at completion. A new skill starts gray. Existing visibility settings apply. Capture with gameplay visible and chat closed; afterward return pages spanning cue onset/completion and the summary.

| Field | Meaning |
| --- | --- |
| `active`, `ready` | Observed GCD and latched next-LA cue used by rendering |
| `gcd`, `source` | Selected remaining/duration in ms and physical ability slot |
| `ping`, `lead` | Raw GetLatency and capped 0..150 ms cue lead |
| `cycle` | Observed cycle number; resets when runtime model is cleared |
| `api`, `used`, `usable`, `fail` | Raw slot-1 probe availability and state; **not cue gates** |
| `cd` | Slot-1 remaining/duration/global/type, observational only |
| `id`, `type`, `bar` | Slot-1 bound ID, slot type and active hotbar |

Summary counters count active frames, ready frames, waiting frames and missing-latency frames. A ready row can have remaining greater than current lead if ping dropped after cue entry: the cue is deliberately latched. Completion has no slot observations; nil remains nil. Hidden gameplay clears the model, so a completion row may not be captured while the HUD is hidden. Timeout is checked on next capture/command, with no background timer.

With ping=100 and a 1000 ms GCD, ready begins at remaining<=100, not when usable becomes true. The supplied historical trace has only its 33 ms row green at this latency; the next 1000 ms cycle starts gray. If diagnostics show ready but the bar stays gray while visible, report it as a presentation issue. This is a latency heuristic, not a guaranteed engine weaving window; see WEAVING_REFERENCE.md.


## Heavy/Channel capture

The START line reports availability of the four reference-used combat result globals BEGIN/CHANNEL/GAINED/FADED. False is a client capability limitation, not a reason to invent their numeric values.

Rows also include `owner=gcd/heavy/channel/cast/idle`, `progress`, `timingId`, `duration`, `timingSource`, `start`, `end`, `reason`, `stopped`. The timing interval/last stop reason can remain in later GCD/idle rows for diagnosis; `owner` identifies what is currently displayed. `heavyChannel` in summary counts frames with this owner. Heavy-only activity is captured even with no GCD. Snapshots are immutable, changes are recorded immediately on observation, periodic progress samples remain rate-limited. No per-frame chat output.

After `/reloadui`, test full/partial Heavy, block/dodge/swap, short cast, long channel, repeated casts, feature Off/On, and return to GCD/green/idle. Use each relevant weapon. Send summary and pages around transitions if the bar disagrees with animation. See HEAVY_CHANNEL_REFERENCE.md for known limits. Diagnostics run only during visible gameplay; hidden timing is still maintained/expired by Runtime.
