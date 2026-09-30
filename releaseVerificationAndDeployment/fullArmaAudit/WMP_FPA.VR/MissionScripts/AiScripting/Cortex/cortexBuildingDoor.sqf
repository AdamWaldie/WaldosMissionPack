/*
 * Author: WaldoTheWarfighter
 * Lets an approaching soldier on an explicit building order open a recognised unlocked door.
 * Locality/authority: called only on the soldier owner; BIS door animation has global effect.
 * Repeat/JIP: two-second building cooldown bounds requests; engine door state persists for JIP.
 * Door model metadata is cached per building on each owner; locks are always read live.
 * Arguments: 0 unit <OBJECT>, default objNull; 1 building <OBJECT>, default objNull.
 * Return: BOOL, an opening request was issued (not proof of entry).
 * Current callers: CortexClearBuilding and CortexGarrisonApplyLocal owner jobs.
 * Example: [_soldier,_house] call Waldo_fnc_CortexBuildingDoor;
 */
params [["_unit",objNull,[objNull]],["_building",objNull,[objNull]]];
if (isNull _unit || {isNull _building} || {!local _unit} || {!alive _unit}
    || {isPlayer _unit} || {lifeState _unit == "INCAPACITATED"}
    || {vehicle _unit != _unit} || {!alive _building}
    || {!([group _unit] call Waldo_fnc_CortexIsEligible)}) exitWith {false};
if (serverTime < (_building getVariable ["Waldo_Cortex_DoorRequestUntil",-1])) exitWith {false};
// Model metadata is stable for this object's lifetime. Locks and animation phases are not.
private _doors=_building getVariable ["Waldo_Cortex_DoorDefinitions",[]];
if (isNil {_building getVariable "Waldo_Cortex_DoorDefinitions"}) then {
    private _config=configOf _building;
    private _count=(getNumber (_config >> "numberOfDoors")) min 64;
    for "_index" from 1 to _count do {
        private _source=format ["Door_%1_sound_source",_index];
        if (isClass (_config >> "AnimationSources" >> _source)) then {
            private _memory=_building selectionPosition [format ["Door_%1_trigger",_index],"Memory"];
            if (_memory isNotEqualTo [0,0,0]) then {_doors pushBack [_index,_source,_memory]};
        };
    };
    _building setVariable ["Waldo_Cortex_DoorDefinitions",_doors];
};
private _requested=false;
{
    _x params ["_index","_source","_memory"];
    private _lock=_building getVariable [format ["bis_disabled_Door_%1",_index],0];
    // Unknown door/lock conventions are left to their mod rather than guessed or unlocked.
    if (_lock isEqualTo 0 && {_building animationSourcePhase _source < 0.1}) then {
        private _position=_building modelToWorldWorld _memory;
        // Building pathfinding can discard a closed-door route six to twelve metres before
        // the interaction point. Request the normal unlocked-door action during approach so
        // reaching the threshold is not itself a prerequisite for making the route valid.
        if ((getPosASL _unit) vectorDistance _position <= 12) exitWith {
            _building setVariable ["Waldo_Cortex_DoorRequestUntil",serverTime+2,true];
            [_building,_index,1] call BIS_fnc_door;
            _requested=true;
        };
    };
    if (_requested) exitWith {};
} forEach _doors;
_requested
