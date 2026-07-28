/*
 * Author: Waldo
 * Assigns portable crate capacity and current stock to one unit.
 *
 * Arguments: 0: unit <OBJECT>; 1: current crates <NUMBER>; 2: maximum crates <NUMBER>
 * Return Value: Boolean
 */

params [["_unit", objNull, [objNull]], ["_crates", 1, [0]], ["_maximum", 2, [0]]];
if !(isServer) exitWith {[_unit, _crates, _maximum] remoteExecCall ["Waldo_fnc_FieldResupplyAssignCarrier", 2]; true};
if (isNull _unit || {!(_unit isKindOf "CAManBase")}) exitWith {false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull (getAssignedCuratorLogic _caller)}) exitWith {false};
};
_maximum = round (_maximum max 0);
_unit setVariable ["Waldo_FieldResupply_MaxCrates", _maximum, true];
_unit setVariable ["Waldo_FieldResupply_Crates", (round _crates max 0) min _maximum, true];
missionNamespace setVariable ["Waldo_FieldResupply_Enable", true, true];
[[["Waldo_FieldResupply_Enable", true]], false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", owner _unit];
[] remoteExecCall ["Waldo_fnc_FieldResupplyInit", owner _unit];
true
