/*
 * Author: WaldoTheWarfighter
 * Performs the one-shot server transition that spills a virtually carried recovery package into
 * a checked clear position. Network variables broadcast once per successful transition. A failed
 * placement clears the guard so the low-frequency monitor may safely retry later.
 *
 * Arguments:
 * 0: package <OBJECT>
 * 1: carrier <OBJECT> (default objNull)
 *
 * Return Value: BOOL - true only when the package was materialised successfully.
 *
 * Example: [_package, _carrier] call Waldo_fnc_RecoverySpillVirtualPackageServer;
 * Current caller: Waldo_fnc_RecoveryMonitorServer on carrier loss or destruction.
 */
params [['_package', objNull, [objNull]], ['_carrier', objNull, [objNull]]];
if (!isServer || {remoteExecutedOwner > 0} || {isNull _package} || {!(_package getVariable ['Waldo_Recovery_IsVirtualLoaded', false])}) exitWith {false};
if (_package getVariable ['Waldo_Recovery_Transition', false]) exitWith {false};
_package setVariable ['Waldo_Recovery_Transition', true];
private _position = [];
if (!isNull _carrier) then {
    _position = [_carrier, _package, [_carrier, _package]] call Waldo_fnc_RecoveryResolveUnloadPosition;
} else {
    private _lastPosition = _package getVariable ['Waldo_Recovery_VirtualLastPosition', []];
    if !(_lastPosition isEqualTo []) then {
        _position = _lastPosition findEmptyPosition [0, missionNamespace getVariable ['Waldo_Recovery_VirtualUnloadSearchRange', 20], typeOf _package];
        if !(_position isEqualTo []) then {_position set [2, 0]};
    };
};
if (_position isEqualTo []) exitWith {_package setVariable ['Waldo_Recovery_Transition', false]; false};
if (!isNull _carrier) then {
    private _manifest = (_carrier getVariable ['Waldo_Recovery_VirtualPackages', []]) select {!isNull _x && {_x != _package}};
    _carrier setVariable ['Waldo_Recovery_VirtualPackages', _manifest, true];
};
_package setVariable ['Waldo_Recovery_VirtualCarrier', objNull, true];
_package setVariable ['Waldo_Recovery_IsVirtualLoaded', false, true];
_package setPosATL _position;
_package setVectorUp surfaceNormal _position;
_package hideObjectGlobal false;
_package allowDamage true;
_package enableSimulationGlobal true;
_package setVariable ['Waldo_Recovery_Transition', false];
true
