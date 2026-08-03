/*
 * Author: WaldoTheWarfighter
 * Saves the exact backpack portion of a local jumper's engine loadout, equips a selected steerable
 * parachute backpack, and installs both a manual action and automatic landing watcher. Repeated
 * calls before restoration never overwrite the original saved backpack.
 *
 * Arguments:
 * 0: jumping unit <OBJECT>
 * 1: parachute backpack class <STRING> (default "B_Parachute")
 *
 * Return Value:
 * Boolean - true when the parachute backpack and restoration action were installed.
 *
 * Called by:
 * Waldo_fnc_HaloJumpFunc after aircraft exit.
 *
 * Example:
 * [player, "B_Parachute"] call Waldo_fnc_ParaBackpack;
 */

params [
    ["_player", objNull],
    ["_chuteBackpackClass", "B_Parachute"]
];

if (isNull _player || {!local _player} || {!(isClass (configFile >> "CfgVehicles" >> _chuteBackpackClass))}) exitWith {false};

private _saved = _player getVariable ["Waldo_Paradrop_SavedBackpackLoadout", []];
if (count _saved < 2) then {
    private _loadout = getUnitLoadout _player;
    _player setVariable ["Waldo_Paradrop_SavedBackpackLoadout", [true, _loadout param [5, []]]];
};

removeBackpack _player;
_player addBackpack _chuteBackpackClass;

_player forceWalk true;

private _oldAction = _player getVariable ["Waldo_Paradrop_RestoreBackpackAction", -1];
if (_oldAction >= 0) then {[_player, _oldAction] call BIS_fnc_holdActionRemove};
private _actionId = [
    _player,
    "Ditch Chute And Put On Backpack",
    "\a3\ui_f\data\igui\cfg\holdactions\holdAction_loaddevice_ca.paa",
    "\a3\ui_f\data\igui\cfg\holdactions\holdAction_loaddevice_ca.paa",
    "((count (_this getVariable ['Waldo_Paradrop_SavedBackpackLoadout', []])) > 1) && (((getPosATL _this) # 2 < 2) || {isTouchingGround _this})",
    "((count (_caller getVariable ['Waldo_Paradrop_SavedBackpackLoadout', []])) > 1) && (((getPosATL _caller) # 2 < 5) || {isTouchingGround _caller})",
    {},
    {},
    {
        params ["_target", "_caller", "_actionId", "_arguments"];
        [_caller] call Waldo_fnc_ParadropRestoreBackpackLocal;
    },
    {},
    [],
    5,
    0,
    false,
    false
] call BIS_fnc_holdActionAdd;
_player setVariable ["Waldo_Paradrop_RestoreBackpackAction", _actionId];

private _watchToken = (_player getVariable ["Waldo_Paradrop_BackpackWatchToken", 0]) + 1;
_player setVariable ["Waldo_Paradrop_BackpackWatchToken", _watchToken];
[_player, _watchToken] spawn {
    params ["_unit", "_watchToken"];
    waitUntil {
        uiSleep 0.25;
        isNull _unit
        || {!local _unit}
        || {(_unit getVariable ["Waldo_Paradrop_BackpackWatchToken", -1]) != _watchToken}
        || {count (_unit getVariable ["Waldo_Paradrop_SavedBackpackLoadout", []]) < 2}
        || {!alive _unit}
        || {
            vehicle _unit isEqualTo _unit
            && {
                isTouchingGround _unit
                || {((getPosATL _unit) select 2) <= 1.5}
                || {surfaceIsWater (getPosASL _unit) && {((getPosASLW _unit) select 2) <= 1.5}}
            }
        }
    };
    if (
        !isNull _unit
        && {local _unit}
        && {(_unit getVariable ["Waldo_Paradrop_BackpackWatchToken", -1]) == _watchToken}
        && {count (_unit getVariable ["Waldo_Paradrop_SavedBackpackLoadout", []]) >= 2}
    ) then {
        [_unit] call Waldo_fnc_ParadropRestoreBackpackLocal;
    };
};
true
