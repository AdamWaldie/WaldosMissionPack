/*
 * Author: WaldoTheWarfighter
 * Purpose: Configures ACE cargo capacity and publishes drag/carry actions to every client.
 * Locality / Authority: Call on the server. ACE's global drag/carry API replays to JIP.
 * Repeat / JIP: Repeating updates the same ACE object settings; ACE handles JIP action replay.
 *
 * Arguments:
 * 0: Vehicle       <OBJECT>
 * 1: Cargo Space   <NUMBER> (nil to keep default value)
 * 2: Cargo Size    <NUMBER> (nil to keep default value)
 * 3: Draggable     <BOOLEAN> (Default; true)
 * 4: Carryable     <BOOLEAN> (Default; true)
 * Return Value: <BOOLEAN> true when the settings were submitted.
 * Current callers: logistics crates, quartermaster, MHQ, field resupply and audit fixtures.
 *
 * Example:
 * [myTruck] call Waldo_fnc_SetCargoAttributes;
 * [myTruck, 30, -1] call Waldo_fnc_SetCargoAttributes;
 * [myCrate, -1, 2] call Waldo_fnc_SetCargoAttributes;
 * [myCrate, -1, 2, true, false] call Waldo_fnc_SetCargoAttributes;
 * [myCrate, nil, nil, true, false] call Waldo_fnc_SetCargoAttributes;
 *
 * 
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_space", nil, [0, nil]],
    ["_size", nil, [0, nil]],
    ["_draggable", true, [true]],
    ["_carryable", true, [true]]
];

if !(isServer) exitWith {false};
if (isNull _vehicle) exitWith {false};

if (!isNil{_space}) then {
    [_vehicle, _space] call ace_cargo_fnc_setSpace;
};
if (!isNil{_size}) then {
    [_vehicle, _size] call ace_cargo_fnc_setSize;
};

// ACE's sixth parameter is the global/JIP switch. Its default is LOCAL, even when
// called on a dedicated server; without this clients never receive Carry/Drag.
// The global path serialises all arguments, so supply concrete pose values too.
[_vehicle, _draggable, _vehicle getVariable ["ace_dragging_dragPosition", [0, 1.5, 0]],
    _vehicle getVariable ["ace_dragging_dragDirection", 0], false, true]
    call ace_dragging_fnc_setDraggable;
[_vehicle, _carryable, _vehicle getVariable ["ace_dragging_carryPosition", [0, 1, 1]],
    _vehicle getVariable ["ace_dragging_carryDirection", 0], false, true]
    call ace_dragging_fnc_setCarryable;
_vehicle setVariable ["Waldo_CargoAttributes_CarryablePublished", _carryable];
true
