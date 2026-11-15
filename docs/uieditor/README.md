# Per-mod UI Editor (P-Slice)

Each mod can add its own UI layout overrides in:

```text
mods/<Your Mod>/uieditor/
```

Use these JSON files (all optional):

- `main-menu.json` — Main Menu
- `story-menu.json` — Story Menu
- `freeplay.json` — Freeplay
- `credits.json` — Credits

The game loads the UI layout file selected by the UI Editor's mod-source rules. If a file or element is absent, the normal P-Slice layout is kept. These files do not replace menu logic or input handling.

Each file uses an `elements` object. You can also set the top-level `scrollDirection` to `"vertical"` (default) or `"horizontal"` for Story week selection or Freeplay song selection. Difficulty scrolling automatically uses the opposite axis. For example, `"scrollDirection": "horizontal"` makes week/song selection horizontal and difficulty scrolling vertical.

The element names below are the keys supported by this implementation. Properties are optional:

- `x`, `y`: absolute screen/world position
- `scaleX`, `scaleY`: sprite scale
- `alpha`: opacity from `0` to `1`
- `visible`, `active`: booleans
- `angle`: rotation in degrees
- `color`: hex RGB string such as `"#FF00AA"` or `"FF00AA"`
- `scrollFactorX`, `scrollFactorY`: camera scroll factors
- `text`, `textSize`: only for `FlxText` elements

For example, `mods/My Mod/uieditor/main-menu.json`:

```json
{
  "elements": {
    "menu_story_mode": { "x": 140, "y": 160, "scaleX": 1.1, "scaleY": 1.1 },
    "menu_freeplay": { "x": 140, "y": 300 },
    "menu_credits": { "alpha": 0.8 },
    "background": { "color": "#223344" },
    "options": { "x": 1180, "y": 620 }
  }
}
```

## Supported element IDs

### `main-menu.json`
`background`, `transitionOverlay`, `gf`, `gfDanceTitle`, `options`, `achievements`, plus `menu_story_mode`, `menu_freeplay`, `menu_mods`, `menu_credits`, `menu_how_to_play` as available in that menu.

### `story-menu.json`
`background`, `headerBar`, `weekAccent`, `tracksImage`, `score`, `weekTitle`, `tracklist`, `leftDifficultyArrow`, `rightDifficultyArrow`, `difficulty`, `week_0`, `week_1`, ... , `character_0`, `character_1`, `character_2`, `lock_0`, `lock_1`, ... . Week and lock IDs follow the displayed order.

### `freeplay.json`
`dj`, `characterHint`, `topLeftTitle`, `titleBackground`, `highscoreIcon`, `clearBox`, `completionText`, `songTitle`, `score`, `letterSort`, `overhang`, `albumRoll`, `difficultyLeft`, `difficultyRight`, `backingImage`, `rankBackground`, `capsule_0`, `capsule_1`, ... . Capsule IDs follow the current group order.

### `credits.json`
`background`, `description`, `descriptionBox`, `entry_0`, `entry_1`, ... , `icon_0`, `icon_1`, ... . Entry/icon IDs follow the generated list order.

`customElements` can add static sprites, text, and animated sprites. Custom elements do not create new menu buttons or change navigation logic.

## Adding custom elements

Use the top-level `customElements` array to add elements that are not part of the original menu. Supported types are:

- `sprite` — a static image
- `text` — a text element
- `animatedSprite` — an animated Sparrow-atlas sprite

Put custom images inside your mod's normal `images/` directory (for example, `mods/My Mod/images/uieditor/logo.png`) and refer to them without the extension.

### Static sprite

```json
{
  "customElements": [
    {
      "id": "mod_logo",
      "type": "sprite",
      "image": "uieditor/logo",
      "x": 24,
      "y": 24,
      "scaleX": 0.5,
      "scaleY": 0.5,
      "alpha": 1,
      "color": "#FFFFFF",
      "antialiasing": true
    }
  ]
}
```

### Text

```json
{
  "customElements": [
    {
      "id": "mod_tagline",
      "type": "text",
      "text": "My Mod",
      "x": 24,
      "y": 100,
      "width": 420,
      "textSize": 28,
      "color": "#FFFFFF",
      "font": "vcr.ttf"
    }
  ]
}
```

### Animated sprite

`animatedSprite` uses a Sparrow atlas. Set `image` to the atlas path without the file extension, define its animations in `animations`, and choose the initial animation with `playAnimation`.

```json
{
  "customElements": [
    {
      "id": "customGF",
      "type": "animatedSprite",
      "image": "characters/gf",
      "x": 500,
      "y": 200,
      "scaleX": 1,
      "scaleY": 1,
      "alpha": 1,
      "color": "#FF88CC",
      "antialiasing": true,
      "animations": [
        {
          "name": "danceLeft",
          "prefix": "GF Dancing Beat LEFT",
          "fps": 24,
          "loop": false
        },
        {
          "name": "danceRight",
          "prefix": "GF Dancing Beat RIGHT",
          "fps": 24,
          "loop": false
        }
      ],
      "playAnimation": "danceLeft"
    }
  ]
}
```

Animation fields:

- `name`: animation name used by `playAnimation`
- `prefix`: Sparrow atlas frame prefix
- `fps`: animation frame rate
- `loop`: whether the animation loops
- `playAnimation`: animation to play when the custom element is created

### Color and appearance

`color` is supported by custom sprites, animated sprites, and text. Use a six-digit RGB hex value:

- `"#FF0000"` — red
- `"#00FF00"` — green
- `"#0000FF"` — blue
- `"#FFFFFF"` — white / no tint

Other appearance fields include `alpha`, `visible`, `angle`, `scaleX`, and `scaleY` where applicable. `antialiasing` can be set on image-based custom elements.

## Controlling draw order with `objectOrder`

Use the top-level `objectOrder` array to control the front-to-back order of existing elements and custom elements. Entries are element IDs. The array is ordered from **back to front**: the first ID is drawn behind later IDs, and later IDs are drawn in front.

```json
{
  "objectOrder": [
    "background",
    "gfDanceTitle",
    "menu_story_mode",
    "menu_freeplay",
    "mod_logo",
    "customGF"
  ],
  "customElements": [
    {
      "id": "mod_logo",
      "type": "sprite",
      "image": "uieditor/logo",
      "x": 24,
      "y": 24
    },
    {
      "id": "customGF",
      "type": "animatedSprite",
      "image": "characters/gf",
      "x": 500,
      "y": 200,
      "animations": [
        {
          "name": "danceLeft",
          "prefix": "GF Dancing Beat LEFT",
          "fps": 24,
          "loop": false
        }
      ],
      "playAnimation": "danceLeft"
    }
  ]
}
```

- Use the same `id` that identifies an existing element or a custom element.
- Custom element IDs can be mixed with existing element IDs in the same array.
- Elements omitted from `objectOrder` keep their default ordering.
- The order is applied within the UI container/group that owns the elements. It does not move an element across separate parent groups or camera layers.

## Complete example

```json
{
  "scrollDirection": "horizontal",
  "objectOrder": [
    "background",
    "gfDanceTitle",
    "menu_story_mode",
    "menu_freeplay",
    "mod_logo",
    "customGF"
  ],
  "elements": {
    "gfDanceTitle": {
      "x": 700,
      "y": 100,
      "scaleX": 1.2,
      "scaleY": 1.2,
      "color": "#FFFFFF"
    },
    "menu_story_mode": {
      "x": 140,
      "y": 160
    }
  },
  "customElements": [
    {
      "id": "mod_logo",
      "type": "sprite",
      "image": "uieditor/logo",
      "x": 24,
      "y": 24,
      "scaleX": 0.5,
      "scaleY": 0.5,
      "color": "#FFFFFF"
    },
    {
      "id": "customGF",
      "type": "animatedSprite",
      "image": "characters/gf",
      "x": 500,
      "y": 200,
      "scaleX": 1,
      "scaleY": 1,
      "color": "#FF88CC",
      "animations": [
        {
          "name": "danceLeft",
          "prefix": "GF Dancing Beat LEFT",
          "fps": 24,
          "loop": false
        },
        {
          "name": "danceRight",
          "prefix": "GF Dancing Beat RIGHT",
          "fps": 24,
          "loop": false
        }
      ],
      "playAnimation": "danceLeft"
    }
  ]
}
```

Coordinates in `x` are adjusted by the UI Editor's Wide Screen Mode offset. Enter the normal layout coordinate; the UI Editor applies the offset automatically.

These files adjust UI presentation only. Existing menu navigation and input handling remain engine-controlled. Custom elements do not automatically gain menu navigation or interactive button behavior.
