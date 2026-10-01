/*
 * Author: WaldoTheWarfighter
 * Ends a garrison order: soldiers can move again and return to their normal stance. Normal release
 * rejoins formation; replacement-order release clears only a still-owned combat-labelled hold so
 * a new group waypoint can move the soldier without overwriting a newer direct unit command.
 *
 * Re-enables PATH, restores each soldier's recorded stance and rejoins formation, and clears the
 * published order so no machine re-applies it. Called automatically when a garrison breaks (losses
 * or broken morale), or by the AI Orders ZEN module and scripts.
 * Locality and authority: call where the group is local, or on the server, which forwards to the
 * owner.
 *
 * Review contract: Repeated release restores PATH only for soldiers marked as disabled by this garrison. Mission-maker PATH restrictions remain in place; public assignments are cleared for JIP.
 *
 * Restores only an unchanged Cortex duck stance; preserves later Zeus/script stance choices.
 * Repeat/JIP: repeated release clears published assignments; new owners do not replay a released order.
 * Arguments:
 * 0: group <GROUP or OBJECT>
 * 1: restore formation <BOOL> - false when Zeus already supplied replacement movement (default true)
 *
 * Return Value:
 * Boolean - true when released or forwarded
 *
 * Example:
 * [_group] call Waldo_fnc_CortexGarrisonRelease;
 * Result: the defenders leave their positions and fight as a normal squad.
 *
 * Current callers: Waldo_fnc_CortexGroupTick, the AI Orders ZEN module and mission scripts.
 */

params [["_group", grpNull, [grpNull, objNull]],["_restore",true,[true]]];
if (_group isEqualType objNull) then {_group = group _group};
if (isNull _group) exitWith {false};
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!local _group) exitWith {
    if (isServer) then {[_group,_restore] remoteExecCall ["Waldo_fnc_CortexGarrisonRelease", groupOwner _group]; true} else {false};
};
private _delegated=_group getVariable ["Waldo_Cortex_BuildingBackend",[]];
if (count _delegated >= 2 && {(_delegated select 0) == "LAMBS"} && {(_delegated select 1) == "GARRISON"}) exitWith {
    [_group,_restore] call Waldo_fnc_CortexLambsBuildingRelease
};
// No Cortex assignment means there is nothing for this release to restore.
if ((_group getVariable ["Waldo_AIPass_Garrison",[]]) isEqualTo [] && {units _group findIf {(_x getVariable ["Waldo_AIPass_GarrisonPos",[]]) isNotEqualTo []} < 0}) exitWith {false};
private _leader = leader _group;
{
    if (local _x) then {
        private _unit = _x;
        private _ownedHold = (_unit getVariable ["Waldo_AIPass_GarrisonPos",[]]) isNotEqualTo []
            || {_unit getVariable ["Waldo_AIPass_GarrisonDisabledPath",false]};
        {_unit removeEventHandler _x} forEach (_unit getVariable ["Waldo_AIPass_GarrisonHandlerIds", []]);
        _unit setVariable ["Waldo_AIPass_GarrisonHandlerIds", nil];
        _unit setVariable ["Waldo_AIPass_GarrisonHandlers", nil];
        _unit setVariable ["Waldo_AIPass_DuckUntil", nil];

        if (_x getVariable ["Waldo_AIPass_GarrisonDisabledPath", false]) then {_x enableAI "PATH"};
        if (alive _x && {!isPlayer _x} && {lifeState _x != "INCAPACITATED"}) then {
            // Do not overwrite a subsequent Zeus or mission-script stance change.
            if (unitPos _x == (_x getVariable ["Waldo_Cortex_GarrisonDuckStance", ""])) then {
                _x setUnitPos (_x getVariable ["Waldo_AIPass_GarrisonStance", "AUTO"]);
            };
            _x doWatch objNull;
            if (getForcedSpeed _x == 4 && {!isNil {_x getVariable "Waldo_Cortex_GarrisonForcedSpeed"}}) then {
                _x forceSpeed (_x getVariable ["Waldo_Cortex_GarrisonForcedSpeed",-1]);
            };
            private _command = toUpperANSI currentCommand _x;
            if (_restore || {_ownedHold && {_command in ["","STOP","ATTACK","FIRE","SUPPRESS"]}}) then {
                _x doFollow _leader
            };
        };
    };
    _x setVariable ["Waldo_Cortex_GarrisonDuckStance",nil,true];
    _x setVariable ["Waldo_AIPass_GarrisonDisabledPath", nil, true];
    _x setVariable ["Waldo_AIPass_GarrisonPos", nil, true];
    _x setVariable ["Waldo_AIPass_GarrisonFailed",nil,true];
    _x setVariable ["Waldo_AIPass_GarrisonStance", nil, true];
    _x setVariable ["Waldo_Cortex_GarrisonForcedSpeed",nil];
} forEach units _group;
_group setVariable ["Waldo_AIPass_Garrison", nil, true];
_group setVariable ["Waldo_Cortex_GarrisonCandidates",nil,true];
_group setVariable ["Waldo_AIPass_GarrisonApplied", nil];
diag_log format ["[WMP CORTEX] %1 garrison released", _group];
true
