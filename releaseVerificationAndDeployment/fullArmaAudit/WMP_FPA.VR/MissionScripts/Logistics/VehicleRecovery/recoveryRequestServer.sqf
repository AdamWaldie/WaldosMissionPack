/* Server-authoritative package/load/unload operations. */
params [["_actor", objNull, [objNull]], ["_operation", "", [""]], ["_target", objNull, [objNull]]];
if (!isServer) exitWith {_this remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2]; false};
if (isNull _actor || {isNull _target} || {!alive _actor}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner != owner _actor}) exitWith {false};
if (_actor distance _target > 7 || {vehicle _actor != _actor} || {abs speed _target >= 1}) exitWith {
    ["Remain on foot beside a stationary vehicle.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
};
_operation = toUpperANSI _operation;
if (_operation == "PACK") exitWith {
    if !(_target getVariable ["Waldo_Recovery_Registered", false]) exitWith {false};
    private _config = _target getVariable ["Waldo_Recovery_Config", ["MAIN", 0.55, true, false, "B_Slingload_01_Cargo_F", true, 1]];
    _config params ["_key", "_minimumDamage", "_allowDestroyed", "_requireEngineer", "_packageClass", "_preserveCargo"];
    private _workshops = (missionNamespace getVariable ["Waldo_Recovery_Workshops", []]) select {!isNull _x && {(_x getVariable ["Waldo_Recovery_WorkshopKey", ""]) == _key}};
    if (_workshops isEqualTo []) exitWith {["No active recovery workshop accepts this vehicle key.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false};
    private _serviced = _workshops findIf {
        private _workshopSide = _x getVariable ["Waldo_Recovery_Side", sideUnknown];
        _workshopSide == sideUnknown || {_workshopSide getFriend side group _actor >= 0.6}
    };
    if (_serviced < 0) exitWith {["Your side is not serviced by this vehicle's recovery workshop.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false};
    if (count crew _target > 0 || {(alive _target && {damage _target < _minimumDamage})} || {!alive _target && {!_allowDestroyed}}) exitWith {
        ["The vehicle is occupied or does not meet its recovery threshold.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
    };
    if (_requireEngineer && {!(_actor getUnitTrait "engineer")}) exitWith {
        ["An engineer is required to package this vehicle.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
    };
    private _cargo = if (_preserveCargo) then {[getWeaponCargo _target, getMagazineCargo _target, getItemCargo _target, getBackpackCargo _target]} else {[]};
    private _customVariableNames = +(missionNamespace getVariable ["Waldo_Recovery_DefaultCustomVariables", []]);
    {_customVariableNames pushBackUnique _x} forEach (_target getVariable ["Waldo_Recovery_CustomVariables", []]);
    private _customVariables = _customVariableNames apply {[_x, _target getVariable _x]};
    private _bounds = boundingBoxReal _target;
    private _minimum = _bounds param [0, [-1, -1, -1]];
    private _maximum = _bounds param [1, [1, 1, 1]];
    private _footprint = (((_maximum select 0) - (_minimum select 0)) max ((_maximum select 1) - (_minimum select 1))) / 2;
    private _state = [
        typeOf _target, getObjectTextures _target, getPylonMagazines _target, _cargo, _config,
        _target getVariable ["Waldo_Recovery_Carrier", false], _target getVariable ["Waldo_Recovery_CarrierRange", 10],
        _target, alive _target, vehicleVarName _target, [vectorDir _target, vectorUp _target],
        simulationEnabled _target, isDamageAllowed _target,
        _target getVariable ["Waldo_Recovery_OnRestored", {}], _customVariables, _footprint
    ];
    private _position = getPosATL _target;
    private _direction = getDir _target;
    _target enableSimulationGlobal false;
    _target allowDamage false;
    _target hideObjectGlobal true;
    _target setPosASL [0, 0, -1000];
    private _package = createVehicle [_packageClass, _position, [], 0, "CAN_COLLIDE"];
    if (isNull _package) exitWith {
        _target setPosATL _position;
        _target setDir _direction;
        _target hideObjectGlobal false;
        _target allowDamage (_state select 12);
        _target enableSimulationGlobal (_state select 11);
        ["The recovery package could not be created; the vehicle was left in place.", "ERROR"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
        false
    };
    _package setDir _direction;
    _package setVariable ["Waldo_Recovery_Package", true, true];
    _package setVariable ["Waldo_Recovery_State", _state];
    _package setVariable ["Waldo_Recovery_WorkshopKey", _key, true];
    private _packages = (missionNamespace getVariable ["Waldo_Recovery_Packages", []]) select {!isNull _x};
    _packages pushBack _package;
    missionNamespace setVariable ["Waldo_Recovery_Packages", _packages];
    ["Vehicle packaged. Deliver it to its recovery workshop.", "SUCCESS"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
    true
};
if !(_target getVariable ["Waldo_Recovery_Carrier", false]) exitWith {false};
if (_operation == "LOAD") exitWith {
    if !((getVehicleCargo _target) isEqualTo []) exitWith {false};
    private _range = _target getVariable ["Waldo_Recovery_CarrierRange", 10];
    private _near = (nearestObjects [_target, ["AllVehicles"], _range, true]) select {
        _x getVariable ["Waldo_Recovery_Package", false]
        && {isNull isVehicleCargo _x}
        && {!(_x getVariable ["Waldo_Recovery_Transition", false])}
    };
    if (_near isEqualTo []) exitWith {["No recovery package is within loading range.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false};
    private _package = _near select 0;
    _package setVariable ["Waldo_Recovery_Transition", true];
    private _actorOwner = owner _actor;
    [_target, _package] remoteExecCall ["Waldo_fnc_RecoverySetCargoLocal", owner _target];
    [_target, _package, _actorOwner] spawn {
        params ["_carrier", "_package", "_actorOwner"];
        sleep 0.75;
        private _loaded = !isNull _package && {isVehicleCargo _package == _carrier};
        if (!isNull _package) then {_package setVariable ["Waldo_Recovery_Transition", false]};
        [if (_loaded) then {"Recovery package loaded."} else {"The carrier could not accept that package."}, ["WARNING", "SUCCESS"] select _loaded]
            remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", _actorOwner];
    };
    true
};
if (_operation == "UNLOAD") exitWith {
    if ((getVehicleCargo _target) isEqualTo []) exitWith {false};
    private _cargo = (getVehicleCargo _target) select 0;
    _cargo setVariable ["Waldo_Recovery_Transition", true];
    private _actorOwner = owner _actor;
    [_target, objNull] remoteExecCall ["Waldo_fnc_RecoverySetCargoLocal", owner _target];
    [_cargo, _actorOwner] spawn {
        params ["_cargo", "_actorOwner"];
        sleep 0.75;
        private _unloaded = isNull _cargo || {isNull isVehicleCargo _cargo};
        if (!isNull _cargo) then {_cargo setVariable ["Waldo_Recovery_Transition", false]};
        [if (_unloaded) then {"Recovery package unloaded."} else {"The package could not be unloaded here."}, ["WARNING", "SUCCESS"] select _unloaded]
            remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", _actorOwner];
    };
    true
};
false
