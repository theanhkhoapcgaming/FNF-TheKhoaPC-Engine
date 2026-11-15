# Base Game pack (P-Slice source patch)

## Runtime folder

The patched source expects the mutable Base Game pack at `assets/basegame/`, relative to the game's runtime working directory. Keep the files there so they can be updated without rebuilding the executable.

Minimum layout:

```text
assets/
└── basegame/
    ├── pack.json
    ├── pack.png                 # optional
    ├── data/                    # game data, examples only
    ├── images/                  # game assets, examples only
    └── ...                      # at least one real file besides pack.json
```

`pack.json` must be valid JSON. Example:

```json
{
  "name": "Base Game",
  "description": "Required core game content.",
  "runsGlobally": true,
  "restart": false
}
```

The engine forces the Base Game entry to be globally available while enabled, and resolves its filesystem files before other global mods (a currently selected mod may override a file). The engine startup check intentionally refuses to continue if `assets/basegame/pack.json` is missing/invalid or there is no other file in the Base Game directory tree. A mod marked independent does **not** bypass this startup requirement.

## Independent mods

A regular mod that can function without Base Game should set the exact boolean `IndependentMod` to `true` in its own `mods/<ModFolder>/pack.json`:

```json
{
  "name": "Standalone Mod",
  "description": "Does not depend on Base Game content.",
  "runsGlobally": false,
  "IndependentMod": true
}
```

When at least one such mod is enabled, the Base Game toggle in Mod State may be disabled. Otherwise the Base Game entry is locked and remains enabled. This toggle does not remove the startup requirement for the Base Game files.

## Scope and validation note

This source archive contains the engine source, not the actual game asset payload. Copy your real Base Game data into `assets/basegame/`; this patch does not generate or migrate those files. The source was statically reviewed, but no Haxe compiler/project files were included in the uploaded archive, so a full build could not be run here.
