# UI Visual Themes

> **Use this page when:** you want WMP interfaces to match a modern, Second World War, Vietnam/Cold War, science-fiction or fantasy/olden-times mission without changing how any feature works.

WMP has one visual theme setting shared by its notification cards, SafeStart, electronic-warfare display, hazardous-environment status, tactical display, interaction equipment, Economy authoring prompts and table-game interface chrome. Themes change fonts, materials, rails, control chrome, copy motifs, colours and accents only. Control positions, input handling, feature state, authority and gameplay rules do not change.

Set the mission style near the top of `init.sqf`, before the guarded WMP default:

```sqf
Waldo_UI_Theme = "VIETNAM";
```

Built-in values are:

| ID | Presentation |
|---|---|
| `DEFAULT` | Modern dark-blue tactical glass, clean top rails and concise WMP system labels |
| `WW2` | Olive field equipment, khaki paper/brass tones, bottom rule and War Department field-order copy |
| `VIETNAM` | Green phosphor/field-radio shell, amber controls, double scan rails and field-net copy |
| `SCIFI` | Deep navy node display, cyan/magenta split rails, bracketed titles and system-status copy |
| `PARCHMENT` | Aged parchment and wax-seal red, gilt double rails, "Royal Chancery" proclamation copy for fantasy/olden-times missions |

Semantic success, warning and error colours remain distinct in every style. Every state also carries a written state and symbol, and interaction procedures use labels, shapes or patterns rather than requiring colour recognition.

## Personal colour-vision profiles

Every player has a local colour-vision overlay independent of the mission-wide era theme. Open **ACE Self Interact > WMP Interface > Accessibility > Colour Vision Settings** and select:

| Profile | Purpose |
|---|---|
| `STANDARD` | Era theme's original semantic palette |
| `RED_GREEN` | Blue/cyan/amber/violet separation for common red-green deficiencies |
| `PROTAN` | Avoids dark-red cues and uses cyan/blue/gold/magenta states |
| `TRITAN` | Turquoise/green/vermilion/magenta separation for blue-yellow deficiencies |
| `HIGH_CONTRAST` | Widens separation between semantic/focus states toward white/grey; symbol-led |

Every profile follows the same rule: it overrides only the semantic/focus tokens (accent, success, warning, danger and their active/hex variants) - never a theme's own panel, chrome, material or text colours. The choice is stored in `profileNamespace`, applies immediately to theme-aware displays and persists for that player. It is never broadcast: two players can use different colour-vision profiles while seeing the same WW2, Vietnam or SCIFI mission theme, and the theme's own stylistic identity is always preserved. Mission makers should not set this globally.

The shared resolver applies the personal profile after mission theme overrides. Use `Waldo_fnc_UiColourVisionApplyLocal` only for local accessibility tooling; use `Waldo_fnc_UiThemeSetServer` for the mission-wide era.

## Live QA switch

**UI QA - Set Visual Theme** provides a named dropdown for all five styles. The server publishes the chosen style globally; connected clients apply it immediately and JIP clients receive the durable current value. Open WMP notification cards are re-rendered in place without replaying or extending them, including font-dependent height and rail orientation. Tagged interaction-equipment plugins, party-game chrome and Economy prompts update their cached presentation tokens and existing controls. SafeStart, electronic-warfare and hazardous-environment HUDs resolve the new style on their next service refresh. The optional preview sends only the requesting curator notification cards to verify styling and top-right stacking. The full-pack audit theme station can also open the player-facing colour-vision selector and exercise every built-in profile.

Live selections are included in WMP's ordered runtime snapshot as well as the public mission value, so a joining player resolves the server's current style before optional feature interfaces activate.

## Concurrent HUD ownership

WMP treats screen regions as shared space rather than letting each feature draw at a fixed unrelated coordinate. Any persistent or specialist HUD registers its live controls and affected notification placements through `Waldo_fnc_RegisterUiReservationLocal`, updates the reservation when it shows or hides, and removes it through `Waldo_fnc_UnregisterUiReservationLocal` during teardown. The notification service then calculates its stack cursors from the shared registry; it contains no SafeStart, jammer, Rally, or other feature-specific collision rules.

SafeStart, electronic warfare and hazardous environments are current consumers of this global hook. SafeStart reserves the top-centre banner, electronic warfare owns a lower-right specialist panel above the radio overlay, and live hazard exposure owns a continuously updated lower-left specialist panel. Hazard and jammer panels can therefore coexist without either becoming a notification-card stream; ordinary notification stacks reflow around their active reservations. Older logistics centre text is routed through the same service as a replaceable compatibility channel. New WMP HUD plugins must register their occupied controls instead of adding pairwise deconfliction logic.

Opening ACE interaction temporarily hides notification cards and the persistent SafeStart/electronic-warfare cards. Their state is retained, still-valid queued messages remain bounded, and the complete layout is reflowed when ACE interaction closes. This makes ACE the deliberate input and draw-priority owner rather than allowing a Rally notification or jammer status to cover its radial menu.

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
