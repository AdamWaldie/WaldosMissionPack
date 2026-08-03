/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking the normal server-authoritative EMP API.
 * This protects the public ZEN path without changing mission-script uses of Waldo_fnc_EMP.
 *
 * Arguments:
 * 0: position <ARRAY>; 1: radius <NUMBER>; 2: duration <NUMBER>; 3: requester <OBJECT>.
 * Return Value: BOOL - true when the server accepted the pulse.
 * Example: [[100,100,0],150,30,player] remoteExecCall ["Waldo_fnc_ZenEMPServer",2];
 * Current caller: Waldo_fnc_ZenEMP.
 */
params [["_position", [], [[]]], ["_radius", 150, [0]], ["_duration", 30, [0]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {false};
private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {false};
if (count _position < 2) exitWith {false};
[_position, (_radius max 25) min 1000, (_duration max 5) min 300] call Waldo_fnc_EMP;
if (_owner > 2) then {
    ["EMP DETONATED", format ["Pulse applied within %1 metres.", round _radius], "SUCCESS", "EMP_ZEN", 6]
        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};
true
