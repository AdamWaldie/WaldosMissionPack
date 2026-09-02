# WMP HUD

Local, friendly-only 3D identification overlay with two independent ways to
qualify: configured equipment (high-tech campaign) or an always-on
accessibility allowlist by Steam UID. Does not change side relations, AI
knowledge, or network state — pure client-local presentation.

## Config (`MissionConfig\interfaceConfig.sqf` — player local)

```sqf
["Waldo_WmpHud_Enable", true],                 // installs the local HUD framework
["Waldo_WmpHud_SystemName", "WMP HUD"],        // player-facing system name, e.g. "Auspex"
["Waldo_WmpHud_AccessibilityUIDs", ["76561198094931408"]], // Steam UIDs that always qualify
["Waldo_WmpHud_ExcludedUIDs", []],             // Steam UIDs denied through every route
["Waldo_WmpHud_AllowEveryone", false],         // true bypasses both UID and equipment checks
["Waldo_WmpHud_Headgear", []],                 // CfgWeapons headgear classnames granting access
["Waldo_WmpHud_Facewear", ["G_Goggles_VR"]],   // CfgGlasses facewear classnames granting access
["Waldo_WmpHud_NVGs", [ /* NVG/HMD classnames */ ]],
["Waldo_WmpHud_DefaultVisible", true],
["Waldo_WmpHud_AccessibilityDefaultVisible", true],
["Waldo_WmpHud_AllowToggle", true],            // shows the rapid Enable/Disable WMP HUD self-actions
["Waldo_WmpHud_Icon", "\a3\ui_f\data\igui\cfg\actions\getincommander_ca.paa"],
["Waldo_WmpHud_Colour", []],                   // [] follows colour-vision-aware theme; else RGBA 0-1
["Waldo_WmpHud_IconRange", 300], ["Waldo_WmpHud_NameRange", 50],
["Waldo_WmpHud_RequireLOS", true], ["Waldo_WmpHud_IncludeAI", false],
["Waldo_WmpHud_GroupOnly", false], ["Waldo_WmpHud_ShowVehicleCrew", false],
["Waldo_WmpHud_ShowIncapacitated", true], ["Waldo_WmpHud_ShowIcons", true], ["Waldo_WmpHud_ShowNames", true]
// ADVANCED TUNING: IconScale/TextScale, DistanceFade, Font, TextDistanceGrowth, TextMaximumScale,
// TextHeadOffset, IconHeadOffset, OutlineScale, OutlineColour — leave alone for a normal mission.
```

## Beginner setup

1. Leave `Waldo_WmpHud_Enable` as `true`.
2. Put accessibility users' Steam UID strings in `Waldo_WmpHud_AccessibilityUIDs`
   — the first player always qualifies without equipment.
3. For a high-tech campaign, add equipment classnames to `Headgear`,
   `Facewear` or `NVGs` — any player wearing the configured item qualifies.
4. Leave `AllowEveryone` false unless every player should qualify without
   equipment.
5. Adjust `IconRange`/`NameRange`/LOS/AI inclusion only if the defaults
   don't suit the mission.

## Player access

Eligible users get **ACE Self Interact > WMP Options > WMP HUD**: rapid,
conditionally-shown **Enable WMP HUD** / **Disable WMP HUD** actions plus a
**WMP HUD Settings** custom screen (blue vanilla `addAction` fallback
without ACE). Colour-vision and reduced-motion controls live separately
under **WMP Options > Accessibility Settings** — see `ui-themes.md`.

### WMP HUD Settings (player-local, restriction-only)

The settings screen can:
- hide otherwise-permitted icons and/or names
- choose **Small / Medium / Large** icon+text scale
- choose **Low / Medium / High** opacity

It can only ever make the HUD show **less** than mission configuration
permits — it cannot expand `IconRange`/`NameRange`, reveal units the
mission excludes, bypass LOS/equipment/UID gates, or override
`AllowToggle`. It also explains in-place when the feature is mission-
disabled or this player's eligibility isn't met. The choice survives
respawn (`Waldo_fnc_WmpHudPreferences` / `Waldo_fnc_WmpHudSettingsApplyLocal`).

## Script API (local, no ZEN module)

```sqf
[] call Waldo_fnc_WmpHudInit;
[] call Waldo_fnc_WmpHudToggle;
[] call Waldo_fnc_WmpHudStop;
[unit] call Waldo_fnc_WmpHudEligible;
[] call Waldo_fnc_WmpHudPreferences;            // reads this player's stored HUD content/scale/opacity prefs
```

WMP HUD intentionally has **no ZEN module** — eligibility/presentation is
mission/player configuration, not Zeus world state.

## Gotchas

- Names and icons have separate ranges and use local LOS checks, so a name
  can be gated off before the icon disappears (or vice versa) depending on
  `IconRange`/`NameRange`.
- `Waldo_WmpHud_ExcludedUIDs` overrides both the UID and equipment routes —
  useful for a specific player who should never see it regardless of gear.
- Does not reveal enemies or bypass Arma knowledge — friendly-only, always.
