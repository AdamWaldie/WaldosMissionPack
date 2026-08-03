/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request and changes one side's ACE Fortify budget on the server.
 * The dialog remains local to Zeus; the shared ACE budget is never mutated on a dedicated client.
 *
 * Arguments:
 * 0: side <SIDE> - side whose Fortify budget is changed.
 * 1: budget delta <NUMBER> - signed amount to add or remove.
 * 2: requester <OBJECT> - curator player submitting the dialog.
 *
 * Return Value: BOOL - true when the server accepted the change.
 * Example: [west, 100, player] remoteExecCall ["Waldo_fnc_ZenFortifyBudgetServer", 2];
 * Current caller: Waldo_fnc_FortifyBudgetModule.
 */
params [["_side", sideUnknown, [sideUnknown]], ["_delta", 0, [0]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {false};
private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {
    diag_log format ["[WMP ZEN] Fortify request rejected owner=%1", _owner];
    false
};
if !(_side in [west, east, independent, civilian]) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_fortify")) exitWith {false};
[_side, _delta, true] call ace_fortify_fnc_updateBudget;
diag_log format ["[WMP ZEN] Fortify budget adjusted side=%1 delta=%2 owner=%3", _side, _delta, _owner];
if (_owner > 2) then {
    ["FORTIFY BUDGET", format ["%1 budget changed by %2.", _side, _delta], "SUCCESS", "FORTIFY_ZEN", 6]
        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};
true
