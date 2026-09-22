/*
 * Author: WaldoTheWarfighter
 * Purpose: Rebuilds one registered crate from a lossless direct-cargo snapshot.
 * Locality / Authority: Server-only transaction helper. Never call for a player's equipment.
 * Repeat / JIP: Rebuilds the supplied state exactly or returns false for rollback/diagnostics.
 * Arguments: container <OBJECT>, snapshot <ARRAY>. Return Value: <BOOL> exact rebuild.
 * Current caller: Waldo_fnc_SupplyTransfersRequestServer.
 * Example: [crate, savedSnapshot] call Waldo_fnc_SupplyTransfersApplySnapshot;
 */
params [["_container", objNull, [objNull]], ["_snapshot", [], [[]]]];
if (!isServer || {isNull _container} || {count _snapshot != 4}) exitWith {false};
_snapshot params ["_items", "_weapons", "_magazines", "_backpacks"];
clearItemCargoGlobal _container;
clearWeaponCargoGlobal _container;
clearMagazineCargoGlobal _container;
clearBackpackCargoGlobal _container;
{_container addItemCargoGlobal _x} forEach _items;
{_container addWeaponWithAttachmentsCargoGlobal [_x, 1]} forEach _weapons;
{_container addMagazineAmmoCargo [(_x select 0), 1, (_x select 1)]} forEach _magazines;
private _valid = true;
{
    _x params ["_class", "_contents"];
    private _before = count (everyBackpack _container);
    _container addBackpackCargoGlobal [_class, 1];
    private _after = everyBackpack _container;
    if (count _after != _before + 1) then {_valid = false} else {
        if !([_after select _before, _contents] call Waldo_fnc_SupplyTransfersApplySnapshot) then {_valid = false};
    };
} forEach _backpacks;
private _actual = [_container] call Waldo_fnc_SupplyTransfersSnapshot;
if !(_actual isEqualTo _snapshot) then {
    diag_log format ["[WMP SUPPLY SNAPSHOT MISMATCH] class=%1 expected=%2 actual=%3",
        typeOf _container, _snapshot, _actual];
};
_valid && {_actual isEqualTo _snapshot}
