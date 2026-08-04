# Respawn options

`respawnOnStart = -1` in `description.ext` must **never** be changed — the
loadout-saving system depends on it. If a user asks to "fix respawn" or
change respawn behaviour, this specific setting is off-limits regardless of
what else changes.

Two optional behaviours in `initPlayerLocal.sqf` are commented out by
default — uncomment whichever the mission wants:

```sqf
// Save loadout when closing ACE Arsenal (respawn with chosen kit):
["ace_arsenal_displayClosed", {
    [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
}] call CBA_fnc_addEventHandler;

// Respawn with what you died with (instead of starting kit):
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;
```

These are mutually meaningful choices, not a checklist to enable both
blindly: "save on arsenal close" means players keep whatever kit they last
built in Arsenal; "respawn with what you died with" means the death-moment
inventory becomes the new spawn kit. Ask which behaviour the mission wants
before uncommenting — enabling both can produce confusing double-saves
depending on order of events.
