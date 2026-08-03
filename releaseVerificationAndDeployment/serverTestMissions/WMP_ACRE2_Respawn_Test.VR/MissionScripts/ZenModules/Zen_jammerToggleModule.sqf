/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: finds the nearest registered radio jammer to where the curator dropped the
 * module and flips it on/off (Waldo_fnc_JammerToggle). No dialog - it acts immediately and reports
 * the new state to the curator via systemChat. The registry write is server-authoritative.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenJammerToggle;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos", ["_actor", objNull]];

if (!isServer) exitWith {
    [_modulePos, _objectPos, player] remoteExecCall ["Waldo_fnc_ZenJammerToggle", 2];
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {isNull _actor || {_requestOwner != owner _actor}}) exitWith {};
private _notify = {
    params ["_message"];
    if (!isNull _actor) then {["JAMMER CONTROL", _message, 6, "INFO"] remoteExecCall ["Waldo_fnc_JammingNotice", owner _actor];};
};

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
if (_registry isEqualTo []) exitWith {["No radio jammers exist in this mission."] call _notify;};

// Pick the nearest jammer with a valid object.
private _bestId = -1;
private _bestState = false;
private _bestDist = 1e11;
{
    private _obj = _x select 1;
    if (!isNull _obj) then {
        private _d = _obj distance _modulePos;
        if (_d < _bestDist) then {
            _bestDist = _d;
            _bestId = _x select 0;
            _bestState = _x select 7;
        };
    };
} forEach _registry;

if (_bestId < 0) exitWith {["No radio jammer found nearby."] call _notify;};

private _new = !_bestState;
[_bestId, _new] call Waldo_fnc_JammerToggle;
[format ["Nearest radio jammer switched %1.", (["OFF", "ON"] select _new)]] call _notify;
diag_log format ["[WMP ZEN] Jammer toggle id=%1 active=%2 curator=%3 owner=%4", _bestId, _new, if (isNull _actor) then {"<unknown>"} else {name _actor}, _requestOwner];
