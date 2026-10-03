/*
 * Author: WaldoTheWarfighter
 * Starts the installed LAMBS Waypoints controller as Cortex's primary building backend while
 * retaining the state needed for clean Zeus interruption, stop and locality migration.
 *
 * This is an integration wrapper around the public LAMBS task functions; it does not copy LAMBS
 * implementation. GARRISON uses taskGarrison without teleporting. CQB stores the spawned script
 * handle so Cortex can terminate the continuing LAMBS room cycle before an external order. The
 * public semantic intent is replayable by a new group owner; engine commands and script handles are
 * never replayed across machines.
 *
 * Locality/authority: current group owner only. The caller authenticates and forwards server
 * requests before reaching this function.
 * Repeat/JIP: replaces an earlier delegated building task after releasing it. Public intent and
 * backend diagnostics identify the active task; the baseline and script handle remain owner-local.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: kind <STRING> - GARRISON or CQB
 * 2: target <ARRAY or OBJECT> - garrison centre or CQB building
 * 3: radius <NUMBER> - search radius
 *
 * Return Value: Boolean - true when the installed LAMBS function was started
 * Current callers: CortexGarrison and CortexClearBuilding.
 * Example: [_group,"CQB",_building,35] call Waldo_fnc_CortexLambsBuildingStart;
 */
params [
    ["_group",grpNull,[grpNull]],
    ["_kind","",[""]],
    ["_target",objNull,[objNull,[]]],
    ["_radius",50,[0]]
];
_kind=toUpperANSI _kind;
if (isNull _group || {!local _group} || {!(_kind in ["GARRISON","CQB"])}
    || {!(isClass (configFile >> "CfgPatches" >> "lambs_wp"))}) exitWith {false};
if (!isNil {_group getVariable "Waldo_Cortex_LambsBuildingBackend"}) then {
    [_group,false] call Waldo_fnc_CortexLambsBuildingRelease;
};

// A migrated task reuses the original pre-task snapshot. Capturing the already modified LAMBS
// state on the new owner would make final cleanup restore FILE/FULL and disabled AI features.
private _publishedBaseline=_group getVariable ["Waldo_Cortex_BuildingBaseline",[]];
private _baseline=if ((_group getVariable ["Waldo_Cortex_BuildingIntent",[]]) isNotEqualTo []
    && {count _publishedBaseline == 2}) then {
    createHashMapFromArray _publishedBaseline
} else {
    private _baseBehaviour=behaviour leader _group;
    private _baseFormation=formation _group;
    private _baseSpeed=speedMode _group;
    private _baseCombat=combatMode _group;
    private _baseAttack=attackEnabled _group;
    private _ownedBehaviour=["SAFE",_baseBehaviour] select (_kind == "CQB");
    private _ownedFormation=[_baseFormation,"FILE"] select (_kind == "CQB");
    private _ownedSpeed=[_baseSpeed,"FULL"] select (_kind == "CQB");
    // Arma has no scripting getter for the live IR-laser state. Do not invent one here: the old
    // isIRLaserOn token was not an engine command and made this entire function fail to compile.
    private _unitState=(units _group) apply {
        [_x,unitPos _x,getForcedSpeed _x,_x checkAIFeature "PATH",_x checkAIFeature "MOVE",
            _x checkAIFeature "COVER",_x checkAIFeature "SUPPRESSION",_x checkAIFeature "AUTOCOMBAT"]
    };
    createHashMapFromArray [
        ["group",[_baseBehaviour,_baseFormation,_baseSpeed,_baseCombat,_baseAttack,
            _ownedBehaviour,_ownedFormation,_ownedSpeed,_baseCombat,false]],
        ["units",_unitState]
    ]
};
private _beforeWaypoints=+waypoints _group;
private _handle=scriptNull;
private _intent=[];

if (_kind == "GARRISON") then {
    private _centre=if (_target isEqualType objNull) then {getPosATL _target} else {+_target};
    [_group,_centre,_radius,[],false,true,-2,false] call lambs_wp_fnc_taskGarrison;
    _intent=["GARRISON",_centre,_radius];
} else {
    if !(_target isEqualType objNull) exitWith {};
    _handle=[_group,getPosATL _target,_radius] spawn lambs_wp_fnc_taskCQB;
    _intent=["CQB",_target,_radius];
};
if (_intent isEqualTo []) exitWith {false};

private _ownedWaypoints=(waypoints _group) select {!(_x in _beforeWaypoints)};
_group setVariable ["Waldo_Cortex_LambsBuildingBackend",[_kind,_baseline,_ownedWaypoints]];
_group setVariable ["Waldo_Cortex_LambsBuildingHandle",_handle];
_group setVariable ["Waldo_Cortex_BuildingIntent",_intent,true];
_group setVariable ["Waldo_Cortex_BuildingBaseline",[["group",_baseline get "group"],["units",_baseline get "units"]],true];
_group setVariable ["Waldo_Cortex_BuildingBackend",["LAMBS",_kind,serverTime],true];
diag_log format ["[WMP CORTEX] %1 %2 handed to installed LAMBS Waypoints backend",_group,_kind];
true
