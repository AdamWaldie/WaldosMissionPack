/*
 * Author: WaldoTheWarfighter
 * Converts all ACRE unique-ID radio classes in a unit loadout back to base radio classes before
 * respawn or persistence storage. When ACRE is absent the supplied loadout is returned unchanged.
 *
 * Arguments:
 * 0: loadout source <ARRAY|OBJECT>
 *
 * Return Value: ARRAY - safe unit loadout.
 *
 * Example: private _safe = [getUnitLoadout player] call Waldo_fnc_ACRE2FilterLoadout;
 * Current callers: Waldo_fnc_SaveLoadout and persistence capture/apply.
 */
params [['_source', [], [[], objNull]]];
private _loadout = if (_source isEqualType objNull) then {getUnitLoadout _source} else {+_source};
if !(isClass (configFile >> 'CfgPatches' >> 'acre_main')) exitWith {_loadout};
[_loadout] call acre_api_fnc_filterUnitLoadout
