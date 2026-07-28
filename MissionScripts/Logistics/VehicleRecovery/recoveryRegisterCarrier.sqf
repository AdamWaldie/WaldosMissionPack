/* Registers a vehicle able to load and unload recovery packages. */
params [["_carrier", objNull, [objNull]], ["_range", 10, [0]]];
if (isNull _carrier || {!(_carrier isKindOf "AllVehicles")}) exitWith {false};
if (!isServer) exitWith {[_carrier, _range] remoteExecCall ["Waldo_fnc_RecoveryRegisterCarrier", 2]; true};
private _authorized = true;
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    _authorized = !isNull _caller && {!isNull getAssignedCuratorLogic _caller};
};
if (!_authorized) exitWith {false};
_carrier setVariable ["Waldo_Recovery_Carrier", true, true];
_carrier setVariable ["Waldo_Recovery_CarrierRange", _range max 3, true];
[_carrier] remoteExecCall ["Waldo_fnc_RecoverySetupCarrierLocal", 0, _carrier];
true
