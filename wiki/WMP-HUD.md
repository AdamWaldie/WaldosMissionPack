# WMP HUD

> **Use this page when:** you want friendly 3D identification for a high-technology campaign, or an accessibility aid for specific players in any campaign.

WMP HUD is one local, friendly-only identification system with two independent ways to qualify. A mission can grant it through configured headgear, facewear or NVGs/HMDs. Separately, Steam UIDs in `Waldo_WmpHud_AccessibilityUIDs` always qualify without equipment. An entry in `Waldo_WmpHud_ExcludedUIDs` overrides both routes.

The HUD does not change side relations, AI knowledge or network state. Each client draws only eligible friendly units using local line-of-sight checks. Names and icons have separate ranges, follow animated head positions, respect incapacitation/vehicle policy, and use the active WMP theme plus the player's colour-vision profile.

## Beginner setup

Open `MissionConfig\interfaceConfig.sqf` and find the **WMP HUD** block.

1. Leave `Waldo_WmpHud_Enable` as `true` to install the framework.
2. Put accessibility users' Steam UID strings in `Waldo_WmpHud_AccessibilityUIDs`.
3. For a high-tech campaign, add the equipment classnames that should grant access to `Headgear`, `Facewear` or `NVGs`.
4. Leave `AllowEveryone` false unless every player should qualify without equipment.
5. Adjust `IconRange`, `NameRange`, LOS and AI inclusion only if the defaults do not suit the mission.

```sqf
["Waldo_WmpHud_AccessibilityUIDs", ["76561198094931408"]]
["Waldo_WmpHud_Facewear", ["G_Goggles_VR"]]
["Waldo_WmpHud_NVGs", ["NVGogglesB_blk_F"]]
```

The first player always qualifies. Any other player qualifies while wearing the VR goggles or configured NVGs. The values are loaded player-locally by WMP; do not publish them from `init.sqf`.

Open **ACE Self Interact > WMP Options > WMP HUD**. Eligible users receive separate rapid **Enable WMP HUD** and **Disable WMP HUD** actions plus **WMP HUD Settings**. The custom settings screen can hide otherwise permitted icons or names and choose Small/Medium/Large scale and Low/Medium/High opacity. It also explains when the mission has disabled the feature or its eligibility requirement is not met. These controls cannot expand icon/name range, reveal disallowed units, bypass LOS, equipment gates or UID exclusions, or override `AllowToggle`. The local visibility choice survives player-object respawn. Without ACE, equivalent blue addActions are installed.

Cross-interface colour-vision and reduced-motion controls live at **ACE Self Interact > WMP Options > Accessibility Settings**. WMP HUD intentionally has no ZEN module because eligibility and information restrictions are mission authority, not player or Zeus presentation state.

Script APIs are local: `Waldo_fnc_WmpHudInit`, `Waldo_fnc_WmpHudToggle`, `Waldo_fnc_WmpHudStop`, `Waldo_fnc_WmpHudEligible`, `Waldo_fnc_WmpHudPreferences` and `Waldo_fnc_WmpHudSettingsApplyLocal`.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
