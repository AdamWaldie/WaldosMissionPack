/* Opens a deterministic developer-facing gallery for all field-equipment procedures. */
if (!hasInterface) exitWith {false};
private _entries = [
    ["wirecut", [5, 0], []], ["minesweeper", [5, 5, 0], []],
    ["keypad", [4, 6, 0], []], ["lockpick", [3, 1.4, 0.16, 0], []],
    ["circuit", [4, 3, 0], []], ["repair", [4, 2, 3, 0], []],
    ["radiotune", [3, 0.05, 1, 0], []], ["pressure", [3, 1, 2, 0], []],
    ["sequence", [4, 4, 0.6, 0], []]
];
[objNull, _entries] call Waldo_fnc_MiniGameEquipmentPicker
