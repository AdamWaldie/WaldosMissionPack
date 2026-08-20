/*
 * Author: WaldoTheWarfighter
 * Repairs the malformed ACE 3.21.1 setName Respawn callback stored on the local player by CBA XEH.
 * ACE's function expects `[unit, optional force BOOL]`, but its XEH callback forwards Arma's
 * `[new unit, old corpse]` payload. This function replaces only the compiled callback containing
 * `ace_common_fnc_setName` with an argument-safe call to ACE's unchanged final function.
 *
 * Upstream status: fixed directly by ACE in community/ACE3#11470 (closes ACE issue #11468),
 * targeted for release 3.21.2 - `addons/common/CfgEventHandlers.hpp`'s respawn line changes from
 * `call FUNC(setName)` to `(_this select 0) call FUNC(setName)`, the same argument-safe call this
 * function installs, just spelled with parentheses instead of a one-element array literal. Both
 * forms are recognised as already safe below (see `_safeNeedles`) specifically so this repair
 * becomes a genuine no-op - not a spurious re-patch-and-log-every-respawn - on a client already
 * running a fixed ACE build. Kept rather than removed even after 3.21.2 ships broadly, since a
 * WMP mission's exact ACE version is never guaranteed (older ACE builds, or a modset pinned behind
 * 3.21.2, still hit the original bug).
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
// Two textual forms are recognised as already safe: WMP's own array-literal repair, and ACE's own
// upstream fix (community/ACE3#11470) using a parenthesised single value instead - both pass just
// the respawned unit into ace_common_fnc_setName, functionally identical.
private _safeNeedles = ["[_this select 0] call ace_common_fnc_setname", "(_this select 0) call ace_common_fnc_setname"];
{
    private _callbackText = str _x;
    private _callbackTextLower = toLower _callbackText;
    if (_callbackTextLower find "ace_common_fnc_setname" >= 0) then {
        _found = true;
        private _alreadySafe = _safeNeedles findIf {_callbackTextLower find _x >= 0} != -1;
        if !(_alreadySafe) then {
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
