# UIEditor Custom UI Scripts (P-Slice / V-Slice)

This implementation uses the engine's HScript/Iris interpreter. Custom files use the `.hxc` extension and are loaded at runtime. They are **not compiled Haxe `.hx` source files**.

## Where files go

A custom script must live in the same `uieditor/` folder as the JSON file that registers it.

Base Game example:

```text
<Base Game root>/uieditor/
  story-mode.json
  StoryModeCustom.hxc
```

Mod example:

```text
mods/MyMod/uieditor/
  free-play.json
  FreeplayCustom.hxc
```

The JSON provider determines the script provider. A mod's JSON therefore loads only a script beside that JSON; it cannot accidentally pick up a same-named script from another mod. Base Game layouts are checked first when Base Game is globally mounted; otherwise enabled mods are searched in the configured mod order. Mods do not need an `IndependentMod` flag for UIEditor lookup.

## Register a script

In `story-mode.json`:

```json
{
  "custom-script": "StoryModeCustom",
  "elements": {},
  "customElements": []
}
```

The value is the filename without `.hxc`. The loader also accepts `customScript` for compatibility. Path separators and `..` are rejected. Only `.hxc` is loaded, to avoid confusing interpreted scripts with compiled Haxe source.

## Example script

`StoryModeCustom.hxc`:

```haxe
var title;

function onCreate() {
    title = new FlxText(20, 20, 500, "Custom Story Mode", 24);
    state.add(title);
}

function onUpdate(elapsed) {
    if (title != null) {
        title.alpha = 0.75 + Math.sin(FlxG.elapsed * 2) * 0.25;
    }
}

function onDestroy() {
    // Remove timers/tweens/listeners or objects added to nested groups here.
}
```

Injected variables include:

- `state`: the screen's `FlxState`.
- `uiScreen`: internal screen ID (`story-menu`, `freeplay`, `main-menu`, `title`, or `credits`).
- `uiEditor`: the `UIEditor` class.

Hooks: `onCreate()`, `onUpdate(elapsed)`, and `onDestroy()`.

HScript also exposes the engine APIs registered by `psychlua.HScript` (for example `FlxG`, `FlxSprite`, `FlxText`, `FlxTween`, and `Paths`). The exact available API is the set enabled by this P-Slice build.

## Override and fallback rules

1. UIEditor reads and applies the JSON layout first, preserving it as the fallback configuration.
2. It snapshots JSON-controlled registered sprites and the state's existing top-level members.
3. The custom script is parsed and `onCreate()` is called.
4. Only if loading and `onCreate()` succeed, UIEditor hides/deactivates JSON-registered elements. The custom script then owns the visible UI for that screen.
5. If parsing, `onCreate()`, or `onUpdate()` throws an error, UIEditor logs the failure, calls cleanup when possible, removes top-level state members added after the snapshot, restores the saved JSON-controlled sprite properties, and returns to the JSON UI.
6. When the screen closes normally, `onDestroy()` is called and custom top-level state members are removed; JSON-controlled elements are restored before the state is discarded.

The automatic cleanup tracks top-level `state.members` and registered UI sprites. If a script adds objects to nested groups, starts timers/tweens, or installs external listeners, it should release those resources in `onDestroy()`; the engine cannot safely infer ownership of arbitrary nested resources.

## Notes

- Remove `custom-script` from JSON to use the ordinary JSON layout without a custom override.
- If HScript is not enabled in the build (`HSCRIPT_ALLOWED`), the script is skipped and JSON remains active; a log message is emitted.
- The runtime loader does not compile `.hx` files. Use `.hxc` for runtime custom UI.
