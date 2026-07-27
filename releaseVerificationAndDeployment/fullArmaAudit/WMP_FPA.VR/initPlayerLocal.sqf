// Generated full-pack audit entry point. Keep the real pack lifecycle intact.
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditPreInitPlayerLocal.sqf";

/*
 * Author: WaldoTheWarfighter
 * initPlayerLocal.sqf - runs per-player on each join and respawn. Saves the starting loadout, adds
 * the "Flip Vehicle" action, and re-applies the saved loadout and action on respawn via a CBA event
 * handler. Two optional behaviours (save-on-arsenal-close, respawn-with-what-you-died-with) are
 * included commented out below.
 *
 * Arguments:
 * None (engine entry point; runs locally for each player)
 *
 * Return Value:
 * Nothing
 */

//Post-Init Setup of saved Loadout (Measure taken to help prevent Naked/unarmed People)


// Save Inventory on mission start
[player, [missionNamespace, "Waldo_Player_Inventory"], [], false] call BIS_fnc_saveInventory;

player addAction [
    "Flip Vehicle",
    "MissionScripts\Logistics\LogiHelpers\flipAction.sqf",
    [],
    0,
    false,
    true,
    "",
    "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
];

/* //This doesnt seem to work after the 2022 December patch.
["CAManBase", "InitPost", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Waldo_Player_Inventory"], [], false] call BIS_fnc_saveInventory; // Apparently just doesnt work anymore
        //missionNamespace setVariable ["Waldo_Player_Inventory",getUnitLoadout _unit,false]
        _unit addAction [
        "Flip Vehicle",
        "MissionScripts\Logistics\LogiHelpers\flipAction.sqf",
        [],
        0,
        false,
        true,
        "",
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
    };
}] call CBA_fnc_addClassEventHandler;*/


//Respawn Reapplication Of Loadout Segment
["CAManBase", "Respawn", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_loadInventory;
        //_unit setUnitLoadout (missionNamespace getVariable "Waldo_Player_Inventory");
        // Respawn Text
        [] spawn Waldo_fnc_RespawnText;
        // Re-apply safestart if it is still active (respawn resets damage/handlers/position)
        if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
            [true] call Waldo_fnc_SafeStartApply;
        };
        [] call Waldo_fnc_SetupUiCleanupAction;
        player addAction [
        "Flip Vehicle",
        "MissionScripts\Logistics\LogiHelpers\flipAction.sqf",
        [],
        0,
        false,
        true,
        "",
        "_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
    ];
    };
}] call CBA_fnc_addClassEventHandler;

// Apply safestart to this client if a freeze is already active when they join (JIP).
if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    [true] call Waldo_fnc_SafeStartApply;
};

// Shared, JIP-safe renderer for mission-maker custom 3D world markers.
[] call Waldo_fnc_Init3DMarkers;

// Local emergency cleanup for WMP-owned UI. ACE self-interaction is preferred;
// vanilla addAction is used only when ACE interaction is unavailable.
[] call Waldo_fnc_SetupUiCleanupAction;

// WMP overlays must never survive into Arma's death or debriefing displays.
// The cleanup function only hides controls owned by this pack.
addMissionEventHandler ["EntityKilled", {
    params ["_killed"];
    if (_killed isEqualTo player) then {[] call Waldo_fnc_CleanupTransientUi;};
}];
addMissionEventHandler ["Ended", {[] call Waldo_fnc_CleanupTransientUi;}];

/*
=====================ACE 3 SAVE LOADOUT ON ARSENAL CLOSE====================================
This allows you to save whatever loadout the player selected after they close the arsenal
so that they may respawn with it.  Particularly helpful when you just want the player to
select a loadout and then forget about having to use the arsenal after respawning.
*/

// ["ace_arsenal_displayClosed", {
//     [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
// }] call CBA_fnc_addEventHandler;

/*
=====================RESPAWN WITH LOADOUT ON DEATH====================================

UNCOMMENT THE BELOW IF YOU WANT PEOPLE TO RESPAWN WITH WHAT THEY DIED WITH!


*/

/*
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;


*/

call compile preprocessFileLineNumbers "auditInitPlayerLocal.sqf";
