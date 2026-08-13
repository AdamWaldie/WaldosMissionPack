/*
 * Author: WaldoTheWarfighter
 * Repairs the malformed ACE 3.21.1 setName Respawn callback stored on the local player by CBA XEH.
 * ACE's function expects `[unit, optional force BOOL]`, but its XEH callback forwards Arma's
 * `[new unit, old corpse]` payload. This function replaces only the compiled callback containing
 * `ace_common_fnc_setName` with an argument-safe call to ACE's unchanged final function.
 *
 * Locality and authority: interface-client local. It edits only the local player's
 * `cba_xeh_respawn` callback array after CBA and ACE have initialised. CBA/Arma copy that object
 * variable to subsequent player bodies, so the repair survives ordinary respawns. Calling it again
 * is repeat-safe: an already safe callback is recognised and retained. It creates no public or JIP
 * state and changes no player name itself.
 *
 * Arguments:
 * 0: unit whose local CBA Respawn callback list is repaired <OBJECT> (default: player)
 *
 * Return Value:
 * BOOL - true when the ACE callback is present and safe after the call; false when prerequisites or
 * the expected callback are unavailable.
 *
 * Current callers: initPlayerLocal.sqf after CBA/ACE mission initialisation.
 *
 * Example:
 * [player] call Waldo_fnc_AceSetNameRespawnBindingRepair;
 */

params [["_unit", player, [objNull]]];
if (!hasInterface || {isNull _unit} || {isNil "ace_common_fnc_setName"}) exitWith {false};

private _callbacks = _unit getVariable ["cba_xeh_respawn", []];
if !(_callbacks isEqualType []) exitWith {
    diag_log format ["[WMP ACE COMPAT] Cannot inspect cba_xeh_respawn: unit=%1 valueType=%2.", _unit, typeName _callbacks];
    false
};

private _found = false;
private _replaced = false;
private _safeNeedle = "[_this select 0] call ace_common_fnc_setname";
{
    private _callbackText = str _x;
    private _callbackTextLower = toLower _callbackText;
    if (_callbackTextLower find "ace_common_fnc_setname" >= 0) then {
        _found = true;
        if (_callbackTextLower find _safeNeedle < 0) then {
            _callbacks set [_forEachIndex, {[_this select 0] call ace_common_fnc_setName}];
            _replaced = true;
        };
    };
} forEach _callbacks;

if !(_found) exitWith {
    diag_log format ["[WMP ACE COMPAT] ACE setName Respawn callback was not found on unit=%1 callbacks=%2.", _unit, count _callbacks];
    false
};

_unit setVariable ["cba_xeh_respawn", _callbacks];
missionNamespace setVariable ["Waldo_ACE_SetNameRespawnBindingSafe", true];
diag_log format ["[WMP ACE COMPAT] ACE setName Respawn callback %1 unit=%2 callbacks=%3.", if (_replaced) then {"repaired"} else {"already safe"}, _unit, count _callbacks];
true
