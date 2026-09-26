# Mod Config Patch Logger

> **Use this page when:** you need a mod's `CfgPatches` name for an optional-mod guard.

This debug script logs every loaded `CfgPatches` class to the Arma `.rpt` file. A patch name is not necessarily the same as a mod's Workshop title or an object classname. Run the logger in a test session with the mod loaded, then search the current log.

## Quick setup in a test session

Open the debug console and run this with **Local Execute**:

```sqf
[] execVM "MissionScripts\MissionMakerResourceScripts\DEBUG_GetNameOfModConfigPatch.sqf";
```

Open that client's current `.rpt` and search for a likely part of the mod's name. Confirm the class you found against the mod's config before using it as a dependency guard.

## Script call and result

| Input | Type | Default | Effect |
| --- | --- | --- | --- |
| Arguments | None | None | The script reads the local `configFile >> "CfgPatches"` catalogue. |
| Execution | `execVM` call | Manual | Returns an Arma Script handle immediately. |
| Log output | `CfgPatches` class references | Loaded addons | Writes each class reference to the local `.rpt`. The script returns no useful list. |

For example, an optional feature can check a confirmed patch before using that mod's classes:

```sqf
if !(isClass (configFile >> "CfgPatches" >> "acre_main")) exitWith {};
```

This logger does not change WMP settings or publish state to other clients. It runs only when you call it. Do not add it to normal mission startup because it writes a long list to the log.

## If the patch is missing

Check that the mod was loaded in the same session whose `.rpt` you searched. If the logger ran on a client, inspect that client's log. Do not assume the server loaded the same addons without checking its own mod list.

## See also

- [Mission Diagnostics](Mission-Diagnostics)
- [Mission-Maker Resource Scripts](Mission-Maker-Resource-Scripts)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)
