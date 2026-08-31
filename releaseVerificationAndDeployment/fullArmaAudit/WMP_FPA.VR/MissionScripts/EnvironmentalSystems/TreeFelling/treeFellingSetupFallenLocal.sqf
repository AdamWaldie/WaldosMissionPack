/*
 * Author: WaldoTheWarfighter
 * Applies the complete ACE drag/carry policy for one fallen tree replacement on the executing
 * machine. A single object-keyed remote call is used because Arma keeps one replaceable JIP entry
 * per object key; splitting drag and carry into two calls would make the latter replace the former.
 *
 * Locality/authority: local effect on every machine; the server supplies the authoritative object
 * and carry eligibility. No state is published by this function.
 * Repeat/JIP behaviour: repeat-safe. The caller attaches its one replay entry to the fallen object,
 * so Arma removes it automatically when that object is deleted.
 *
 * Arguments:
 * 0: fallen object <OBJECT>
 * 1: carryable <BOOLEAN> (default false)
 * Return Value: BOOLEAN - true when ACE policy was applied; false when unavailable.
 * Current caller: Waldo_fnc_TreeFellingProcess.
 * Example: [_fallenTree, true] remoteExecCall ["Waldo_fnc_TreeFellingSetupFallenLocal", 0, _fallenTree];
 */

params [
    ["_fallenObject", objNull, [objNull]],
    ["_carryable", false, [false]]
];
if (isNull _fallenObject || {isNil "ace_dragging_fnc_setDraggable"}) exitWith {false};

[_fallenObject, true, [0, 2, 0], 90] call ace_dragging_fnc_setDraggable;
if (_carryable && {!(isNil "ace_dragging_fnc_setCarryable")}) then {
    [_fallenObject, true, [0, 1, 0], 0] call ace_dragging_fnc_setCarryable;
};
true
