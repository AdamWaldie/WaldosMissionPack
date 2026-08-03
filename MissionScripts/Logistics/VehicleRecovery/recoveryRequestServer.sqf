/*
 * Author: WaldoTheWarfighter
 * Validates and executes package, physical-cargo and virtual-cargo recovery operations.
 *
 * The requesting player's owner, distance, on-foot state and carrier motion are checked before
 * every mutation. Automatic carriers use Arma vehicle-in-vehicle cargo only when the package fits
 * the actual configured bay, otherwise the server hides and simulation-disables the package in a
 * synchronized virtual manifest. Virtual packages restore directly at a matching workshop or are
 * materialized only at a complete clear footprint beside the carrier.
 *
 * Arguments:
 * 0: actor <OBJECT>
 * 1: operation <STRING> - "PACK", "LOAD" or "UNLOAD"
 * 2: recoverable vehicle, carrier or package target <OBJECT>
 *
 * Return Value:
 * Boolean - true when the operation was accepted; asynchronous physical cargo may still fail.
 *
 * Example:
 * [player, "LOAD", recoveryCarrier] remoteExecCall ["Waldo_fnc_RecoveryRequestServer", 2];
 *
 * Current callers: local recovery vehicle and carrier actions.
 */
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
    private _loadedRecovery = (getVehicleCargo _target) select {_x getVariable ["Waldo_Recovery_Package", false]};
    private _virtualRecovery = (_target getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x};
    if (_target getVariable ["Waldo_Recovery_Carrier", false] && {count _loadedRecovery + count _virtualRecovery > 0}) exitWith {
        ["Unload all recovery packages before packaging this carrier.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
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
        _target getVariable ["Waldo_Recovery_OnRestored", {}], _customVariables, _footprint,
        _target getVariable ["Waldo_Recovery_CarrierMode", "AUTO"],
        _target getVariable ["Waldo_Recovery_CarrierCapacity", 1]
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
    private _manifest = (_target getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x};
    _target setVariable ["Waldo_Recovery_VirtualPackages", _manifest, true];
    private _capacity = (_target getVariable ["Waldo_Recovery_CarrierCapacity", 1]) max 1;
    if (count (getVehicleCargo _target) + count _manifest >= _capacity) exitWith {
        ["This recovery carrier is at package capacity.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
    };
    private _range = _target getVariable ["Waldo_Recovery_CarrierRange", 10];
    private _near = (nearestObjects [_target, ["AllVehicles"], _range, true]) select {
        _x getVariable ["Waldo_Recovery_Package", false]
        && {isNull isVehicleCargo _x}
        && {!(_x getVariable ["Waldo_Recovery_Transition", false])}
    };
    if (_near isEqualTo []) exitWith {["No recovery package is within loading range.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false};
    private _package = _near select 0;
    private _mode = _target getVariable ["Waldo_Recovery_CarrierMode", "AUTO"];
    private _canPhysical = vehicleCargoEnabled _target && {(_target canVehicleCargo _package) param [0, false]};
    if (_mode == "PHYSICAL" && {!_canPhysical}) exitWith {
        ["That package does not fit this vehicle's configured physical cargo bay.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
    };
    private _usePhysical = _mode == "PHYSICAL" || {_mode == "AUTO" && {_canPhysical}};
    if !(_usePhysical) exitWith {
        _package setVariable ["Waldo_Recovery_Transition", true];
        _package setVariable ["Waldo_Recovery_VirtualCarrier", _target, true];
        _package setVariable ["Waldo_Recovery_IsVirtualLoaded", true, true];
        _package setVariable ["Waldo_Recovery_VirtualLastPosition", getPosATL _target];
        _package enableSimulationGlobal false;
        _package allowDamage false;
        _package hideObjectGlobal true;
        _package setPosASL [0, 0, -1100 - (count _manifest * 10)];
        _manifest pushBack _package;
        _target setVariable ["Waldo_Recovery_VirtualPackages", _manifest, true];
        _package setVariable ["Waldo_Recovery_Transition", false];
        [format ["Recovery package loaded virtually (%1 of %2).", count _manifest, _capacity], "SUCCESS"]
            remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
        true
    };
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
    private _manifest = (_target getVariable ["Waldo_Recovery_VirtualPackages", []]) select {!isNull _x};
    if !(_manifest isEqualTo []) exitWith {
        private _package = _manifest deleteAt ((count _manifest) - 1);
        _package setVariable ["Waldo_Recovery_Transition", true];
        private _key = _package getVariable ["Waldo_Recovery_WorkshopKey", "MAIN"];
        private _workshops = (missionNamespace getVariable ["Waldo_Recovery_Workshops", []]) select {
            !isNull _x
            && {(_x getVariable ["Waldo_Recovery_WorkshopKey", ""]) == _key}
            && {_target distance2D _x <= (_x getVariable ["Waldo_Recovery_Radius", 50])}
        };
        if !(_workshops isEqualTo []) then {
            private _state = _package getVariable ["Waldo_Recovery_State", []];
            private _class = _state param [0, "", [""]];
            private _footprint = _state param [15, 3, [0]];
            private _restorePosition = [_workshops select 0, _class, _footprint, [_package, _state param [7, objNull]]] call Waldo_fnc_RecoveryResolveRestorePosition;
            if (_restorePosition isEqualTo []) exitWith {
                _manifest pushBack _package;
                _package setVariable ["Waldo_Recovery_Transition", false];
                ["The workshop restore area is obstructed; the package remains loaded.", "WARNING"]
                    remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
                false
            };
            _target setVariable ["Waldo_Recovery_VirtualPackages", _manifest, true];
            _package setVariable ["Waldo_Recovery_VirtualCarrier", objNull, true];
            _package setVariable ["Waldo_Recovery_IsVirtualLoaded", false, true];
            _package setPosATL getPosATL (_workshops select 0);
            _package setVariable ["Waldo_Recovery_Transition", false];
            ["Recovery package delivered; workshop restoration is queued.", "SUCCESS"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
            true
        } else {
            private _position = [_target, _package, [_target, _package]] call Waldo_fnc_RecoveryResolveUnloadPosition;
            if (_position isEqualTo []) then {
                _manifest pushBack _package;
                _package setVariable ["Waldo_Recovery_Transition", false];
                ["No clear package-sized unloading area was found beside the carrier.", "WARNING"]
                    remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
                false
            } else {
                _target setVariable ["Waldo_Recovery_VirtualPackages", _manifest, true];
                _package setVariable ["Waldo_Recovery_VirtualCarrier", objNull, true];
                _package setVariable ["Waldo_Recovery_IsVirtualLoaded", false, true];
                _package setDir getDir _target;
                _package setPosATL _position;
                _package setVectorUp surfaceNormal _position;
                _package hideObjectGlobal false;
                _package allowDamage true;
                _package enableSimulationGlobal true;
                _package setVariable ["Waldo_Recovery_Transition", false];
                [format ["Recovery package unloaded (%1 remaining).", count _manifest], "SUCCESS"]
                    remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor];
                true
            }
        }
    };
    private _physicalRecovery = (getVehicleCargo _target) select {_x getVariable ["Waldo_Recovery_Package", false]};
    if (_physicalRecovery isEqualTo []) exitWith {
        ["No recovery package is loaded on this carrier.", "WARNING"] remoteExecCall ["Waldo_fnc_RecoveryNotifyLocal", owner _actor]; false
    };
    private _cargo = _physicalRecovery select 0;
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
