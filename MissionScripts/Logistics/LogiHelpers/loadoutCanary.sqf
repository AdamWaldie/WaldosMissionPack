/*
 * Author: WaldoTheWarfighter
 * Returns a small, ACRE-independent fingerprint of a unit's stable equipment commands. Used both to
 * verify a restored loadout actually took effect (respawnRestoreLoadout.sqf) and to detect whether a
 * unit's inventory has finished settling before an automatic capture treats it as final
 * (Waldo_fnc_LoadoutWaitStable). Deliberately not a full getUnitLoadout comparison: that top-level
 * shape never changes with content (so a count comparison could never detect a no-op), while a full
 * deep-equality comparison would false-positive the moment ACRE assigns fresh unique radio item IDs
 * onto otherwise-unchanged gear.
 *
 * Arguments:
 * 0: unit <OBJECT>
 *
 * Return Value: ARRAY - [primaryWeapon, secondaryWeapon, handgunWeapon, uniform, vest, backpack, headgear].
 *
 * Example: private _canary = [player] call Waldo_fnc_LoadoutCanary;
 * Current callers: saveRespawnLoadout.sqf, respawnRestoreLoadout.sqf, Waldo_fnc_LoadoutWaitStable.
 */
params [["_unit", objNull, [objNull]]];
[primaryWeapon _unit, secondaryWeapon _unit, handgunWeapon _unit, uniform _unit, vest _unit, backpack _unit, headgear _unit]
