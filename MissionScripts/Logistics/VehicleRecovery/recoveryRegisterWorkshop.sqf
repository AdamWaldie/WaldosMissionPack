/* Registers a server-owned recovery workshop. [object, key, radius, serviced side] */
params [["_workshop", objNull, [objNull]], ["_key", "MAIN", [""]], ["_radius", 50, [0]], ["_side", sideUnknown, [sideUnknown]]];
if (isNull _workshop) exitWith {false};
if (!isServer) exitWith {[_workshop, _key, _radius, _side] remoteExecCall ["Waldo_fnc_RecoveryRegisterWorkshop", 2]; true};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
_key = [_key, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"] call BIS_fnc_filterString;
if (_key == "") exitWith {false};
_workshop setVariable ["Waldo_Recovery_Workshop", true, true];
_workshop setVariable ["Waldo_Recovery_WorkshopKey", toUpperANSI _key, true];
_workshop setVariable ["Waldo_Recovery_Radius", _radius max 5, true];
_workshop setVariable ["Waldo_Recovery_Side", _side, true];
private _workshops = (missionNamespace getVariable ["Waldo_Recovery_Workshops", []]) select {!isNull _x};
_workshops pushBackUnique _workshop;
missionNamespace setVariable ["Waldo_Recovery_Workshops", _workshops];
if !(missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]) then {[] spawn Waldo_fnc_RecoveryMonitorServer};
true
