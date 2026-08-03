/*
 * Author: WaldoTheWarfighter
 * Performs one local emergency exit while preserving momentum and bounded damage protection.
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: vehicle <OBJECT>
 * 2: destroyed <BOOLEAN>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [player, vehicle player, false] spawn Waldo_fnc_EmergencyDismountExecute;
 */

params ["_unit", "_vehicle", ["_destroyed", false]];
if (remoteExecutedOwner > 0) exitWith {};
if !(hasInterface && {local _unit}) exitWith {};
if (isNull _vehicle || {_vehicle == _unit}) exitWith {};

private _profile = _unit getVariable ["Waldo_EmergencyDismount_ActiveProfile", createHashMap];
private _setting = {
    params ["_name", "_fallback"];
    _profile getOrDefault [_name, missionNamespace getVariable [format ["Waldo_EmergencyDismount_%1", _name], _fallback]]
};

_unit setVariable ["Waldo_EmergencyDismount_Next", diag_tickTime + (["Cooldown", 8] call _setting)];
private _velocity = velocity _vehicle;
private _damageWasAllowed = isDamageAllowed _unit;
if (["ProtectDuringExit", true] call _setting) then {
    _unit allowDamage false;
};

unassignVehicle _unit;
if (["UseEject", false] call _setting) then {
    _unit action ["Eject", _vehicle];
} else {
    moveOut _unit;
};
sleep 0.1;
if (_vehicle isKindOf "LandVehicle") then {
    private _clearRadius = ["ClearPositionRadius", 6] call _setting;
    private _searchCentre = _vehicle getPos [_clearRadius, random 360];
    private _clearPosition = _searchCentre findEmptyPosition [0, 3, "CAManBase"];
    if (count _clearPosition > 0) then {_unit setPosATL _clearPosition};
};
if (["PreserveVelocity", true] call _setting) then {
    _unit setVelocity _velocity;
};

private _push = ["UpwardVelocity", 2.5] call _setting;
_unit setVelocity [velocity _unit select 0, velocity _unit select 1, (velocity _unit select 2) max _push];

private _timeout = diag_tickTime + ((["ProtectionSeconds", 4] call _setting) max 0.5);
waitUntil {
    sleep 0.05;
    isTouchingGround _unit || {underwater _unit} || {diag_tickTime >= _timeout}
};
if (_damageWasAllowed) then {_unit allowDamage true};
if (["RecoverUnconscious", false] call _setting) then {
    _unit setUnconscious false;
};
private _damageOnExit = ["DamageOnExit", 0] call _setting;
if (_damageOnExit > 0) then {_unit setDamage ((damage _unit + _damageOnExit) min 1)};
_unit setVariable ["Waldo_EmergencyDismount_ActiveProfile", nil];
["EMERGENCY DISMOUNT", if (_destroyed) then {"Extracted from a destroyed vehicle."} else {"Extracted from an overturned vehicle."}, "WARNING", "EMERGENCY_DISMOUNT"] call Waldo_fnc_FeatureNotifyLocal;
