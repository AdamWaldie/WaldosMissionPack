/*
 * Author: WaldoTheWarfighter
 * Releases a LAMBS Waypoints building task started through Cortex without leaving its CQB loop,
 * garrison hold, PATH lock, stance, forced speed or task waypoint behind.
 *
 * Cortex records the exact pre-task group and unit state before calling LAMBS. CQB script handles
 * are terminated locally; LAMBS task variables and event handlers are removed; only settings still
 * carrying the value applied by the building task are restored. A Zeus takeover therefore removes
 * the old controller without issuing a replacement movement command. On locality loss, only the old
 * owner's local script is retired and the public semantic intent remains for the new owner to replay.
 *
 * Locality/authority: runs on the machine that started the LAMBS task. Ordinary release is called on
 * the current group owner. The migration-only path may run immediately after locality was lost so it
 * can terminate the old owner's local script handle.
 * Repeat/JIP: local backend state is consumed once. Public intent is cleared for ordinary release and
 * retained only for locality migration, where the new owner reconstructs the task from that intent.
 *
 * Arguments:
 * 0: group <GROUP> - group whose delegated building task is being released
 * 1: restore formation movement <BOOL> - true rejoins surviving AI to the leader (default true)
 * 2: locality migration only <BOOL> - true preserves public semantic intent (default false)
 *
 * Return Value: Boolean - true when a delegated LAMBS task was retired
 * Current callers: CortexReleaseGroup, CortexLocality, CortexStop, CortexGarrison and
 * CortexClearBuilding.
 * Example: [_group, false] call Waldo_fnc_CortexLambsBuildingRelease;
 */
params [
    ["_group",grpNull,[grpNull]],
    ["_restore",true,[true]],
    ["_migration",false,[true]]
];
if (isNull _group) exitWith {false};
private _backend=_group getVariable ["Waldo_Cortex_LambsBuildingBackend",[]];
if (_backend isEqualTo []) exitWith {false};
_backend params ["_kind","_baseline",["_ownedWaypoints",[]]];
private _handle=_group getVariable ["Waldo_Cortex_LambsBuildingHandle",scriptNull];
if (_kind == "CQB" && {!scriptDone _handle}) then {terminate _handle};
_group setVariable ["Waldo_Cortex_LambsBuildingHandle",nil];
_group setVariable ["Waldo_Cortex_LambsBuildingBackend",nil];

if (_migration) exitWith {true};

// Remove only the waypoint(s) created by the delegated task. A later Zeus waypoint is not in this
// captured list and remains untouched.
if (local _group) then {
    private _waypointsToDelete=+_ownedWaypoints;
    reverse _waypointsToDelete;
    {deleteWaypoint _x} forEach _waypointsToDelete;
};

private _groupState=_baseline getOrDefault ["group",[]];
if (local _group && {count _groupState == 10}) then {
    _groupState params ["_behaviour","_formation","_speed","_combat","_attack","_ownedBehaviour","_ownedFormation","_ownedSpeed","_ownedCombat","_ownedAttack"];
    if (behaviour leader _group == _ownedBehaviour) then {_group setBehaviour _behaviour};
    if (formation _group == _ownedFormation) then {_group setFormation _formation};
    if (speedMode _group == _ownedSpeed) then {_group setSpeedMode _speed};
    if (combatMode _group == _ownedCombat) then {_group setCombatMode _combat};
    if (attackEnabled _group == _ownedAttack) then {_group enableAttack _attack};
};

private _leader=leader _group;
// LAMBS CQB deliberately sets the group to never flee. Arma exposes no getter for that coefficient,
// whose engine default is 1, or for the live IR-laser state. Restore the morale default, but leave
// weapon-light ownership with the engine/LAMBS rather than guessing a pre-task laser state.
if (_kind == "CQB" && {local _group}) then {_group allowFleeing 1};
{
    _x params ["_unit","_stance","_forcedSpeed","_path","_move","_cover","_suppression","_autocombat"];
    if (local _unit) then {
        if (!isNil "lambs_main_fnc_removeEventhandlers") then {
            [_unit,_unit getVariable ["lambs_wp_eventhandlers",[]]] call lambs_main_fnc_removeEventhandlers;
        };
        _unit setVariable ["lambs_wp_eventhandlers",nil];
        _unit setVariable ["lambs_main_currentTask",nil];
        _unit setVariable ["lambs_main_currentTarget",nil];
        _unit setVariable ["lambs_danger_disableAI",nil,true];
        _unit setVariable ["lambs_danger_forceMove",nil,true];
        // Restore only values the delegated task is known to own. MOVE and COVER are sampled for
        // diagnostics but LAMBS building tasks do not change them, so touching them here could
        // overwrite a newer curator or mission-script decision.
        if (unitPos _unit in ["UP","MIDDLE","AUTO"]) then {
            _unit setUnitPos _stance;
            _unit setUnitPosWeak _stance;
        };
        if (getForcedSpeed _unit < 0) then {_unit forceSpeed _forcedSpeed};
        if !(_unit checkAIFeature "PATH") then {
            if (_path) then {_unit enableAI "PATH"} else {_unit disableAI "PATH"};
        };
        if (_kind == "CQB") then {
            if !(_unit checkAIFeature "SUPPRESSION") then {
                if (_suppression) then {_unit enableAI "SUPPRESSION"} else {_unit disableAI "SUPPRESSION"};
            };
            if !(_unit checkAIFeature "AUTOCOMBAT") then {
                if (_autocombat) then {_unit enableAI "AUTOCOMBAT"} else {_unit disableAI "AUTOCOMBAT"};
            };
        };
        if (_restore && {alive _unit} && {!isPlayer _unit}) then {_unit doFollow _leader};
    };
} forEach (_baseline getOrDefault ["units",[]]);

if ((_group getVariable ["lambs_main_currentTactic",""]) in ["taskCQB","taskGarrison"]) then {
    _group setVariable ["lambs_main_currentTactic",nil];
};
_group setVariable ["Waldo_Cortex_BuildingIntent",nil,true];
_group setVariable ["Waldo_Cortex_BuildingBaseline",nil,true];
_group setVariable ["Waldo_Cortex_BuildingBackend",nil,true];
diag_log format ["[WMP CORTEX] %1 delegated LAMBS %2 task released",_group,_kind];
true
