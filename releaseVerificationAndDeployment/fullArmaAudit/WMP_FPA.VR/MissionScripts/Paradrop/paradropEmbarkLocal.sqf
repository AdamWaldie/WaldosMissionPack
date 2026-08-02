/*
 * Author: WaldoTheWarfighter
 * Moves one local player into a named paradrop aircraft's cargo compartment after a server-
 * authorised ZEN embark request. It never claims pilot, turret or command seats and reports a
 * stale aircraft or exhausted cargo capacity through the WMP notification UI.
 *
 * Arguments:
 * 0: player unit <OBJECT>
 * 1: aircraft <OBJECT>
 * 2: operation name <STRING>
 *
 * Return Value:
 * Boolean - true when the player entered aircraft cargo.
 *
 * Called by:
 * Waldo_fnc_ParadropEmbark on the selected player's owning client.
 *
 * Example:
 * [player, _aircraft, "DZ ALPHA"] call Waldo_fnc_ParadropEmbarkLocal;
 */

params [
    ["_unit", objNull, [objNull]],
    ["_aircraft", objNull, [objNull]],
    ["_operationName", "PARADROP", [""]]
];

if (!hasInterface || {isNull _unit} || {!local _unit}) exitWith {false};
if (isNull _aircraft || {!alive _aircraft}) exitWith {
    ["PARADROP EMBARK", format ["%1 aircraft is no longer available.", _operationName], "ERROR", "PARADROP_EMBARK", 7]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};
if ((_aircraft emptyPositions "cargo") <= 0) exitWith {
    ["PARADROP EMBARK", format ["%1 has no free cargo seats.", _operationName], "WARNING", "PARADROP_EMBARK", 7]
        call Waldo_fnc_FeatureNotifyLocal;
    false
};

_unit moveInCargo _aircraft;
private _boarded = vehicle _unit isEqualTo _aircraft && {_aircraft getCargoIndex _unit >= 0};
if (_boarded) then {
    ["PARADROP EMBARK", format ["Boarded %1 as cargo.", _operationName], "SUCCESS", "PARADROP_EMBARK", 5]
        call Waldo_fnc_FeatureNotifyLocal;
} else {
    ["PARADROP EMBARK", format ["Could not board %1; its cargo state changed.", _operationName], "WARNING", "PARADROP_EMBARK", 7]
        call Waldo_fnc_FeatureNotifyLocal;
};
_boarded
