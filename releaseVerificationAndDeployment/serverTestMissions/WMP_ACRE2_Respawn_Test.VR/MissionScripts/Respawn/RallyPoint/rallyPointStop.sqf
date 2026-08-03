/* Removes rally actions on this client; active rally ownership remains server-side. */
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface) exitWith {false};
{
    if (_x >= 0) then {player removeAction _x};
} forEach (player getVariable ["Waldo_Rally_ActionIds", []]);
{
    if (_x >= 0) then {[player, _x] call BIS_fnc_holdActionRemove};
} forEach (player getVariable ["Waldo_Rally_HoldActionIds", []]);
if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
    {
        [player, 1, _x] call ace_interact_menu_fnc_removeActionFromObject;
    } forEach (player getVariable ["Waldo_Rally_ACEActionPaths", []]);
};
player setVariable ["Waldo_Rally_ActionIds", []];
player setVariable ["Waldo_Rally_HoldActionIds", []];
player setVariable ["Waldo_Rally_ACEActionPaths", []];
player setVariable ["Waldo_Rally_ActionsInstalled", false];
true
