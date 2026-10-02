/*
 * Author: WaldoTheWarfighter
 * Checks owner-local permission for defensive reactions on any eligible AI aircraft.
 * Locality/authority: on the aircraft owner; the aircraft does not need to originate from another
 * WMP feature. This prevents the global missile-reaction setting from silently depending on the
 * separate Gunship or Dynamic AA systems.
 * Repeat/JIP: no installation; rechecks permission and uses the shared local Zeus-hold cache.
 * Arguments: 0: aircraft <OBJECT>, objNull.
 * Return: Boolean. Current callers: Waldo_fnc_CortexDiscover missile handler and delayed flare bursts.
 * Example: private _allowed=[_aircraft] call Waldo_fnc_CortexAircraftEligible;
 */
params [["_aircraft",objNull,[objNull]]];
if (isNull _aircraft || {!local _aircraft} || {!alive _aircraft}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active",false])}
    || {[] call Waldo_fnc_CortexIsPaused}) exitWith {false};
private _pilot=driver _aircraft;
if (isNull _pilot || {!alive _pilot} || {isPlayer _pilot} || {unitIsUAV _aircraft} || {_pilot getVariable ["ACE_isUnconscious",false]} || {lifeState _pilot == "INCAPACITATED"}) exitWith {false};
private _group=group _pilot;
if (_group getVariable ["Waldo_AI_ExternalControl",false]
    || {"ALL" in (_group getVariable ["Waldo_AIPass_DisabledFeatures",[]])}
    || {[_group] call Waldo_fnc_CortexZeusHeld}) exitWith {false};
private _sideKey=switch (side _group) do {case west:{"WEST"}; case east:{"EAST"}; case independent:{"GUER"}; case civilian:{"CIV"}; default {""}};
if !(_sideKey in (missionNamespace getVariable ["Waldo_AIPass_IncludedSides",["WEST","EAST","GUER"]])) exitWith {false};
private _included=missionNamespace getVariable ["Waldo_AI_IncludedFactions",[]];
private _excluded=missionNamespace getVariable ["Waldo_AI_ExcludedFactions",[]];
private _classes=missionNamespace getVariable ["Waldo_AI_ExcludedClasses",[]];
if ([_group,_aircraft] findIf {_x getVariable ["Waldo_AI_Exclude",false] || {_x getVariable ["Waldo_AIPass_Exclude",false]}} >= 0) exitWith {false};
(units _group) findIf {
    alive _x && {isPlayer _x || {_x getVariable ["Waldo_AI_Exclude",false]}
        || {_x getVariable ["Waldo_AIPass_Exclude",false]}
        || {!isNull (_x getVariable ["bis_fnc_moduleRemoteControl_owner",objNull])}
        || {count _included > 0 && {!(faction _x in _included)}}
        || {faction _x in _excluded} || {typeOf _x in _classes}}
} < 0
