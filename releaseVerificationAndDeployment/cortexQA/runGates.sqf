/*
 * Author: WaldoTheWarfighter
 * Exercises exclusion and master gates with visible, measured defence movement.
 * Locality/authority: scheduled dedicated-server QA; disposable groups are server-pinned.
 * Repeat/JIP: actors are fresh per case and deleted; observer positions are public for JIP.
 * Arguments: 0 check <CODE>, 1 phase <CODE>, 2 wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAGates.sqf";
 */
params ["_check","_phase","_wait"];
private _savedSides=missionNamespace getVariable ["Waldo_AIPass_IncludedSides",["WEST","EAST","GUER"]];
{
    private _case=_x;
    missionNamespace setVariable ["Waldo_AIPass_IncludedSides",["EAST","WEST","GUER"],true];
    [createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIRebalance_Enable",false],
        ["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Regroup_Enable",false]]] call Waldo_fnc_CortexTuning;
    [{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
    private _group=createGroup [east,true];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    private _unit=_group createUnit ["O_Soldier_F",[2250,1100,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["GATE %1",_case],true];
    _unit setVariable ["Waldo_CortexQA_Target",[2250,1140,0],true];
    doStop _unit;
    switch (_case) do {
        case "MASTER": {[createHashMapFromArray [["Waldo_AIPass_Enable",false]]] call Waldo_fnc_CortexTuning; [{!(missionNamespace getVariable ["Waldo_AIPass_Active",true])},20] call _wait};
        case "GROUP": {_group setVariable ["Waldo_AIPass_Exclude",true,true]};
        case "UNIT": {_unit setVariable ["Waldo_AI_Exclude",true,true]};
        case "EXTERNAL": {_group setVariable ["Waldo_AI_ExternalControl",true,true]};
        case "SIDE": {missionNamespace setVariable ["Waldo_AIPass_IncludedSides",["WEST"],true]};
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[_unit],true];
    [format ["Exclusion gate: %1",_case],"The requested defence point is 40 m north. With this gate closed the order must be refused and the soldier must remain at the start. The same soldier then receives the order with the gate open and must walk there.",[2250,1120,0]] call _phase;
    private _start=getPosATL _unit;
    private _accepted=[_group,[2250,1140,0],0,10] call Waldo_fnc_CortexDefend;
    private _maxTravel=0;
    for "_sample" from 1 to 12 do {sleep 1; _maxTravel=_maxTravel max (_unit distance2D _start)};
    [format ["CORE-%1-refused-and-stationary",_case],!_accepted && {alive _unit} && {_maxTravel < 3},format ["accepted=%1 maximum travel=%2",_accepted,_maxTravel]] call _check;
    _group setVariable ["Waldo_AIPass_Exclude",false,true];
    _unit setVariable ["Waldo_AI_Exclude",false,true];
    _group setVariable ["Waldo_AI_ExternalControl",false,true];
    missionNamespace setVariable ["Waldo_AIPass_IncludedSides",["EAST","WEST","GUER"],true];
    [createHashMapFromArray [["Waldo_AIPass_Enable",true]]] call Waldo_fnc_CortexTuning;
    [{missionNamespace getVariable ["Waldo_AIPass_Active",false]},20] call _wait;
    [format ["Gate reopened: %1",_case],"The soldier must now physically reach the north marker. A refusal check without this positive movement control does not validate the fixture.",[2250,1120,0]] call _phase;
    _accepted=[_group,[2250,1140,0],0,10] call Waldo_fnc_CortexDefend;
    private _arrived=[{alive _unit && {_unit distance2D [2250,1140,0] < 3} && {_unit distance2D _start > 35}},60] call _wait;
    [format ["CORE-%1-reopened-physical-arrival",_case],_accepted && {_arrived},str getPosATL _unit] call _check;
    [_group] call Waldo_fnc_CortexDefendRelease;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    deleteVehicle _unit; deleteGroup _group;
} forEach ["MASTER","GROUP","UNIT","EXTERNAL","SIDE"];

missionNamespace setVariable ["Waldo_AIPass_IncludedSides",_savedSides,true];
