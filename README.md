# OneCrosshair

**Version 1.0 — oneDOK** · ESO UI API **101051**

Animated crosshair presets with a contextual resource ring and a Light Attack weaving cue.

## Installation

1. Install LibAddonMenu-2.0 and its dependencies separately.
2. Extract `OneCrosshair-1.0.zip` into your ESO `live/AddOns` directory. The result must be `AddOns/OneCrosshair/OneCrosshair.txt`.
3. Run `/reloadui`, enable the addon and open Settings → Addons → OneCrosshair.

## Features

- Five presets: Dot, Large Dots, Rays, Diamonds and ESO Default.
- Smooth Normal/Target/Block transitions. Rays unfold into corners and rearrange when blocking.
- White outside combat, red in combat, including the native ESO preset. Native targeting and stealth behavior remain; the hit-color timeline is suppressed while the addon owns native color so it cannot overwrite the combat tint.
- Health, Magicka, Stamina, shield and a center-out bottom timing bar; configurable feature toggles and visibility modes.
- Full-arc outward warnings for low resources.
- GCD and finite cast/channel weaving cues, plus Heavy Attack progress.
- English/Russian localization, account-wide settings and isolated three-state previews with bars.

## Fixed release appearance

The five appearance sliders remain visible but locked. Edit the commented values in `Core/Config.lua`, then `/reloadui`:

| Value | Release setting |
| --- | --- |
| Arc length | 90% |
| Ring radius | 45.25 UI units |
| Line thickness | 5 UI units |
| Custom crosshair opacity | 65% |
| Resource/HUD opacity | 50% |

These code values override old saved appearance settings on load. Preset, visibility and feature choices remain configurable. Native ESO keeps its own alpha. Dot is 3 UI units in diameter; Large Dots is 15. Dot spacing is 25% wider than in 0.1.11.

## Timing limitations

The green next-LA cue is a latency heuristic: the remaining GCD, and any active finite cast/channel, must be within `min(ping,150 ms)`. It is not a guaranteed engine input window. Unknown or indefinite cast durations do not fabricate progress. Full Heavy completion retains its approved one green update; early cancellation does not. Timing research is in `docs/WEAVING_REFERENCE.md` and `docs/HEAVY_CHANNEL_REFERENCE.md`. CombatMetronome is not a dependency.

## Development

`python tests/run.py` runs Lua 5.1 contract tests (requires lupa). `python tools/package_release.py` creates and verifies the runtime-only ZIP and SHA-256 file in `dist`. Development/reference folders, SavedVariables and third-party addons are excluded. `tools/deploy.ps1` installs runtime files and checks hashes. Mock tests do not replace final in-game verification.
