/*
 * Author: WaldoTheWarfighter
 * Switches a registered jammer on or off without removing it, so a mission maker or curator can
 * flip a jammer's state from a trigger, script or Zeus module. Server-authoritative - calling on
 * a client forwards to the server, which updates and re-broadcasts the jammer registry.
 *
 * Arguments:
 * 0: Reference <OBJECT or NUMBER> - the jammer object, or its jammer id (from Waldo_fnc_Jammer)
 * 1: Active <BOOL> - true = switch on, false = switch off (optional, default: toggles current)
 *
 * Return Value:
 * Bool <BOOL> - true if a matching jammer was found and updated (server side)
 *
 * Example:
 * [myJammer, false] call Waldo_fnc_JammerToggle;   // switch a jammer object off
 * [3] call Waldo_fnc_JammerToggle;                 // flip jammer id 3 to its opposite state
 */

params [["_ref", objNull], ["_active", "TOGGLE"]];

if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_JammerToggle", 2];
    false
};

// Resolve the target id from either an object or a raw id.
private _id = -1;
if (_ref isEqualType objNull) then {
    _id = _ref getVariable ["Waldo_Jamming_Id", -1];
} else {
    if (_ref isEqualType 0) then { _id = _ref; };
};
if (_id < 0) exitWith { false };

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
private _idx = _registry findIf { (_x select 0) == _id };
if (_idx < 0) exitWith { false };

private _entry = _registry select _idx;
private _new = _active;
if (_active isEqualType "") then { _new = !(_entry select 7); };
_entry set [7, _new];
_registry set [_idx, _entry];
missionNamespace setVariable ["Waldo_Jamming_Registry", _registry, true];
if (_new && {!isNull (_entry select 1)}) then {
    (_entry select 1) setVariable ["Waldo_Jamming_FieldDisabled", false, true];
    if ((_entry select 1) getVariable ["Waldo_Jamming_DisableChallenge", false] && {!isNil "Waldo_fnc_MiniGameInteractionReset"}) then {
        [(_entry select 1), true, false] call Waldo_fnc_MiniGameInteractionReset;
    };
};

diag_log format ["[WMP JAM] Jammer %1 set active=%2", _id, _new];

true
