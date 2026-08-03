# ACRE2 Communications Configuration

> **Use this page when:** you need deterministic squad radio assignments, named carried-radio displays, CEOI or side-isolated ACRE2 presets.

Associated files: `acreConfig.sqf` and `MissionScripts\MissionInit\ACRE2\acre2*.sqf`.

All active ACRE2 authoring now lives in the root `acreConfig.sqf`. Do not add ACRE waits or mutable defaults to `init.sqf`. Pre-init registers the ACRE side-preset labels on every machine, `initServer.sqf` publishes one versioned side/group plan for JIP, and `initPlayerLocal.sqf` applies the local player's carried radios.

## Nets and groups

Each side entry contains a stable side key, its existing ACRE preset, logical nets, and groups:

```sqf
["WEST", "default3", [
    ["PLT1", "PLATOON 1", []],
    ["AIRGND", "AIR-GND", []]
], [
    ["VIKING-1-1", ["PLT1", "AIRGND"], [1, 1]]
]]
```

Groups reference net keys, not channel numbers. Reordering a displayed name does not silently change a group's intent. The final group field is an optional explicit PRC-343 `[block, channel]`; both values must be 1–16. Strict validation rejects invalid values, duplicate side/group/net keys, unknown net references, and explicit collisions.

## Named displays and presets

WMP modifies only each radio's official display-name text field on existing side presets: `label` for PRC-148, `description` for PRC-152 and `name` for PRC-117F. It never copies a preset, rewrites TX/RX frequencies, or changes a preset after unique radio IDs exist. Names are upper-case, restricted to safe display characters, and capped at 12 characters. The write is read back and the frequency fields are compared before and after.

Physical named displays are enabled for PRC-148, PRC-152 and PRC-117F. Other supported radios retain their normal channel or frequency display; their net names remain visible in the CEOI. If registration fails, WMP reports diagnostics and leaves radio frequencies unchanged.

## Carried radio profiles

- PRC-343: block/channel assignment.
- PRC-148, PRC-152, PRC-117F, BF-888S and SEM52SL: numbered-channel assignment.
- PRC-77 and SEM70: recognised as manual-frequency radios and left unchanged unless a mission supplies a safe explicit integration.
- Unknown and third-party radios: untouched unless a mission adds a profile.
- Vehicle racks: deliberately outside this lifecycle because mounted ownership and initialisation differ from carried radios.

Radio priority is configured independently. Unsupported radios never consume a logical net assignment. Automatic application occurs on join, JIP and normal respawn; arbitrary group-change retuning is disabled by default so captured and newly picked-up radios are not unexpectedly rewritten.

## Diagnostics and fallback

The audit mission's core console can show the compiled plan and actual unique radio list, force a plan/Babel/CEOI reapply, and save a filtered respawn loadout. The previous implementation is frozen as `Waldo_fnc_ACRE2Init_Legacy` and related `_Legacy` helpers. Nothing calls it automatically.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
