/*
 * Author: WaldoTheWarfighter
 * Converts all ACRE unique-ID radio classes in a unit loadout back to base radio classes before
 * respawn or persistence storage. When ACRE is absent the supplied loadout is returned unchanged.
 * Locality and authority: Pure loadout conversion on the calling machine; it does not change a
 * unit's inventory or server state.
 * Repeat/JIP: No persistent handler or JIP state. Each call filters the supplied current loadout.
 *
 * Arguments:
 * 0: loadout source <ARRAY|OBJECT>
 *
 * Return Value: ARRAY - safe unit loadout.
 *
 * Example: private _safe = [getUnitLoadout player] call Waldo_fnc_ACRE2FilterLoadout;
 * Current callers: Waldo_fnc_SaveLoadout and persistence capture/apply.
 * Result: Stored loadout data uses base radio classes so ACRE can assign new unique IDs later.
 */
params [['_source', [], [[], objNull]]];
private _loadout = if (_source isEqualType objNull) then {getUnitLoadout _source} else {+_source};
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {_loadout};
[_loadout] call acre_api_fnc_filterUnitLoadout
