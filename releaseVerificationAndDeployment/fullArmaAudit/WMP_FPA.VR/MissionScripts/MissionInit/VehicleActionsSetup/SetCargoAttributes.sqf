/*
 * Author: WaldoTheWarfighter
 * Purpose: Configures ACE cargo size/space and WMP's drag/carry choice.
 * Locality / Authority: Server selects the object and calls ACE's public global
 *   size, space, drag and carry setters after mission startup.
 * Repeat / JIP: Pending edits coalesce per object. Unchanged choices send no
 *   event; ACE's global setters replay live state to joining clients.
 *
 * Arguments:
 * 0: Object        <OBJECT>
 * 1: Cargo Space   <NUMBER> (nil to keep default value)
 * 2: Cargo Size    <NUMBER> (nil to keep default value)
 * 3: Draggable     <BOOLEAN> (Default: true for portable objects, false for vehicles/static weapons)
 * 4: Carryable     <BOOLEAN> (Default: true for portable objects, false for vehicles/static weapons)
 * 5: Ignore drag weight limit <BOOLEAN> (Default: false)
 * 6: Ignore carry weight limit <BOOLEAN> (Default: false)
 * Return Value: <BOOLEAN> true when the settings were submitted.
 * Current callers: logistics crates, quartermaster, MHQ, ZEN cargo settings,
 *   field resupply and audit fixtures.
 *
 * Example:
 * [myTruck] call Waldo_fnc_SetCargoAttributes;
 * [myTruck, 30, -1] call Waldo_fnc_SetCargoAttributes;
 * [myCrate, -1, 2] call Waldo_fnc_SetCargoAttributes;
 * [myCrate, -1, 2, true, false] call Waldo_fnc_SetCargoAttributes;
 * [myCrate, nil, nil, true, false] call Waldo_fnc_SetCargoAttributes;
 * Result: Submitted settings are coalesced for that object and applied through ACE's global
 * handling/cargo setters, then replayed by ACE to joining clients.
 *
 */

params [
    ["_vehicle", objNull, [objNull]],
    ["_space", nil, [0, nil]],
    ["_size", nil, [0, nil]],
    ["_draggable", true, [true]],
    ["_carryable", true, [true]],
    ["_ignoreDragWeight", false, [true]],
    ["_ignoreCarryWeight", false, [true]]
];

if (!isServer || {isRemoteExecuted}) exitWith {false};
if (isNull _vehicle) exitWith {false};
if !(isClass (configFile >> "CfgPatches" >> "ace_cargo")
    && {isClass (configFile >> "CfgPatches" >> "ace_dragging")}) exitWith {false};
private _portable = !(_vehicle isKindOf "LandVehicle" || {_vehicle isKindOf "Air"}
    || {_vehicle isKindOf "Ship"} || {_vehicle isKindOf "StaticWeapon"});
if (count _this <= 3) then {_draggable = _portable};
if (count _this <= 4) then {_carryable = _portable};
private _pending = +(_vehicle getVariable ["Waldo_CargoAttributes_Pending", [false, 0, false, 0, false]]);
if (!isNil "_space") then {
    _vehicle setVariable ["Waldo_CargoAttributes_TotalSpace", _space, true];
    _pending set [0, true];
    _pending set [1, _space];
};
if (!isNil "_size") then {
    _vehicle setVariable ["Waldo_CargoAttributes_DesiredSize", _size];
    _pending set [2, true];
    _pending set [3, _size];
};
private _choice = [_draggable, _carryable, _ignoreDragWeight, _ignoreCarryWeight];
if !(_choice isEqualTo (_vehicle getVariable ["Waldo_CargoAttributes_Choice", []])) then {
    _vehicle setVariable ["Waldo_CargoAttributes_Choice", _choice, true];
    _pending set [4, true];
};
_vehicle setVariable ["Waldo_CargoAttributes_Pending", _pending];
if !((_pending select 0) || {(_pending select 2)} || {(_pending select 4)}) exitWith {true};

private _apply = {
    params ["_object"];
    if (isNull _object) exitWith {};
    private _work = _object getVariable ["Waldo_CargoAttributes_Pending", [false, 0, false, 0, false]];
    if (_work select 0) then {[_object, _work select 1] call ace_cargo_fnc_setSpace};
    if (_work select 2) then {[_object, _work select 3] call ace_cargo_fnc_setSize};
    if (_work select 4) then {
        (_object getVariable ["Waldo_CargoAttributes_Choice", [false, false, false, false]])
            params ["_drag", "_carry", "_ignoreDrag", "_ignoreCarry"];
        [_object, _drag, _object getVariable ["ace_dragging_dragPosition", [0, 1.5, 0]],
            _object getVariable ["ace_dragging_dragDirection", 0], _ignoreDrag, true]
            call ace_dragging_fnc_setDraggable;
        [_object, _carry, _object getVariable ["ace_dragging_carryPosition", [0, 1, 1]],
            _object getVariable ["ace_dragging_carryDirection", 0], _ignoreCarry, true]
            call ace_dragging_fnc_setCarryable;
    };
    _object setVariable ["Waldo_CargoAttributes_Pending", [false, 0, false, 0, false]];
};
private _ready = time > 0 && {!isNil "ace_cargo_fnc_setSpace"}
    && {!isNil "ace_cargo_fnc_setSize"} && {!isNil "ace_dragging_fnc_setDraggable"}
    && {!isNil "ace_dragging_fnc_setCarryable"};
if (_ready) then {
    [_vehicle] call _apply;
} else {
    private _queue = +(missionNamespace getVariable ["Waldo_CargoAttributes_PendingObjects", []]);
    _queue pushBackUnique _vehicle;
    missionNamespace setVariable ["Waldo_CargoAttributes_PendingObjects", _queue];
    if !(missionNamespace getVariable ["Waldo_CargoAttributes_QueueRunning", false]) then {
        missionNamespace setVariable ["Waldo_CargoAttributes_QueueRunning", true];
        [_apply] spawn {
            params ["_apply"];
            waitUntil {
                sleep 0.25;
                time > 0 && {!isNil "ace_cargo_fnc_setSpace"}
                    && {!isNil "ace_cargo_fnc_setSize"}
                    && {!isNil "ace_dragging_fnc_setDraggable"}
                    && {!isNil "ace_dragging_fnc_setCarryable"}
            };
            private _queue = missionNamespace getVariable ["Waldo_CargoAttributes_PendingObjects", []];
            missionNamespace setVariable ["Waldo_CargoAttributes_PendingObjects", []];
            {[_x] call _apply} forEach (_queue select {!isNull _x});
            missionNamespace setVariable ["Waldo_CargoAttributes_QueueRunning", false];
        };
    };
};
true
