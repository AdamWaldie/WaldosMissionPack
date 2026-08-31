/*
 * Author: WaldoTheWarfighter
 * Server-authoritatively accumulates tree hits and creates a reusable fallen-tree object.
 * Locality and authority: Server-only target mutation. Player clients request it through the
 * registered remote call; owner, range, cooldown, tool and target checks are repeated on the server.
 * ACE dragging/carrying remains interface-local and is replayed for JIP with the fallen object as
 * the JIP key. Arma therefore removes that replay automatically when the object is deleted; WMP
 * does not maintain a parallel lifetime registry or transmit executable source code.
 * Repeat/JIP behaviour: strikes are cooldown-gated and the drag/carry setup is repeat-safe in ACE.
 * Each fallen object's JIP side effect exists only for that object's engine-managed lifetime.
 *
 * Arguments:
 * 0: unit <OBJECT> - requesting player
 * 1: weapon <STRING> - validated cutting tool
 * 2: target <OBJECT> - terrain or placed tree
 *
 * Return Value:
 * Boolean - true when the hit was accepted
 *
 * Example:
 * [_unit, _weapon, _tree] remoteExecCall ["Waldo_fnc_TreeFellingProcess", 2];
 * Result: Accepts one valid strike, or fells/replaces the tree when accumulated hits reach the threshold.
 * Current caller: Waldo_fnc_TreeFellingSwing after the local player completes the cutting action.
 */

params ["_unit", "_weapon", "_target"];
if !(isServer) exitWith {false};
if (isNull _unit || {!alive _unit}) exitWith {false};
if (remoteExecutedOwner > 0 && {owner _unit != remoteExecutedOwner}) exitWith {false};
if (!isNull _target && {_unit distance _target > (missionNamespace getVariable ["Waldo_TreeFelling_Range", 3]) + 1}) exitWith {false};

private _patterns = missionNamespace getVariable ["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]];
private _weaponLower = toLowerANSI _weapon;
if (_patterns findIf {_weaponLower find toLowerANSI _x >= 0} < 0) exitWith {false};

private _protectedAreas = missionNamespace getVariable ["Waldo_TreeFelling_ProtectedAreas", []];
if (!isNull _target && {_protectedAreas findIf {_target inArea _x} >= 0}) exitWith {
    ["TREE FELLING", "Tree felling is prohibited in this area.", "WARNING", "TREE_FELLING"] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _unit];
    false
};

private _now = diag_tickTime;
if (_now < (_unit getVariable ["Waldo_TreeFelling_NextHit", 0])) exitWith {false};
_unit setVariable ["Waldo_TreeFelling_NextHit", _now + (missionNamespace getVariable ["Waldo_TreeFelling_HitCooldown", 0.35])];

private _clearedBushes = 0;
if (missionNamespace getVariable ["Waldo_TreeFelling_ClearBushes", false]) then {
    private _bushes = nearestTerrainObjects [_unit, ["Bush"], missionNamespace getVariable ["Waldo_TreeFelling_BushRadius", 4], false, true];
    {_x setDamage 1; _clearedBushes = _clearedBushes + 1} forEach _bushes;
};

if (isNull _target) exitWith {_clearedBushes > 0};
private _model = toLowerANSI ((getModelInfo _target) select 1);
private _allowedClasses = missionNamespace getVariable ["Waldo_TreeFelling_AllowedClasses", []];
if (_model find "tree" < 0 && {_allowedClasses find typeOf _target < 0}) exitWith {_clearedBushes > 0};

private _bounds = boundingBoxReal _target;
private _height = abs (((_bounds select 1) select 2) - ((_bounds select 0) select 2));
private _toolProfiles = missionNamespace getVariable ["Waldo_TreeFelling_ToolEfficiency", createHashMap];
if !(_toolProfiles isEqualType createHashMap) then {_toolProfiles = createHashMap};
private _toolProfileKeys = keys _toolProfiles;
private _exactToolIndex = _toolProfileKeys findIf {toLowerANSI _x == _weaponLower};
private _efficiency = 1;
if (_exactToolIndex >= 0) then {
    _efficiency = _toolProfiles get (_toolProfileKeys select _exactToolIndex);
} else {
    private _bestPatternLength = -1;
    {
        private _pattern = toLowerANSI _x;
        if (_pattern != "" && {_weaponLower find _pattern >= 0} && {count _pattern > _bestPatternLength}) then {
            _efficiency = _toolProfiles get _x;
            _bestPatternLength = count _pattern;
        };
    } forEach _toolProfileKeys;
};
if !(_efficiency isEqualType 0) then {_efficiency = 1};
_efficiency = _efficiency max 0.05;
private _required = ceil (((missionNamespace getVariable ["Waldo_TreeFelling_BaseHits", 4]) + (_height * (missionNamespace getVariable ["Waldo_TreeFelling_HeightFactor", 0.35]))) / _efficiency);
private _hits = (_target getVariable ["Waldo_TreeFelling_Hits", 0]) + 1;
_target setVariable ["Waldo_TreeFelling_Hits", _hits, true];

private _progress = round ((_hits / (_required max 1)) * 100) min 100;
["TREE FELLING", format ["Cutting progress: %1%%", _progress], "INFO", "TREE_FELLING", 3] remoteExecCall ["Waldo_fnc_FeatureNotifyLocal", owner _unit];
if (_hits < _required) exitWith {true};

private _position = getPosATL _target;
private _direction = getDir _target;
_target setDamage 1;
hideObjectGlobal _target;

private _classes = missionNamespace getVariable [
    "Waldo_TreeFelling_FallenClasses",
    ["Land_WoodenLog_F"]
];
private _thresholds = missionNamespace getVariable ["Waldo_TreeFelling_SizeThresholds", [7, 15]];
private _tierClasses = if (_height < (_thresholds param [0, 7])) then {
    missionNamespace getVariable ["Waldo_TreeFelling_FallenClassesSmall", []]
} else {
    if (_height <= (_thresholds param [1, 15])) then {
        missionNamespace getVariable ["Waldo_TreeFelling_FallenClassesMedium", []]
    } else {
        missionNamespace getVariable ["Waldo_TreeFelling_FallenClassesLarge", []]
    }
};
if (count _tierClasses > 0) then {_classes = _tierClasses};
private _validClasses = _classes select {isClass (configFile >> "CfgVehicles" >> _x)};
private _fallenObject = objNull;
if (count _validClasses > 0) then {
    private _fallen = createVehicle [selectRandom _validClasses, _position, [], 0, "CAN_COLLIDE"];
    _fallenObject = _fallen;
    private _directionMode = toUpperANSI (missionNamespace getVariable ["Waldo_TreeFelling_DirectionMode", "RANDOM"]);
    private _fallenDirection = switch (_directionMode) do {
        case "STRIKE": {_unit getDir _target};
        case "ORIGINAL": {_direction + random [-15, 0, 15]};
        default {random 360};
    };
    _fallen setDir _fallenDirection;
    _fallen setVariable ["Waldo_TreeFelling_SourceModel", _model, true];
    if (isClass (configFile >> "CfgPatches" >> "ace_dragging")) then {
        [_fallen, true, [0, 2, 0], 90] remoteExecCall ["ace_dragging_fnc_setDraggable", 0, _fallen];
        if (_height < 8) then {
            [_fallen, true, [0, 1, 0], 0] remoteExecCall ["ace_dragging_fnc_setCarryable", 0, _fallen];
        };
    };
};

private _yieldObjects = [];
{
    _x params [["_yieldClass", "", [""]], ["_yieldCount", 1, [0]]];
    if (isClass (configFile >> "CfgVehicles" >> _yieldClass)) then {
        for "_yieldIndex" from 1 to (round _yieldCount max 0) do {
            _yieldObjects pushBack (createVehicle [_yieldClass, _position, [], 2, "NONE"]);
        };
    };
} forEach (missionNamespace getVariable ["Waldo_TreeFelling_Yields", []]);

private _regrowSeconds = missionNamespace getVariable ["Waldo_TreeFelling_RegrowSeconds", -1];
if (_regrowSeconds > 0) then {
    [_target, _fallenObject, _yieldObjects, _regrowSeconds] spawn {
        params ["_tree", "_fallen", "_yields", "_delay"];
        sleep _delay;
        if (!isNull _fallen) then {deleteVehicle _fallen};
        {if (!isNull _x) then {deleteVehicle _x}} forEach _yields;
        if (!isNull _tree) then {
            _tree hideObjectGlobal false;
            _tree setDamage 0;
            _tree setVariable ["Waldo_TreeFelling_Hits", 0, true];
        };
    };
};
true
