/*
 * Author: WaldoTheWarfighter
 * Purpose: Applies WMP's standard ACE handling to an object a WMP feature sets up: ACE Drag and
 *   Carry regardless of weight, and optionally an ACE cargo size. This is the same handling
 *   quartermaster crates receive, shared so every WMP entry point treats objects alike.
 * Locality / Authority: Server only. Call from a server context that is not a remote-executed
 *   request (Waldo_fnc_SetCargoAttributes rejects those); WMP callers defer through
 *   CBA_fnc_execNextFrame first.
 * Repeat / JIP: Repeat-safe; ACE's global setters replay the state to joining clients.
 *
 * People and vehicles are left unchanged, except static weapons, which do receive the handling.
 *
 * Arguments:
 * 0: object <OBJECT>
 * 1: ACE cargo size <NUMBER> (optional, default nil = leave the object's size unchanged)
 *
 * Return Value: <BOOL> - true when the handling was submitted.
 * Current callers: supply/medical crate helpers and the Waldos Logistics ZEN handler.
 * Example: [myCrate, 1] call Waldo_fnc_LogisticsApplyAceHandling;
 */
params [["_object", objNull, [objNull]], ["_size", nil, [0, nil]]];
if (!isServer || {isNull _object} || {_object isKindOf "CAManBase"}) exitWith {false};
if (!(_object isKindOf "StaticWeapon")
    && {_object isKindOf "LandVehicle" || {_object isKindOf "Air"} || {_object isKindOf "Ship"}}) exitWith {false};
if (isNil "_size") then {
    [_object, nil, nil, true, true, true, true] call Waldo_fnc_SetCargoAttributes
} else {
    [_object, nil, _size, true, true, true, true] call Waldo_fnc_SetCargoAttributes
}
