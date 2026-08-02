# UI Visual Themes

> **Use this page when:** you want WMP interfaces to match a modern, Second World War, Vietnam/Cold War or science-fiction mission without changing how any feature works.

WMP has one visual theme setting shared by its notification cards, SafeStart, electronic-warfare display, hazardous-environment status, tactical display, interaction equipment, Economy authoring prompts and table-game interface chrome. Themes change fonts, colours, panels and accents only. Control positions, input handling, feature state, authority and gameplay rules do not change.

Set the mission style near the top of `init.sqf`, before the guarded WMP default:

```sqf
Waldo_UI_Theme = "VIETNAM";
```

Built-in values are:

| ID | Presentation |
|---|---|
| `DEFAULT` | Existing modern WMP dark-blue presentation |
| `WW2` | Olive, khaki and brass with a monospaced field-equipment feel |
| `VIETNAM` | Jungle green, faded cream and field amber |
| `SCIFI` | Deep navy, cyan and high-energy semantic accents |

Semantic success, warning and error colours remain distinct in every style. Game-piece, map-contact and other functional colours are preserved where changing them would make the interface harder to understand.

## Live QA switch

**UI QA - Set Visual Theme** provides a named dropdown for all four styles. The server publishes the chosen style globally; connected clients apply it immediately and JIP clients receive the durable current value. Static displays already open should be closed and reopened for a complete review. Service-driven panels update on their next refresh. The optional preview sends only the requesting curator three notification cards to verify semantic colours and top-right three-lane stacking.

Live selections are included in WMP's ordered runtime snapshot as well as the public mission value, so a joining player resolves the server's current style before optional feature interfaces activate.

The module is a visual QA and mission-authoring tool. Ordinary missions normally set one style in `init.sqf`.

## Mission extensions

`Waldo_UI_CustomThemes` may provide additional named theme HashMaps and `Waldo_UI_ThemeOverrides` may replace known tokens in the selected theme. Override values must retain the built-in token's type. This prevents a malformed palette from changing UI behavior or breaking the shared resolver.

```sqf
Waldo_UI_Theme = "WW2";
Waldo_UI_ThemeOverrides = createHashMapFromArray [
    ["accent", [0.62, 0.42, 0.14, 1]],
    ["accentHex", "#B88942"]
];
```

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
