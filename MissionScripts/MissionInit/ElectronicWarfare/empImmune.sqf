/*
 * Author: Waldo
 * Marks a unit or vehicle as immune to EMP (Waldo_fnc_EMP). Occupants of an immune vehicle inherit
 * the immunity automatically. Server-authoritative and broadcast, so the flag holds for JIP players.
 * Set it from an object's init field or a script for command vehicles, mission-critical assets, etc.
 *
 * Arguments:
 * 0: Object <OBJECT> - the unit or vehicle to make EMP-immune
 * 1: Immune <BOOL> - true to grant immunity, false to revoke it (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [this] call Waldo_fnc_EMPImmune;          // in a vehicle's init field
 * [commandVehicle, true] call Waldo_fnc_EMPImmune;
 */

params [["_object", objNull], ["_immune", true]];

if (isNull _object) exitWith {};

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_EMPImmune", 2];
};

_object setVariable ["Waldo_EMP_Immune", _immune, true];
