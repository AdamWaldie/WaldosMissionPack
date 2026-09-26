/*
 * Author: WaldoTheWarfighter
 * Undoes the Smart AI Pass changes a group's previous owner left behind.
 *
 * A group that arrives on this machine still carries whatever the last owner changed: combat
 * behaviour, a raised speed, AI features a drill turned off, pass-set stances, an inserted
 * "WMP AI PASS" waypoint and soldiers sent off on drill moves. The last owner's own records stayed
 * behind (or were lost if it disconnected), so this reads the broadcast Waldo_AIPass_Restore record
 * (Waldo_fnc_AIPassPublishRestore) and puts the group back as it was before the pass acted. Soldiers
 * posted by a garrison or defence order are left in place; discovery re-applies those orders. The
 * group then starts again from CALM under this machine's pass.
 * Locality and authority: runs where the group is local; other calls do nothing.
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Boolean - true when a record was found and restored
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassAdoptRestore;
 * Result: a squad handed over mid-flank returns to its patrol behaviour, speed and waypoints.
 *
 * Current caller: Waldo_fnc_AIPassDiscover, for a local group this machine is not managing.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group}) exitWith {false};
private _record = _group getVariable ["Waldo_AIPass_Restore", []];
if !(_record isEqualType []) exitWith {false};
private _changes = createHashMapFromArray _record;
private _leader = leader _group;
[_group] call Waldo_fnc_AIPassGroupMoveClear;
if ("behaviour" in _changes && {behaviour _leader in ["COMBAT", "AWARE"]}) then {
    (_changes get "behaviour") params [["_base", "AWARE", [""]], ["_hadContact", false, [false]]];
    // After a real firefight a squad stays alert rather than slinging weapons, as Waldo_fnc_AIPassRestoreCalm does.
    if (_base == "SAFE" && {_hadContact}) then {_base = "AWARE"};
    _group setBehaviour _base;
};
if ("speed" in _changes) then {_group setSpeedMode (_changes get "speed")};
{
    _x params [["_unit", objNull, [objNull]], ["_feature", "", [""]]];
    if (alive _unit && {local _unit} && {_feature != ""}) then {_unit enableAI _feature};
} forEach (_changes getOrDefault ["features", []]);
{
    if (alive _x && {local _x}) then {
        _x setUnitPos "AUTO";
        _x setVariable ["Waldo_AIPass_StanceSet", nil];
    };
} forEach (_changes getOrDefault ["stance", []]);
{
    if (alive _x && {local _x} && {_x != _leader} && {vehicle _x == _x}
        && {(_x getVariable ["Waldo_AIPass_GarrisonPos", []]) isEqualTo []}
        && {(_x getVariable ["Waldo_AIPass_DefendPos", []]) isEqualTo []}) then {
        _x doFollow _leader;
    };
} forEach units _group;
_group setVariable ["Waldo_AIPass_Restore", nil, true];
_group setVariable ["Waldo_AIPass_RestorePublished", nil];
diag_log format ["[WMP AI PASS] %1 adopted from another owner; restored %2", _group, keys _changes];
true
