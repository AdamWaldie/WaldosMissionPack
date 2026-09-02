# UI Visual Themes

> **Use this page when:** you want WMP interfaces to match a modern, historical, retro-futurist, post-apocalyptic, gothic, command-centre, industrial, intelligence, emergency, fantasy or minimal mission without changing how any feature works.

WMP has one visual theme setting shared by its notification cards, SafeStart, electronic-warfare display, hazardous-environment status, tactical display, interaction equipment, Economy authoring prompts and table-game interface chrome. Themes change fonts, materials, rails, control chrome, copy motifs, colours and accents only. Control positions, input handling, feature state, authority and gameplay rules do not change. At the same personal size, every notification theme uses the same footprint and typography scale; `MINIMAL` earns its low-profile identity through reduced visual chrome and transparency rather than smaller text or cards.

Distinct notification materials and silhouettes are assembled programmatically from native Arma
controls. Gothic frames, inset CRT screens, corporate glass, scrap plates, contract tabs and
broadcast banners do not use bundled PNG/PAA textures, imported fonts or theme-specific scripts.
The renderer owns a small fixed set of reusable chrome modes, so these styles add negligible pack
size and continue to share the same stacking, suppression and accessibility behaviour.
The renderer caps the layout canvas against the current safe-zone aspect ratio and screen height,
so lane anchors remain usable on 4:3, 16:10, 16:9 and ultrawide displays.

WMP theme presentation never uses red. Arma reserves red as hostile/enemy language, so built-in
themes use violet for danger and non-red accent/trim colours. The resolver applies the same rule
after custom themes, mission overrides and personal colour-vision overlays; a red input is replaced
with the token's safe blue, green, amber or violet fallback before any WMP control is drawn.

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
| `PARCHMENT` | Aged parchment and wax-seal violet, gilt double rails, handwritten "Royal Chancery" proclamation copy for fantasy/olden-times missions |
| `MINIMAL` | Neutral dark glass at reduced opacity, thin top rail and no source/title copy dressing |
| `NAVAL` | Dark naval-blue Combat Information Centre panels, sea-green tracks, pale-blue trim and CIC contact-report copy |
| `DESERT_STORM` | Charcoal and faded sand command equipment, amber CRT emphasis and CENTCOM tasking/SITREP copy |
| `INDUSTRIAL` | Slate field-operations board, safety-yellow index tab, steel status rules and work-order copy |
| `EASTERN_BLOC` | Gunmetal field apparatus, faded cream text, steel-blue controls and sector-command directive copy |
| `INTELLIGENCE` | Restricted charcoal document panels, muted teal analysis controls, classification-violet trim and intelligence-assessment copy |
| `GRIMDARK` | Vietnam-like olive phosphor field display with amber controls, gothic framing, VOXCASTER traffic labels and Imperial vox-net acknowledgements |
| `ATOMIC_AGE` | Pristine mint-and-cream 1950s retro-futurism, teal controls, gilt trim and civil-defence bulletin copy |
| `WASTELAND` | Battered retro electronics, oxidised teal panels, amber gauges, faded phosphor text and salvaged-relay copy |
| `PMC` | Light silver corporate equipment, cool-blue controls, restrained steel trim and verified-contract tasking copy |
| `RETRO_COMMAND` | Green-phosphor CRT panels, amber keys, scan rails and terse 1970s-80s command-terminal messages |
| `DIESELPUNK` | Symmetrical brass-and-black ministry engine plate, steel braces, warm instrument text and heavy-industry directives |
| `MERCENARY` | Field-worn sand-and-olive contractor kit, muted brass controls and informal job/contract language |
| `PROPAGANDA` | Monumental navy, cream and muted-gold broadcast panels with numbered state directives and oversized institutional copy |
| `EMERGENCY` | Dark incident-command panels, rescue-amber controls, cool-blue trim and active emergency-operations copy |

## Visual chooser

These previews are captured from the real 3840x2160 full-pack audit client. Each image uses the
production resolver and three-card notification preview, so the font, panel material, rail position,
semantic colours and copy treatment are the same ones players receive in a mission.

| | |
|---|---|
| **Default / Modern**<br>![Default theme](assets/ui-themes/default.png) | **Second World War**<br>![WW2 theme](assets/ui-themes/ww2.png) |
| **Vietnam / Cold War**<br>![Vietnam theme](assets/ui-themes/vietnam.png) | **Science Fiction**<br>![Science Fiction theme](assets/ui-themes/scifi.png) |
| **Parchment / Fantasy**<br>![Parchment theme](assets/ui-themes/parchment.png) | **Minimal / Low Profile**<br>![Minimal theme](assets/ui-themes/minimal.png) |
| **Naval / Combat Information Centre**<br>![Naval theme](assets/ui-themes/naval.png) | **Desert Storm / CENTCOM**<br>![Desert Storm theme](assets/ui-themes/desert-storm.png) |
| **Industrial / Operations Control**<br>![Industrial theme](assets/ui-themes/industrial.png) | **Eastern Bloc / Sector Control**<br>![Eastern Bloc theme](assets/ui-themes/eastern-bloc.png) |
| **Intelligence / Restricted**<br>![Intelligence theme](assets/ui-themes/intelligence.png) | **Emergency / Incident Command**<br>![Emergency theme](assets/ui-themes/emergency.png) |
| **Grimdark / Gothic Warfront**<br>![Grimdark theme](assets/ui-themes/grimdark.png) | **Atomic Age / Civil Defence**<br>![Atomic Age theme](assets/ui-themes/atomic-age.png) |
| **Wasteland / Retro Apocalypse**<br>![Wasteland theme](assets/ui-themes/wasteland.png) | **PMC / Corporate Operations**<br>![PMC theme](assets/ui-themes/pmc.png) |
| **Retro Command / CRT**<br>![Retro Command theme](assets/ui-themes/retro-command.png) | **Dieselpunk / Heavy Industry**<br>![Dieselpunk theme](assets/ui-themes/dieselpunk.png) |
| **Mercenary / Field Contract**<br>![Mercenary theme](assets/ui-themes/mercenary.png) | **Propaganda / Central Broadcast**<br>![Propaganda theme](assets/ui-themes/propaganda.png) |

Refresh the complete gallery with:

```powershell
powershell -ExecutionPolicy Bypass -File .\releaseVerificationAndDeployment\capture_ui_theme_gallery.ps1
```

The same run captures a three-card stack at each supported location, proving the full lane rather than one isolated card: `TOP`, `TOP_RIGHT`, `CENTER`, `BOTTOM_LEFT`, `BOTTOM_CENTER` and `BOTTOM_RIGHT`.

| | |
|---|---|
| **Top**<br>![Three-card top stack](assets/ui-themes/notification-position-top.png) | **Top right**<br>![Three-card top-right stack](assets/ui-themes/notification-position-top-right.png) |
| **Centre**<br>![Three-card centre stack](assets/ui-themes/notification-position-center.png) | **Bottom left**<br>![Three-card bottom-left stack](assets/ui-themes/notification-position-bottom-left.png) |
| **Bottom centre**<br>![Three-card bottom-centre stack](assets/ui-themes/notification-position-bottom-center.png) | **Bottom right**<br>![Three-card bottom-right stack](assets/ui-themes/notification-position-bottom-right.png) |

The audit also saturates the configured lanes, verifies that the next FIFO request returns `QUEUED`, frees one bottom-right slot and confirms that the waiting request drains into that slot. Non-standard themes do not own separate queue code: every material and silhouette uses this same bounded registry, overflow order and reflow path.

Semantic success, warning and error colours remain distinct in every style. Every state also carries a written state and symbol, and interaction procedures use labels, shapes or patterns rather than requiring colour recognition.

## Personal colour-vision profiles

Every player has a local colour-vision overlay independent of the mission-wide era theme. Open **ACE Self Interact > WMP Options > Accessibility Settings** and select:

| Profile | Purpose |
|---|---|
| `STANDARD` | Era theme's original semantic palette |
| `RED_GREEN` | Blue/cyan/amber/violet separation for common red-green deficiencies |
| `PROTAN` | Avoids dark-red cues and uses cyan/blue/gold/magenta states |
| `TRITAN` | Turquoise/green/vermilion/magenta separation for blue-yellow deficiencies |
| `HIGH_CONTRAST` | Widens separation between semantic/focus states toward white/grey; symbol-led |

Every profile follows the same rule: it overrides only the semantic/focus tokens (accent, success, warning, danger and their active/hex variants) - never a theme's own panel, chrome, material or text colours. The choice is stored in `profileNamespace`, applies immediately to theme-aware displays and persists for that player. It is never broadcast: two players can use different colour-vision profiles while seeing the same WW2, Vietnam or SCIFI mission theme, and the theme's own stylistic identity is always preserved. Mission makers should not set this globally.

The shared resolver applies the personal profile after mission theme overrides. Use `Waldo_fnc_UiColourVisionApplyLocal` only for local accessibility tooling; use `Waldo_fnc_UiThemeSetServer` for the mission-wide era.

## Personal notification presentation

Open **ACE Self Interact > WMP Options > Notification UI Settings**. The custom screen provides a notification-only theme, **Small / Medium / Large** size and **Normal / Reduced / Off** motion. **Follow Mission** inherits the mission era. A player-selected built-in or mission custom theme affects notifications only; it does not restyle the WMP HUD or other displays. Mission theme-token overrides and the colour-vision profile remain authoritative overlays. Applying a change immediately restyles and reflows visible stacks, persists in the local profile and is never broadcast to other players.

## Live QA switch

**UI QA - Set Visual Theme** provides a named dropdown for all twenty styles. The server publishes the chosen style globally; connected clients apply it immediately and JIP clients receive the durable current value. Open WMP notification cards are re-rendered in place without replaying or extending them, including font-dependent height and rail orientation. Tagged interaction-equipment plugins, party-game chrome and Economy prompts update their cached presentation tokens and existing controls. SafeStart, electronic-warfare and hazardous-environment HUDs resolve the new style on their next service refresh. The optional preview sends only the requesting curator notification cards to verify styling and top-right stacking. The full-pack audit theme station can also open the player-facing colour-vision selector and exercise every built-in profile.

Live selections are included in WMP's ordered runtime snapshot as well as the public mission value, so a joining player resolves the server's current style before optional feature interfaces activate.

## Concurrent HUD ownership

WMP treats screen regions as shared space rather than letting each feature draw at a fixed unrelated coordinate. Any persistent or specialist HUD registers its live controls and affected notification placements through `Waldo_fnc_RegisterUiReservationLocal`, updates the reservation when it shows or hides, and removes it through `Waldo_fnc_UnregisterUiReservationLocal` during teardown. The notification service then calculates its stack cursors from the shared registry; it contains no SafeStart, jammer, Rally, or other feature-specific collision rules.

SafeStart, electronic warfare and hazardous environments are current consumers of this global hook. SafeStart reserves the top-centre banner, electronic warfare owns a lower-right specialist panel above the radio overlay, and live hazard exposure owns a continuously updated lower-left specialist panel. Hazard and jammer panels can therefore coexist without either becoming a notification-card stream; ordinary notification stacks reflow around their active reservations. Older logistics centre text is routed through the same service as a replaceable compatibility channel. New WMP HUD plugins must register their occupied controls instead of adding pairwise deconfliction logic.

Opening ACE interaction temporarily hides notification cards and the persistent SafeStart/electronic-warfare cards. Their state is retained, still-valid queued messages remain bounded, and the complete layout is reflowed when ACE interaction closes. This makes ACE the deliberate input and draw-priority owner rather than allowing a Rally notification or jammer status to cover its radial menu.

The module is a visual QA and mission-authoring tool. Ordinary missions normally set one style in `init.sqf`.

## Mission extensions

`Waldo_UI_CustomThemes` may provide additional named theme HashMaps and `Waldo_UI_ThemeOverrides` may replace known tokens in the selected theme. Override values must retain the built-in token's type. Red hues are reserved and are normalised to safe token-specific fallbacks; hexadecimal text colours are rebuilt from the accepted array colours. This prevents a malformed or hostile-looking palette from changing UI behavior or bypassing the no-red rule. Optional `chromeMode` values select only renderer-owned procedural layouts; custom themes cannot inject scripts or external texture paths through the theme schema. Procedural chrome is limited to structural edges, headers, footers and reserved semantic zones. The renderer does not generate decorative fake gauges or data marks.

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
