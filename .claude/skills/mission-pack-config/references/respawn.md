# Respawn options

`respawnOnStart = -1` in `description.ext` must **never** be changed — the
loadout-saving system depends on it. If a user asks to "fix respawn" or
change respawn behaviour, this specific setting is off-limits regardless of
what else changes.

**Default behaviour** is the mission-start baseline plus whatever a player last saved through the
manual **Loadout Save Point** ACE/vanilla action (`Waldo_fnc_SaveLoadout`,
`Zen_loadoutSaveSetup.sqf`) — nothing is captured automatically on death unless opted in below.

**"Respawn with what you died with"** is off by default, toggled in `MissionConfig\logisticsConfig.sqf`:

```sqf
["Waldo_Respawn_SaveOnDeath", false],   // true = capture loadout+radio on every death
```

When `true`, a `"CAManBase"`/`"Killed"` handler in `initPlayerLocal.sqf` captures both loadout and
radio on every death and restores it on respawn:

```sqf
if (missionNamespace getVariable ["Waldo_Respawn_SaveOnDeath", false]) then {
    ["CAManBase", "Killed", {
        params ["_unit"];
        if (_unit == player) then {
            [false] call Waldo_fnc_SaveLoadout;
        };
    }] call CBA_fnc_addClassEventHandler;
};
```

A second, alternative behaviour is commented out by default in `initPlayerLocal.sqf` — uncomment
instead if the mission wants "whatever kit was last built in Arsenal" rather than "whatever was
carried at death":

```sqf
// Save loadout when closing ACE Arsenal (respawn with chosen kit, no battlefield-looted-gear
// carryover since it only captures on a deliberate Arsenal close, not on every death):
["ace_arsenal_displayClosed", {
    [false] call Waldo_fnc_SaveLoadout;
}] call CBA_fnc_addEventHandler;
```

`Waldo_fnc_SaveLoadout` captures loadout and supported ACRE2 radio state together as one snapshot
(`Waldo_Player_Inventory`/`Waldo_Player_RadioState`) — either handler fixes both at once. These are
mutually meaningful choices: enabling both means whichever event happened most recently wins, since
both write the same state — ask which behaviour the mission wants if only one should apply, rather than
enabling both by default. These two snippets are genuinely still `initPlayerLocal.sqf` code, not
`MissionConfig` data — they're event-handler registrations, not pure settings, so they weren't
migrated.

## Related: Squad Rally Points (temporary respawn positions)

A separate, newer system — group-owned *temporary* respawn points a squad
leader deploys/packs mid-mission, distinct from the permanent starting
respawn behaviour above. Configured via `Waldo_Rally_*` in
`MissionConfig\missionSystemsConfig.sqf`. See
`references/vehicle-recovery-rallies.md`.
