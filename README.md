# OneCrosshair

ESO addon: animated contextual crosshair with four configurable resource arcs. Version 0.1.7 targets the inspected ESO UI API **101051**.

## Installation

1. Install **LibAddonMenu-2.0** and its declared dependencies using your addon manager.
2. Copy this folder as `OneCrosshair` into your ESO `live/AddOns` directory. `OneCrosshair.txt` must be directly inside it, not inside another nested folder.
3. Enable the addon and reload the UI. Open Settings → Addons → OneCrosshair. Three white preset examples and enabled HUD bars appear automatically.

Runtime files are the manifest, Lua modules, and `Assets/*.dds`. `tests`, `tools`, and `docs` are development material; `.reference` is ignored research/test tooling and should not be distributed.

## Available

Dot with interpolated Normal/Target/Block geometry; combat red and normal white; independent configurable Health/Magicka/Stamina arcs; overlaid shield; API-driven GCD progress; dynamic/combat/always/off visibility; whole-arc outward low-resource warnings for HP/MP/Stamina; conservative direct-action feedback; account-wide settings; English/Russian localization; reversible vanilla reticle replacement preserving prompts and stealth UI.

## Explicit API limitations

- **Pursuit yellow**: no reliable general pursuit state was verified; the renderer supports yellow but the detector does not guess it from hostile targets or combat.
- **Weaving cue**: the whole bottom bar turns green in the last `min(GetLatency(), 150)` ms of the current GCD and stays green until completion. This adapts CombatMetronome's ping-zone heuristic, not LA usability or a guaranteed engine input window. [Reference analysis](docs/WEAVING_REFERENCE.md). Normal GCD/weaving is confirmed working in-game.
- **Heavy/Channel progress**: enabled through the GCD setting; event-derived finite charge/cast/channel progress temporarily owns the bottom bar. Cast/channel uses the client-derived timing table and cues LA in the last capped-ping interval, gated by any remaining GCD. Full Heavy completion shows one green frame; cancellation and cast/channel completion restore current GCD/idle without an added hold. Uses narrow CombatMetronome mechanisms without a dependency. [Algorithm, exceptions and limitations](docs/HEAVY_CHANNEL_REFERENCE.md); the user confirmed start/progress/completion, early Heavy release, Block/Dodge cancellation and ownership restoration in ESO.
- **Combat feedback**: a direct damage result must match recent player action evidence. Periodic results, incoming damage, uncorrelated procs and healing do not trigger it. Abilities with differing slot/impact IDs may be intentionally missed; delayed impacts after 1.5 s are ignored. This evidence window is not a GCD timer.

See [API research](docs/API_RESEARCH.md) for sources and the required client test matrix. This repository was checked with a mocked ESO environment running real Lua 5.1; the accepted runtime behavior is documented in [project context](docs/PROJECT_CONTEXT.md). The 0.1.7 geometry and early cast/channel cue should be checked in-game after reload. See [0.1.7 changes](docs/UPDATE_0_1_7.md).

## Development checks

Install Python packages `lupa` and `Pillow` in your development environment, then run:

```text
python tests/run.py
python tools/generate_assets.py
```

The first command checks manifest order, initialization, localization, behavior and (when `.reference/API.txt` exists) referenced engine symbols. The second regenerates the original DDS textures. Tests are contracts, not a substitute for running ESO.
