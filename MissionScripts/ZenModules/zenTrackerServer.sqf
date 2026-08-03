/*
 * Author: WaldoTheWarfighter
 * Authenticates a ZEN curator request before invoking the normal server tracker registry API.
 * The target, active state and JIP-visible registry remain server-owned.
 *
 * Arguments:
 * 0: target <OBJECT>; 1: tracking side <STRING>; 2: label <STRING>;
 * 3: active <BOOL>; 4: requester <OBJECT>.
 * Return Value: BOOL - true when a tracker was registered.
 * Example: [truck1,"WEST","LEAD",true,player] remoteExecCall ["Waldo_fnc_ZenTrackerServer",2];
 * Current caller: Waldo_fnc_ZenTracker.
 */
params [["_target", objNull, [objNull]], ["_side", "ALL", [""]], ["_label", "", [""]], ["_active", true, [true]], ["_requester", objNull, [objNull]]];
if (!isServer) exitWith {false};
private _owner = remoteExecutedOwner;
if (_owner > 0 && {isNull _requester || {owner _requester != _owner} || {isNull getAssignedCuratorLogic _requester}}) exitWith {false};
if (isNull _target) exitWith {false};
private _id = [_target, _side, _label, _active] call Waldo_fnc_Tracker;
private _ok = _id >= 0;
if (_owner > 2) then {
    ["SIGNAL TRACKER", if (_ok) then {format ["Tracker %1 registered on the server.", _id]} else {"Tracker registration failed."}, if (_ok) then {"SUCCESS"} else {"ERROR"}, "TRACKER_ZEN", 6]
        remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", _owner];
};
_ok
