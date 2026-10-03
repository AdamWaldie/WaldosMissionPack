/*
 * Author: WaldoTheWarfighter
 * Removes this client's rally self-actions when the rally feature is disabled at runtime.
 * Locality and authority: Interface-client only; rejects remote senders other than the server.
 * Server-side rally objects and respawn handles are cleared by a separate server function.
 * Repeat/JIP: Safe to call again after actions are removed. Runtime control replays current
 * feature state to joining clients; this function leaves no active action paths behind.
 * Arguments: None.
 * Return Value: <BOOL> - true when local action cleanup completed; false without an interface.
 * Current caller: Waldo_fnc_FeatureRuntimeApply during ZEN runtime disable.
 * Example: [] call Waldo_fnc_RallyPointStop;
 * Result: The local player has no WMP squad-rally interaction actions.
 */
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
