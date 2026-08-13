/*
 * Author: WaldoTheWarfighter
 * Rebinds SafeStart and ENDEX protection after Arma replaces the local player on respawn. Player
 * and vehicle event-handler IDs are client-global but refer to one concrete object; retaining them
 * would make the new body look protected while the actual Fired handler remained on the corpse.
 * This function removes handlers from their original objects, clears inherited per-body protection
 * claims, then reapplies whichever authoritative protection states are still active.
 *
 * Locality and authority: interface-client local. It does not change authoritative SafeStart or
 * ENDEX state. It is repeat-safe for one replacement and creates no public/JIP state.
 *
 * Arguments:
 * 0: new player unit <OBJECT>
 * 1: old player body <OBJECT> (default objNull)
 *
 * Return Value:
 * BOOL - true after local protection was rebound; false for a non-local/non-player call.
 *
 * Current callers: Waldo_fnc_RespawnRestoreLoadout after inventory restoration.
 *
 * Example:
 * [_newUnit, _oldUnit] call Waldo_fnc_ProtectionRespawnLocal;
 */

params [
    ["_newUnit", objNull, [objNull]],
    ["_oldUnit", objNull, [objNull]]
];
if (!hasInterface || {isNull _newUnit} || {!local _newUnit} || {!(_newUnit isEqualTo player)}) exitWith {false};

if !(isNil "Waldo_SafeStart_FiredEH") then {
    if (!isNull _oldUnit) then {_oldUnit removeEventHandler ["Fired", Waldo_SafeStart_FiredEH]};
    Waldo_SafeStart_FiredEH = nil;
};
if !(isNil "Waldo_SafeStart_VehFiredEH") then {
    if !(isNil "Waldo_SafeStart_Vehicle") then {
        if (!isNull Waldo_SafeStart_Vehicle) then {Waldo_SafeStart_Vehicle removeEventHandler ["Fired", Waldo_SafeStart_VehFiredEH]};
    };
    Waldo_SafeStart_VehFiredEH = nil;
};
Waldo_SafeStart_Vehicle = nil;
Waldo_SafeStart_VehicleDamageWasAllowed = nil;
Waldo_SafeStart_PlayerDamageWasAllowed = nil;

if !(isNil "Waldo_PreventWeaponsFireEventHandler") then {
    if (!isNull _oldUnit) then {_oldUnit removeEventHandler ["Fired", Waldo_PreventWeaponsFireEventHandler]};
    Waldo_PreventWeaponsFireEventHandler = nil;
};
if !(isNil "Waldo_PreventVehicleFireEventHandler") then {
    private _oldEndexVehicle = if (isNull _oldUnit) then {objNull} else {_oldUnit getVariable ["Waldo_PreventVehicleFire", objNull]};
    if (!isNull _oldEndexVehicle) then {_oldEndexVehicle removeEventHandler ["Fired", Waldo_PreventVehicleFireEventHandler]};
    Waldo_PreventVehicleFireEventHandler = nil;
};

// Arma/CBA may copy object variables to the replacement. These claims describe the old body and
// must never suppress acquiring the new body's safety or damage baseline.
_newUnit setVariable ["Waldo_WMPProtection_SafetyClaims", []];
_newUnit setVariable ["Waldo_WMPProtection_OwnedSafety", []];
_newUnit setVariable ["Waldo_WMPProtection_DamageBaseline", nil];
_newUnit setVariable ["Waldo_PreventVehicleFire", nil];

if (missionNamespace getVariable ["Waldo_SafeStart_Active", false]) then {
    [true, "RESPAWN"] call Waldo_fnc_SafeStartApply;
};
if (missionNamespace getVariable ["Waldo_ENDEX_Active", false]) then {
    [true] call Waldo_fnc_ENDEX;
};
true
