/*
 * Author: WaldoTheWarfighter
 * Purpose: Takes a lossless direct-cargo snapshot, including loaded weapons, magazine rounds and backpacks.
 * Locality / Authority: Read-only on any machine; server uses the snapshot as transaction truth.
 * Repeat / JIP: Stateless; [] means the container could not be represented safely.
 * Arguments: container <OBJECT>. Return Value: [items, weapons, magazines, backpacks] <ARRAY> or [].
 * Current callers: supply-transfer ACE children and server request/verification.
 * Example: private _contents = [crate] call Waldo_fnc_SupplyTransfersSnapshot;
 */
params [["_container", objNull, [objNull]]];
if (isNull _container) exitWith {[]};
private _rawItems = getItemCargo _container;
private _items = [];
{
    _items pushBack [_x, (_rawItems select 1) select _forEachIndex];
} forEach (_rawItems select 0);
private _backpacks = [];
private _objects = everyBackpack _container;
private _backpackCargo = getBackpackCargo _container;
private _expected = 0;
{_expected = _expected + _x} forEach (_backpackCargo select 1);
if (_expected isNotEqualTo count _objects) exitWith {[]};
private _valid = true;
{
    private _nested = [_x] call Waldo_fnc_SupplyTransfersSnapshot;
    if (_nested isEqualTo []) then {_valid = false} else {
        _backpacks pushBack [typeOf _x, _nested];
    };
} forEach _objects;
if (!_valid) exitWith {[]};
[_items, weaponsItemsCargo _container, magazinesAmmoCargo _container, _backpacks]
