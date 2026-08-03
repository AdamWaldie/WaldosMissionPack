/*
 * Author: WaldoTheWarfighter
 * Runs the single server-owned monitor for grounded and virtually carried recovery packages.
 *
 * Grounded packages are matched to workshop key and radius. Virtual packages are excluded from
 * workshop scans while carried; their last carrier position is retained, and packages spill into
 * a checked clear footprint if the carrier is destroyed. An obstructed spill remains virtual and
 * is retried rather than overlapping another object.
 *
 * Arguments: None.
 *
 * Return Value:
 * Boolean - true after the monitor is deliberately stopped; false when already running/non-server.
 *
 * Example:
 * if (isServer) then {[] spawn Waldo_fnc_RecoveryMonitorServer;};
 *
 * Current caller: Waldo_fnc_RecoveryRegisterWorkshop starts the repeat-safe monitor.
 */
if (!isServer || {remoteExecutedOwner > 0} || {missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]}) exitWith {false};
missionNamespace setVariable ["Waldo_Recovery_MonitorRunning", true];
while {missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]} do {
    private _workshops = (missionNamespace getVariable ["Waldo_Recovery_Workshops", []]) select {!isNull _x};
    private _packages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x};
    {
        private _package = _x;
        private _virtualCarrier = _package getVariable ["Waldo_Recovery_VirtualCarrier", objNull];
        private _isVirtualLoaded = _package getVariable ["Waldo_Recovery_IsVirtualLoaded", false];
        if (_isVirtualLoaded) then {
        if (!isNull _virtualCarrier) then {
            _package setVariable ["Waldo_Recovery_VirtualLastPosition", getPosATL _virtualCarrier];
            if (!alive _virtualCarrier && {!(_package getVariable ["Waldo_Recovery_Transition", false])}) then {
                private _position = [_virtualCarrier, _package, [_virtualCarrier, _package]] call Waldo_fnc_RecoveryResolveUnloadPosition;
                if !(_position isEqualTo []) then {
                    private _manifest = (_virtualCarrier getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x && {_x != _package}};
                    _virtualCarrier setVariable ["Waldo_Recovery_VirtualPackages", _manifest, true];
                    _package setVariable ["Waldo_Recovery_VirtualCarrier", objNull, true];
                    _package setVariable ["Waldo_Recovery_IsVirtualLoaded", false, true];
                    _package setPosATL _position;
                    _package setVectorUp surfaceNormal _position;
                    _package hideObjectGlobal false;
                    _package allowDamage true;
                    _package enableSimulationGlobal true;
                };
            };
        } else {
            private _lastPosition = _package getVariable ["Waldo_Recovery_VirtualLastPosition", []];
            if !(_lastPosition isEqualTo []) then {
                private _position = _lastPosition findEmptyPosition [0, missionNamespace getVariable ["Waldo_Recovery_VirtualUnloadSearchRange", 20], typeOf _package];
                if !(_position isEqualTo []) then {
                    _position set [2, 0];
                    _package setVariable ["Waldo_Recovery_IsVirtualLoaded", false, true];
                    _package setPosATL _position;
                    _package setVectorUp surfaceNormal _position;
                    _package hideObjectGlobal false;
                    _package allowDamage true;
                    _package enableSimulationGlobal true;
                };
            };
        };
        } else {
        if (!(_package getVariable ["Waldo_Recovery_Transition", false]) && {isNull isVehicleCargo _package} && {(getPosATL _package select 2) < 1.5} && {abs speed _package < 1}) then {
            private _key = _package getVariable ["Waldo_Recovery_WorkshopKey", "MAIN"];
            private _index = _workshops findIf {
                (_x getVariable ["Waldo_Recovery_WorkshopKey", ""]) == _key
                && {_package distance2D _x <= (_x getVariable ["Waldo_Recovery_Radius", 50])}
            };
            if (_index >= 0) then {[_package, _workshops select _index] call Waldo_fnc_RecoveryRestoreServer};
        };
        };
    } forEach _packages;
    sleep ((missionNamespace getVariable ["Waldo_Recovery_ScanInterval", 3]) max 1);
};
true
