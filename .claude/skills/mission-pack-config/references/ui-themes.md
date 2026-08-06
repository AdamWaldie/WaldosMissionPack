# UI visual themes + colour-vision accessibility

Two independent, layered settings: one mission-wide era **theme**
(cosmetic only — fonts/materials/rails/copy, never gameplay/authority) and
one **personal colour-vision profile** per player (never mission-wide).
Shared across notification cards, Safestart, EW display, hazard status,
tactical display, interaction equipment, Economy prompts, table-game chrome.

## Mission theme — config (`MissionConfig\interfaceConfig.sqf` — shared)

```sqf
["Waldo_UI_Theme", "DEFAULT"],           // DEFAULT | WW2 | VIETNAM | SCIFI | PARCHMENT | registered custom ID
["Waldo_UI_CustomThemes", createHashMap],    // ADVANCED: full named custom-theme definitions
["Waldo_UI_ThemeOverrides", createHashMap]   // ADVANCED: partial token overrides for the selected theme
```

| ID | Presentation |
|---|---|
| `DEFAULT` | Modern dark-blue tactical glass, clean top rails |
| `WW2` | Olive field equipment, khaki paper/brass, War Department copy |
| `VIETNAM` | Green phosphor/field-radio shell, amber controls, field-net copy |
| `SCIFI` | Deep navy node display, cyan/magenta rails, bracketed titles |
| `PARCHMENT` | Aged parchment and wax-seal red, gilt double rails, "Royal Chancery" proclamation copy |

Semantic success/warning/error colours, written state text, symbols and
shapes remain distinct/present in every theme — interaction procedures
never require colour recognition alone.

## Personal colour-vision profile (per player, never set mission-wide)

**ACE Self Interact > WMP Interface > Accessibility > Colour Vision
Settings**: `STANDARD`, `RED_GREEN`, `PROTAN`, `TRITAN`, `HIGH_CONTRAST`.
Stored in `profileNamespace` as `Waldo_UI_ColourVisionProfile`, applies
immediately, persists per player, never broadcast — two players can run
different colour-vision profiles under the same mission theme.

```sqf
["RED_GREEN", true] call Waldo_fnc_UiColourVisionApplyLocal;   // local scripted selection only
```

Do not publish this from `initServer.sqf` or overwrite it in `init.sqf` —
it's intentionally different for each player.

## Live Zeus QA switch

**UI QA - Set Visual Theme** — server publishes the chosen style globally;
connected clients apply immediately, JIP gets the durable current value.
Open WMP cards re-render in place (including font-dependent
height/orientation) without replaying/extending. This is a visual QA/
authoring tool — ordinary missions just set one style in the config file.

## Custom theme override example

```sqf
["Waldo_UI_Theme", "WW2"],
["Waldo_UI_ThemeOverrides", createHashMapFromArray [
    ["accent", [0.62, 0.42, 0.14, 1]],
    ["accentHex", "#B88942"]
]]
```

Override values must retain the built-in token's type — this prevents a
malformed palette from changing UI behaviour.

## Gotchas

- Use `Waldo_fnc_UiThemeSetServer` for the mission-wide era,
  `Waldo_fnc_UiColourVisionApplyLocal` only for local accessibility tooling
  — don't mix them up.
- Concurrent HUD ownership (Safestart top-centre, EW lower-right, hazard
  lower-left) is handled via `Waldo_fnc_RegisterUiReservationLocal` — a new
  custom HUD plugin should register its region the same way rather than
  hand-rolling collision avoidance against Safestart/jammer/hazard panels.
