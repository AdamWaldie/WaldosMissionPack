# WMP HUD

> **Use this page when:** you want friendly 3D identification for a high-technology campaign, or an accessibility aid for specific players in any campaign.

WMP HUD is one local, friendly-only identification system with two independent ways to qualify. A mission can grant it through configured headgear, facewear or NVGs/HMDs. Separately, Steam UIDs in `Waldo_WmpHud_AccessibilityUIDs` always qualify without equipment. An entry in `Waldo_WmpHud_ExcludedUIDs` overrides both routes.

The HUD does not change side relations, AI knowledge or network state. Each client draws only eligible friendly units using local line-of-sight checks. Names and icons have separate ranges, follow animated head positions, respect incapacitation/vehicle policy, and use the active WMP theme plus the player's colour-vision profile.

## Quick setup

Open `MissionConfig\interfaceConfig.sqf` and find the **WMP HUD** block.

1. Leave `Waldo_WmpHud_Enable` as `true` to install the framework.
2. Put accessibility users' Steam UID strings in `Waldo_WmpHud_AccessibilityUIDs`.
3. For a high-tech campaign, add the equipment classnames that should grant access to `Headgear`, `Facewear` or `NVGs`.
4. Leave `AllowEveryone` false unless every player should qualify without equipment.
5. Adjust `IconRange`, `NameRange`, LOS and AI inclusion only if the defaults do not suit the mission.

```sqf
["Waldo_WmpHud_AccessibilityUIDs", ["76561198094931408"]],
["Waldo_WmpHud_Facewear", ["G_Goggles_VR"]],
["Waldo_WmpHud_NVGs", ["NVGogglesB_blk_F"]]
```

The player whose Steam UID matches the listed string qualifies without equipment. Any other player qualifies while wearing the VR goggles or configured NVGs. Replace that example UID with the actual accessibility users for your mission. WMP loads these settings on each client; do not publish them from `init.sqf`.

Open **ACE Self Interact > WMP Options > WMP HUD**. Eligible users receive separate rapid **Enable WMP HUD** and **Disable WMP HUD** actions plus **WMP HUD Settings**. The custom settings screen can hide otherwise permitted icons or names and choose Small/Medium/Large scale and Low/Medium/High opacity. It also explains when the mission has disabled the feature or its eligibility requirement is not met. These controls cannot expand icon/name range, reveal disallowed units, bypass LOS, equipment gates or UID exclusions, or override `AllowToggle`. The local visibility choice survives player-object respawn. Without ACE, equivalent blue addActions are installed.

Cross-interface colour-vision and reduced-motion controls live at **ACE Self Interact > WMP Options > Accessibility Settings**. WMP HUD intentionally has no ZEN module because eligibility and information restrictions are mission authority, not player or Zeus presentation state.

Script APIs are local: `Waldo_fnc_WmpHudInit`, `Waldo_fnc_WmpHudToggle`, `Waldo_fnc_WmpHudStop`, `Waldo_fnc_WmpHudEligible`, `Waldo_fnc_WmpHudPreferences` and `Waldo_fnc_WmpHudSettingsApplyLocal`.

## Settings reference

These are the shipped values in `MissionConfig/interfaceConfig.sqf`. Change the values there, not in `init.sqf`. An empty classname list grants no access by that equipment route. An empty UID exclusion list excludes nobody.

| Setting (`Waldo_WmpHud_` prefix) | Type | Shipped default | Meaning |
| --- | --- | --- | --- |
| `Enable` | Boolean | `true` | Install the local HUD framework. |
| `SystemName` | String | `"WMP HUD"` | Name shown to players. |
| `AccessibilityUIDs` | Array of Steam UID strings | `["76561198094931408"]` | Players who qualify without equipment. Replace this example UID with your own list. |
| `ExcludedUIDs` | Array of Steam UID strings | `[]` | Players who never qualify, even through equipment or allow-everyone. |
| `AllowEveryone` | Boolean | `false` | Grant access without equipment to every non-excluded player. |
| `Headgear` | Array of CfgWeapons classname strings | `[]` | Headgear granting access. |
| `Facewear` | Array of CfgGlasses classname strings | `["G_Goggles_VR"]` | Facewear granting access. |
| `NVGs` | Array of CfgWeapons classname strings | `["NVGogglesB_blk_F"]` | NVG/HMD equipment granting access. |
| `DefaultVisible` | Boolean | `true` | Initial visibility for equipment-qualified players. |
| `AccessibilityDefaultVisible` | Boolean | `true` | Initial visibility for listed accessibility UIDs. |
| `AllowToggle` | Boolean | `true` | Permit the player-facing HUD toggle. |
| `Icon` | Texture path string | `"\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"` | Friendly icon texture. |
| `Colour` | `[]` or RGBA array of four numbers, 0–1 | `[]` | Empty uses the active colour-vision-aware UI theme. |
| `IconRange` | Number, metres | `300` | Maximum icon range. |
| `NameRange` | Number, metres | `50` | Maximum name range. |
| `RequireLOS` | Boolean | `true` | Hide identifiers blocked by geometry. |
| `IncludeAI` | Boolean | `false` | Include friendly AI. |
| `IconScale` | Number | `0.8` | Base icon drawing size. |
| `TextScale` | Number | `0.035` | Base text drawing size. |
| `DistanceFade` | Boolean | `true` | Fade identifiers with distance. |
| `GroupOnly` | Boolean | `false` | Limit identifiers to the player's group. |
| `ShowIncapacitated` | Boolean | `true` | Show incapacitated friendly units. |
| `ShowIcons` | Boolean | `true` | Permit icons. A player's preference may hide but not enable forbidden icons. |
| `ShowNames` | Boolean | `true` | Permit names. A player's preference may hide but not enable forbidden names. |
| `ShowVehicleCrew` | Boolean | `false` | Show eligible friendly occupants in vehicles. |
| `Font` | Font classname string | `"PuristaBold"` | Name label font. |
| `TextDistanceGrowth` | Number | `0.00025` | Name-size growth with distance. |
| `TextMaximumScale` | Number | `0.05` | Maximum name drawing size. |
| `TextHeadOffset` | Number, metres | `0.30` | Name offset above the animated head. |
| `IconHeadOffset` | Number, metres | `0.75` | Icon offset above the animated head. |
| `OutlineScale` | Number | `1.12` | Text outline size multiplier. |
| `OutlineColour` | RGBA array of four numbers, 0–1 | `[0.03, 0.03, 0.03, 1]` | Text outline colour. |

## Script calls

Normal missions do not need these calls: `initPlayerLocal.sqf` starts the HUD after settings arrive, and the local respawn handler reinstalls it. Use them only for a custom player-facing control. They act on the **local interface client**, not every player on the server.

| Call | Argument type and default | Returns | Example/result |
| --- | --- | --- | --- |
| `Waldo_fnc_WmpHudInit` | None (`[]`) | Boolean: installed/already running, or `false` when unavailable | `[] call Waldo_fnc_WmpHudInit;` installs one local drawing handler. |
| `Waldo_fnc_WmpHudToggle` | Position 0: Boolean desired visibility; omit to invert current state | Boolean: resulting visibility | `[true] call Waldo_fnc_WmpHudToggle;` requests local display; eligibility still applies. |
| `Waldo_fnc_WmpHudStop` | None (`[]`) | Nothing | `[] call Waldo_fnc_WmpHudStop;` removes this client's HUD drawing handler. |
| `Waldo_fnc_WmpHudEligible` | Position 0: player unit Object, default `player` | Boolean: whether that unit has an approved access route | `[player] call Waldo_fnc_WmpHudEligible;` checks the local player's access. |
| `Waldo_fnc_WmpHudPreferences` | None (`[]`) | HashMap: `showIcons`/`showNames` Booleans, `scaleId`/`opacityId` strings, `scale`/`opacity` numbers | `private _prefs = [] call Waldo_fnc_WmpHudPreferences;` reads the validated local choice. |
| `Waldo_fnc_WmpHudSettingsApplyLocal` | Positions 0–4: show icons Boolean (`true`), show names Boolean (`true`), scale string (`"MEDIUM"`), opacity string (`"MEDIUM"`), show confirmation Boolean (`true`) | Boolean: accepted settings | `[true, false, "SMALL", "HIGH", true] call Waldo_fnc_WmpHudSettingsApplyLocal;` saves a name-hidden profile choice. Valid scale: `SMALL`/`MEDIUM`/`LARGE`; opacity: `LOW`/`MEDIUM`/`HIGH`. |

Local choices survive a player-object respawn. They never override the mission's permitted units, ranges, or line-of-sight rule. The built-in ACE/vanilla controls call these helpers; custom scripts need not publish their return values.

## If no labels appear

Check the mission enable flag and the player's eligibility route: allowed UID, configured equipment or explicit allow-everyone setting. The display remains friendly-only and line-of-sight aware. A hidden enemy or an ally behind a wall is not a failed HUD draw.

## See also

- [UI Visual Themes](UI-Visual-Themes)
- [Custom UI Notifications](Custom-UI-Notifications)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
