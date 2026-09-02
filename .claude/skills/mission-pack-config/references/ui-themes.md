# UI visual themes + colour-vision accessibility

Two independent, layered settings: one mission-wide era **theme**
(cosmetic only — fonts/materials/rails/copy, never gameplay/authority) and
one **personal colour-vision profile** per player (never mission-wide).
Shared across notification cards, Safestart, EW display, hazard status,
tactical display, interaction equipment, Economy prompts, table-game chrome.

## Mission theme — config (`MissionConfig\interfaceConfig.sqf` — shared)

```sqf
["Waldo_UI_Theme", "DEFAULT"],           // DEFAULT | WW2 | VIETNAM | SCIFI | PARCHMENT | MINIMAL | NAVAL |
                                          // DESERT_STORM | INDUSTRIAL | EASTERN_BLOC | INTELLIGENCE | GRIMDARK |
                                          // ATOMIC_AGE | WASTELAND | PMC | RETRO_COMMAND | DIESELPUNK |
                                          // MERCENARY | PROPAGANDA | EMERGENCY | registered custom ID
["Waldo_UI_CustomThemes", createHashMap],    // ADVANCED: full named custom-theme definitions
["Waldo_UI_ThemeOverrides", createHashMap]   // ADVANCED: partial token overrides for the selected theme
```

Twenty built-in themes:

| ID | Presentation |
|---|---|
| `DEFAULT` | Modern dark-blue tactical glass, clean top rails |
| `WW2` | Olive field equipment, khaki paper/brass, War Department copy |
| `VIETNAM` | Green phosphor/field-radio shell, amber controls, field-net copy |
| `SCIFI` | Deep navy node display, cyan/magenta rails, bracketed titles |
| `PARCHMENT` | Aged parchment and wax-seal violet, gilt double rails, "Royal Chancery" proclamation copy, `PuristaLight`/`PuristaBold` font |
| `MINIMAL` | Low-profile/no-frills style; also the one theme that sets the `compact` token (see below) |
| `NAVAL` | Dark naval-blue Combat Information Centre panels, sea-green tracks, pale-blue trim, CIC contact-report copy |
| `DESERT_STORM` | Charcoal/faded sand command equipment, amber CRT emphasis, CENTCOM tasking/SITREP copy |
| `INDUSTRIAL` | Slate field-operations board, safety-yellow index tab, steel status rules, work-order copy |
| `EASTERN_BLOC` | Gunmetal field apparatus, faded cream text, steel-blue controls, sector-command directive copy |
| `INTELLIGENCE` | Restricted charcoal document panels, muted teal analysis controls, classification-violet trim |
| `GRIMDARK` | Olive phosphor field display, amber controls, gothic framing, VOXCASTER traffic labels/vox-net copy |
| `ATOMIC_AGE` | Pristine mint-and-cream 1950s retro-futurism, teal controls, gilt trim, civil-defence bulletin copy |
| `WASTELAND` | Battered retro electronics, oxidised teal panels, amber gauges, faded phosphor text, salvage copy |
| `PMC` | Light silver corporate equipment, cool-blue controls, restrained steel trim, verified-contract copy |
| `RETRO_COMMAND` | Green-phosphor CRT panels, amber keys, scan rails, terse 1970s-80s command-terminal messages |
| `DIESELPUNK` | Symmetrical brass-and-black ministry engine plate, steel braces, heavy-industry directives |
| `MERCENARY` | Field-worn sand-and-olive contractor kit, muted brass controls, informal job/contract language |
| `PROPAGANDA` | Monumental navy/cream/muted-gold broadcast panels, numbered state directives, oversized copy |
| `EMERGENCY` | Dark incident-command panels, rescue-amber controls, cool-blue trim, active emergency-ops copy |

WMP theme presentation never uses red anywhere (Arma reserves red as
hostile/enemy language) — built-in themes use violet for danger, and the
resolver normalises any red input (custom theme, override, or player
colour-vision remap) to a safe blue/green/amber/violet fallback before
drawing. Semantic success/warning/error colours, written state text,
symbols and shapes remain distinct/present in every theme — interaction
procedures never require colour recognition alone.

### The `compact` token — the one exception to "themes never change size"

Every other theme token is cosmetic only (colour/font/copy) and never
changes a card's layout or size. `compact` is the deliberate, opt-in-only
exception: `showUiNotification.sqf` reads it (`getOrDefault ["compact",
false]`) and scales notification-card width, padding, max content height
and internal text sizes down (~0.78×) when true. Only `MINIMAL` sets it by
default; a custom theme/override can opt into it the same way. Don't add a
second sizing token — extend `compact` (or its consuming scale factor) if
a future theme also needs a smaller footprint.

## Personal colour-vision profile (per player, never set mission-wide)

**ACE Self Interact > WMP Options > Accessibility Settings**: `STANDARD`,
`RED_GREEN`, `PROTAN`, `TRITAN`, `HIGH_CONTRAST`, plus a reduced-motion
toggle shared with notification entry animation. Stored in
`profileNamespace` as `Waldo_UI_ColourVisionProfile`, applies immediately,
persists per player, never broadcast — two players can run different
colour-vision profiles under the same mission theme. The profile remaps
only semantic/focus tokens (accent, success, warning, danger + hex
variants) — it never touches a theme's own panel/chrome/material/text
colours.

```sqf
["RED_GREEN", true] call Waldo_fnc_UiColourVisionApplyLocal;   // local scripted selection only
```

Do not publish this from `initServer.sqf` or overwrite it in `init.sqf` —
it's intentionally different for each player.

## Personal notification presentation (separate from the HUD and the mission theme)

**ACE Self Interact > WMP Options > Notification UI Settings** — a
player-local screen, independent of `Waldo_WmpHud_*` settings below and of
the mission-wide `Waldo_UI_Theme`:

- **Theme**: `Follow Mission` (default) or any built-in/mission-custom
  theme ID — affects **notification cards only**, never the WMP HUD or
  other panels.
- **Size**: `Small` / `Medium` / `Large` card scale.
- **Motion**: `Normal` / `Reduced` / `Off` entry animation.

Mission theme-token overrides and the colour-vision profile are still
applied on top — a player can't use this to bypass either. Apply restyles
visible stacks immediately and reflows them in place; Cancel discards the
pending form; Restore Defaults resets only the form, not other players.
Never broadcast, never persisted mission-side — purely a local preference
(`Waldo_fnc_UiNotificationSettingsApplyLocal`).

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
  `Waldo_fnc_UiColourVisionApplyLocal` only for local accessibility tooling,
  `Waldo_fnc_UiNotificationSettingsApplyLocal` only for the personal
  notification-only theme/size/motion screen — don't mix these up. Only the
  first is mission-wide/authoritative; the other two are per-player and
  never broadcast.
- Concurrent HUD ownership (Safestart top-centre, EW lower-right, hazard
  lower-left) is handled via `Waldo_fnc_RegisterUiReservationLocal` — a new
  custom HUD plugin should register its region the same way rather than
  hand-rolling collision avoidance against Safestart/jammer/hazard panels.
- The ACE Self Interact launcher category is **"WMP Options"** (renamed
  from the old "WMP Interface"), covering Notification UI Settings, WMP
  HUD (+ its own Settings), and Accessibility Settings.
