/* Repositions an equipment control using the local 40 x 25 grid. */
disableSerialization;
params [
    ["_display", displayNull, [displayNull]],
    ["_control", controlNull, [controlNull]],
    ["_rect", [0, 0, 1, 1], [[]]],
    ["_commit", 0, [0]]
];
if (isNull _display || {isNull _control}) exitWith {false};
_control ctrlSetPosition ([_display, _rect] call Waldo_fnc_MiniGameEquipmentRect);
_control ctrlCommit _commit;
_control setVariable ["Waldo_MG_UI_GridRect", +_rect];
true
