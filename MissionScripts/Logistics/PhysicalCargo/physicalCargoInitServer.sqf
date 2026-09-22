/*
 * Author: WaldoTheWarfighter
 * Purpose: Installs one ACE Cargo listener and monitor to release obsolete physical mounts.
 * Locality / Authority: Server only; it owns mount cleanup and publishes the revised registry.
 * Repeat / JIP: Idempotent installation; public mount state and explicit requests support JIP.
 *
 * Arguments: None.
 * Return Value: BOOLEAN - true when installed or already present.
 * Current caller: initServer.sqf after feature configuration.
 * Example: [] call Waldo_fnc_PhysicalCargoInitServer;
 */
if (!isServer) exitWith {false};
if (missionNamespace getVariable ["Waldo_PhysicalCargo_ServerInstalled", false]) exitWith {true};
if (isNil "CBA_fnc_addEventHandler") exitWith {false};
private _id = ["ace_cargoLoaded", {
    params ["_cargo"];
    if (_cargo isEqualType objNull && {!isNull _cargo}) then {
        [_cargo] call Waldo_fnc_PhysicalCargoClearServer;
    };
}] call CBA_fnc_addEventHandler;
missionNamespace setVariable ["Waldo_PhysicalCargo_CargoLoadedEH", _id];
missionNamespace setVariable ["Waldo_PhysicalCargo_ServerInstalled", true];
private _monitor = [{
    private _mounts = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
    {
        _x params ["_cargo", "_vehicle"];
        if (isNull _cargo) then {
            [_cargo, _vehicle, false] call Waldo_fnc_PhysicalCargoSeatsServer;
        } else {if (isNull _vehicle || {!alive _vehicle}) then {
            [_cargo] call Waldo_fnc_PhysicalCargoClearServer;
        }};
    } forEach _mounts;
    private _current = +(missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []]);
    private _clean = _current select {!isNull (_x select 0)};
    if (count _clean isNotEqualTo count _current) then {
        missionNamespace setVariable ["Waldo_PhysicalCargo_Mounts", _clean, true];
    };
}, 3] call CBA_fnc_addPerFrameHandler;
missionNamespace setVariable ["Waldo_PhysicalCargo_MonitorPFH", _monitor];
true
