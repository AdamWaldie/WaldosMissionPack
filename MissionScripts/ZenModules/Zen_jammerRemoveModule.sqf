/*
 * Author: Waldo
 * Zeus module handler: finds the nearest registered radio jammer to where the curator dropped the
 * module and removes it, deleting its emitter object and map marker (Waldo_fnc_JammerRemove). No
 * dialog - it acts immediately and reports to the curator. The registry write is server-authoritative.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - object the module was dropped on (unused)
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenJammerRemove;
 *
 * Public: No
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
if (_registry isEqualTo []) exitWith { systemChat "No radio jammers exist in this mission."; };

// Pick the nearest jammer with a valid object.
private _bestId = -1;
private _bestDist = 1e11;
{
    private _obj = _x select 1;
    if (!isNull _obj) then {
        private _d = _obj distance _modulePos;
        if (_d < _bestDist) then {
            _bestDist = _d;
            _bestId = _x select 0;
        };
    };
} forEach _registry;

if (_bestId < 0) exitWith { systemChat "No radio jammer found nearby."; };

[_bestId, true] call Waldo_fnc_JammerRemove;
systemChat "Nearest radio jammer removed.";
