/*
 * Author: Waldo
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

params ["_modulePos", "_objectPos"];

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
if (_registry isEqualTo []) exitWith { systemChat "No radio jammers exist in this mission."; };

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

if (_bestId < 0) exitWith { systemChat "No radio jammer found nearby."; };

private _new = !_bestState;
[_bestId, _new] call Waldo_fnc_JammerToggle;
systemChat format ["Nearest radio jammer switched %1.", (["OFF", "ON"] select _new)];
