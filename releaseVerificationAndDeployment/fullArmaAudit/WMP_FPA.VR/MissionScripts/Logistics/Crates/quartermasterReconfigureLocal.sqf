/*
 * Author: WaldoTheWarfighter
 * Purpose: Replaces only WMP-owned quartermaster actions when ZEN changes an object's setup.
 * Locality / Authority: Interface-local action cleanup; server still owns QM availability.
 * Repeat / JIP: Removes tracked paths and actions before repeat-safe reinstall; server keys replay to object.
 * Arguments: target <OBJECT>; bearing <NUMBER> (90); distance <NUMBER> (2);
 *   deployment-controlled <BOOL> (false); allowed issue kinds <ARRAY> (all).
 * Return Value: <BOOL> reconfigured or intentionally skipped on headless clients.
 * Current caller: Waldo_fnc_ZenServiceLogisticsServer.
 * Example: [qmLaptop, 90, 3, false, ["Medical", "Ammo"]]
 *     remoteExecCall ["Waldo_fnc_QuartermasterReconfigureLocal", 0, qmLaptop];
 * Result: The object receives the requested QM issue list and spawn offset on this client.
 */
params [["_target", objNull, [objNull]], ["_bearing", 90, [0]], ["_distance", 2, [0]],
    ["_deploymentControlled", false, [false]], ["_allowedKinds", [], [[]]]];
if (isNull _target) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
if (_allowedKinds isNotEqualTo []) then {
    _target setVariable ["Waldo_QM_AllowedKinds", _allowedKinds];
};
if (hasInterface) then {
    private _paths = +(_target getVariable ["Waldo_QM_ACEActionPaths", []]);
    reverse _paths;
    if (!isNil "ace_interact_menu_fnc_removeActionFromObject") then {
        {[_target, 0, _x] call ace_interact_menu_fnc_removeActionFromObject} forEach _paths;
    };
    {_target removeAction _x} forEach (_target getVariable ["Waldo_QM_VanillaActionIds", []]);
    private _info = _target getVariable ["Waldo_QM_InfoActionId", -1];
    if (_info >= 0) then {_target removeAction _info};
    _target setVariable ["Waldo_QM_ACEActionPaths", nil];
    _target setVariable ["Waldo_QM_VanillaActionIds", nil];
    _target setVariable ["Waldo_QM_InfoActionId", nil];
    _target setVariable ["Waldo_QM_LocalActionsInstalled", nil];
};
[_target, _bearing, _distance, _deploymentControlled] call Waldo_fnc_SetupQuarterMaster
