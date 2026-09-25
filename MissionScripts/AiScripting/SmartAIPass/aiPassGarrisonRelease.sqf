/*
 * Author: WaldoTheWarfighter
 * Ends a garrison order: soldiers can move again and return to their normal stance.
 *
 * Re-enables PATH, restores each soldier's recorded stance and rejoins formation, and clears the
 * published order so no machine re-applies it. Called automatically when a garrison breaks (losses
 * or broken morale), or by the AI Orders ZEN module and scripts.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner.
 *
 * Arguments:
 * 0: group <GROUP or OBJECT>
 *
 * Return Value:
 * Boolean - true when released or forwarded
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassGarrisonRelease;
 * Result: the defenders leave their positions and fight as a normal squad.
 *
 * Current callers: Waldo_fnc_AIPassGroupTick, the AI Orders ZEN module and mission scripts.
 */

params [["_group", grpNull, [grpNull, objNull]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group] remoteExecCall ["Waldo_fnc_AIPassGarrisonRelease", groupOwner _group]; true} else {false};
};
private _leader = leader _group;
{
    if (local _x) then {
        _x enableAI "PATH";
        if (alive _x) then {
            _x setUnitPos (_x getVariable ["Waldo_AIPass_GarrisonStance", "AUTO"]);
            _x doWatch objNull;
            _x doFollow _leader;
        };
    };
    _x setVariable ["Waldo_AIPass_GarrisonPos", nil, true];
} forEach units _group;
_group setVariable ["Waldo_AIPass_Garrison", nil, true];
_group setVariable ["Waldo_AIPass_GarrisonApplied", nil];
diag_log format ["[WMP AI PASS] %1 garrison released", _group];
true
