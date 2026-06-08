_Associated Files: initPlayerLocal.sqf_

# General Setup

Loadout saving is automatically active as soon as the pack is merged into your mission folder — no additional configuration is needed for the basic feature.

By default, upon dying, players respawn with the loadout they had at the start of the mission (or whatever they last saved manually via a starter crate). ACRE2 radio channels are re-assigned automatically on respawn as part of this system.

> **Important:** `respawnOnStart = -1` in `description.ext` is required for this system to work correctly. Do not change this value.

---

# Respawn Options

## Default: Respawn With Starting Loadout

No setup required. Players automatically respawn with the loadout saved at mission start.

## Option: Respawn With Death Loadout

To have players respawn with whatever they were carrying when they died (rather than their starting kit), uncomment the noted section in `initPlayerLocal.sqf`:

![IPL](https://i.imgur.com/L1JxR3C.png)

```sqf
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;
```

## Option: Save Loadout on ACE Arsenal Close

To automatically save the player's respawn loadout whenever they close the ACE Arsenal (so players respawn with their chosen kit), uncomment the section immediately above the death loadout code in `initPlayerLocal.sqf`:

```sqf
["ace_arsenal_displayClosed", {
    [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
}] call CBA_fnc_addEventHandler;
```

Both options can be enabled simultaneously — the death-loadout save will overwrite the arsenal save on each death.

---

# Manual Loadout Saving

Players can also save their loadout manually. The simplest method is via any **Starter Crate** — these already include a save action by default. See [Logistics System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Logistics-System,-Starter-Crates-And-Quartermaster) for starter crate setup.

For custom implementations:

**ACE interaction on an object:**

```sqf
this addAction ["<t color='#00FF00'>Save Respawn Loadout</t>", Waldo_fnc_SaveLoadout];
```

**Direct function call (from a trigger or script):**

```sqf
[] call Waldo_fnc_SaveLoadout;
```

---

# Potential Conflicts

**ACE Respawn** conflicts with this feature. Disable it in server and mission addon settings:

`Settings → Addon Settings → ACE Respawn → disable`

If ACE Respawn is active, loadout restoration on respawn will not function correctly.
