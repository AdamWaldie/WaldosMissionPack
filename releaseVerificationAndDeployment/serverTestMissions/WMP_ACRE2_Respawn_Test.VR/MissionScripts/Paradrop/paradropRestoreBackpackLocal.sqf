/*
 * Author: WaldoTheWarfighter
 * Restores the exact backpack portion of a local jumper's saved unit loadout after a HALO jump.
 * Magazine ammunition, weapons, nested containers and item counts are preserved by restoring the
 * engine loadout structure instead of rebuilding cargo from backpackItems. Cleanup is repeat-safe
 * for the manual hold action and automatic landing watcher.
 *
 * Arguments:
 * 0: jumping unit <OBJECT>
 *
 * Return Value: BOOL - true when a saved backpack state was restored.
 *
 * Example: [player] call Waldo_fnc_ParadropRestoreBackpackLocal;
 * Current callers: ParaBackpack manual hold action and automatic landing watcher.
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit || {!local _unit}) exitWith {false};
private _saved = _unit getVariable ["Waldo_Paradrop_SavedBackpackLoadout", []];
if (count _saved < 2 || {!(_saved param [0, false])}) exitWith {false};

private _loadout = getUnitLoadout _unit;
if (count _loadout < 6) exitWith {false};
_loadout set [5, _saved param [1, []]];
_unit setUnitLoadout _loadout;
_unit forceWalk false;

private _actionId = _unit getVariable ["Waldo_Paradrop_RestoreBackpackAction", -1];
if (_actionId >= 0) then {[_unit, _actionId] call BIS_fnc_holdActionRemove;};
_unit setVariable ["Waldo_Paradrop_RestoreBackpackAction", -1];
_unit setVariable ["Waldo_Paradrop_SavedBackpackLoadout", nil];
_unit setVariable ["Waldo_Paradrop_BackpackWatchToken", (_unit getVariable ["Waldo_Paradrop_BackpackWatchToken", 0]) + 1];
true
