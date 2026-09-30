# OneCrosshair

ESO addon: animated contextual crosshair with four fixed resource bars. Version 0.1.6 targets the inspected ESO UI API **101051**.

## Installation

1. Install **LibAddonMenu-2.0** and its declared dependencies using your addon manager.
2. Copy this folder as `OneCrosshair` into your ESO `live/AddOns` directory. `OneCrosshair.txt` must be directly inside it, not inside another nested folder.
3. Enable the addon and reload the UI. Open Settings → Addons → OneCrosshair. The three white preset examples appear automatically.

Runtime files are the manifest, Lua modules, and `Assets/*.dds`. `tests`, `tools`, and `docs` are development material; `.reference` is ignored research/test tooling and should not be distributed.

## Available

Dot with interpolated Normal/Target/Block geometry; combat red and normal white; independent fixed Health/Magicka/Stamina arcs; overlaid shield; API-driven GCD progress; dynamic/combat/always/off visibility; optional low-resource and critical effects; conservative direct-action feedback; account-wide settings; English/Russian localization; reversible vanilla reticle replacement preserving prompts and stealth UI.

## Explicit API limitations

- **Pursuit yellow**: no reliable general pursuit state was verified; the renderer supports yellow but the detector does not guess it from hostile targets or combat.
- **Weaving cue**: the whole bottom bar turns green in the last `min(GetLatency(), 150)` ms of the current GCD and stays green until completion. This adapts CombatMetronome's ping-zone heuristic, not LA usability or a guaranteed engine input window. [Reference analysis](docs/WEAVING_REFERENCE.md). Normal GCD/weaving is confirmed working in-game.
- **Heavy/Channel progress**: enabled through the existing setting; event-derived finite charge/cast/channel progress temporarily owns the bottom bar. Full Heavy completion shows one green frame; early cancellation and Channel/Cast completion restore current GCD/idle without an added hold. Uses narrow CombatMetronome mechanisms without a dependency. [Algorithm, exceptions and limitations](docs/HEAVY_CHANNEL_REFERENCE.md); the user confirmed start/progress/completion, early Heavy release, Block/Dodge cancellation and ownership restoration in ESO.
- **Combat feedback**: a direct damage result must match recent player action evidence. Periodic results, incoming damage, uncorrelated procs and healing do not trigger it. Abilities with differing slot/impact IDs may be intentionally missed; delayed impacts after 1.5 s are ignored. This evidence window is not a GCD timer.

See [API research](docs/API_RESEARCH.md) for sources and the required client test matrix. This repository was checked with a mocked ESO environment running real Lua 5.1; the accepted runtime behavior is documented in [project context](docs/PROJECT_CONTEXT.md). The new completion polish should be visually checked after reload.

## Development checks

Install Python packages `lupa` and `Pillow` in your development environment, then run:

```text
python tests/run.py
python tools/generate_assets.py
```

The first command checks manifest order, initialization, localization, behavior and (when `.reference/API.txt` exists) referenced engine symbols. The second regenerates the original DDS textures. Tests are contracts, not a substitute for running ESO.
