/* One server loop services all packages; registration starts it on demand. */
if (!isServer || {remoteExecutedOwner > 0} || {missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]}) exitWith {false};
missionNamespace setVariable ["Waldo_Recovery_MonitorRunning", true];
while {missionNamespace getVariable ["Waldo_Recovery_MonitorRunning", false]} do {
    private _workshops = (missionNamespace getVariable ["Waldo_Recovery_Workshops", []]) select {!isNull _x};
    private _packages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x};
    {
        private _package = _x;
        if (!(_package getVariable ["Waldo_Recovery_Transition", false]) && {isNull isVehicleCargo _package} && {(getPosATL _package select 2) < 1.5} && {abs speed _package < 1}) then {
            private _key = _package getVariable ["Waldo_Recovery_WorkshopKey", "MAIN"];
            private _index = _workshops findIf {
                (_x getVariable ["Waldo_Recovery_WorkshopKey", ""]) == _key
                && {_package distance2D _x <= (_x getVariable ["Waldo_Recovery_Radius", 50])}
            };
            if (_index >= 0) then {[_package, _workshops select _index] call Waldo_fnc_RecoveryRestoreServer};
        };
    } forEach _packages;
    sleep (missionNamespace getVariable ["Waldo_Recovery_ScanInterval", 3] max 1);
};
true
