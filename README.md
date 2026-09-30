# OneCrosshair

ESO addon: animated contextual crosshair with four fixed resource bars. Version 0.1.3 targets the inspected ESO UI API **101051**.

## Installation

1. Install **LibAddonMenu-2.0** and its declared dependencies using your addon manager.
2. Copy this folder as `OneCrosshair` into your ESO `live/AddOns` directory. `OneCrosshair.txt` must be directly inside it, not inside another nested folder.
3. Enable the addon and reload the UI. Open Settings → Addons → OneCrosshair. The three white preset examples appear automatically.

Runtime files are the manifest, Lua modules, and `Assets/*.dds`. `tests`, `tools`, and `docs` are development material; `.reference` is ignored research/test tooling and should not be distributed.

## Available

Dot with interpolated Normal/Target/Block geometry; combat red and normal white; independent fixed Health/Magicka/Stamina arcs; overlaid shield; API-driven GCD progress; dynamic/combat/always/off visibility; optional low-resource and critical effects; conservative direct-action feedback; account-wide settings; English/Russian localization; reversible vanilla reticle replacement preserving prompts and stealth UI.

## Explicit API limitations

- **Pursuit yellow**: no reliable general pursuit state was verified; the renderer supports yellow but the detector does not guess it from hostile targets or combat.
- **Green readiness**: the client trace showed slot 1 mirroring the ability GCD. Version 0.1.3 exempts this exactly matching global timer while retaining used/usable/no-failure checks and blocking separate cooldowns. Trace replay passes; client confirmation is still needed. This is a state-based cue, not guaranteed optimal server weaving timing. [Diagnostic commands](docs/GCD_DIAGNOSTICS.md) remain available; no timing constants are guessed.
- **Heavy/Channel progress**: setting and presentation integration exist, but no built-in timing provider is enabled. Tooltip cast durations do not establish actual start/cancel/release. No simulated progress is shown.
- **Combat feedback**: a direct damage result must match recent player action evidence. Periodic results, incoming damage, uncorrelated procs and healing do not trigger it. Abilities with differing slot/impact IDs may be intentionally missed; delayed impacts after 1.5 s are ignored. This evidence window is not a GCD timer.

See [API research](docs/API_RESEARCH.md) for sources and the required client test matrix. This repository was checked with a mocked ESO environment running real Lua 5.1; **in-client compatibility and visual quality still need validation**.

## Development checks

Install Python packages `lupa` and `Pillow` in your development environment, then run:

```text
python tests/run.py
python tools/generate_assets.py
```

The first command checks manifest order, initialization, localization, behavior and (when `.reference/API.txt` exists) referenced engine symbols. The second regenerates the original DDS textures. Tests are contracts, not a substitute for running ESO.
