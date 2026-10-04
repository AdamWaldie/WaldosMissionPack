/*
 * Author: WaldoTheWarfighter
 * Physically audits Cortex coastal assault with separate and combined crew/passenger groups.
 *
 * One bounded terrain search finds a real dry-to-water transition on the current world. Each case
 * starts offshore with an ordinary AI-driven armed boat and a visible, damageable land target.
 * Target knowledge is supplied explicitly so the audit measures the naval controller rather than
 * discovery luck. It then requires real water travel, a shallow stop, passenger exit, dry-ground
 * egress, crew retention and finite plan cleanup. No waypoint, position or completion state is
 * injected after the fixture starts.
 * Locality/authority: scheduled server fixture; production Cortex runs on the current owners.
 * Repeat/JIP: fresh groups/vehicles per case; all fixtures are deleted and settings restored.
 *
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>.
 * Return Value: Nothing.
 * Current caller: cortexQAServer.sqf when focus is naval/all/features.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQANaval.sqf";
 */

params ["_check","_phase","_wait"];
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],
    ["Waldo_AIPass_Contact_Enable",true],
    ["Waldo_AIPass_NavalAssault_Enable",true],
    ["Waldo_AIPass_Vehicles_Enable",true],
    ["Waldo_AIPass_Flank_Enable",false],
    ["Waldo_AIPass_Advance_Enable",false],
    ["Waldo_AIPass_CoordinatedAssault_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],
    ["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_PostContact_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _pin={
    params ["_group"];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    {_x setVariable ["acex_headless_blacklist",true,true]} forEach units _group;
};

// Find a real coastline once. The audit, unlike production, may spend a larger bounded search budget.
private _centre=[worldSize*0.5,worldSize*0.5,0];
private _coast=[];
for "_bearing" from 0 to 350 step 10 do {
    if (_coast isEqualTo []) then {
        private _lastDry=[];
        for "_radius" from 250 to (worldSize*0.7) step 250 do {
            private _sample=_centre getPos [_radius,_bearing];
            if (surfaceIsWater _sample) then {
                if (_lastDry isNotEqualTo []) then {
                    private _shore=+_lastDry;
                    private _water=_shore getPos [60,_shore getDir _sample];
                    private _offshore=_shore getPos [350,_shore getDir _sample];
                    private _inland=_shore getPos [220,_sample getDir _shore];
                    if (surfaceIsWater _water && {surfaceIsWater _offshore} && {!surfaceIsWater _inland}
                        && {((surfaceNormal _shore) select 2) >= 0.65}
                        && {((surfaceNormal _inland) select 2) >= 0.65}) then {
                        _coast=[_shore,_water,_offshore,_inland];
                    };
                };
            } else {
                _lastDry=_sample;
            };
        };
    };
};
["NAVAL-terrain-coast",_coast isNotEqualTo [],format ["world=%1 worldSize=%2 coast=%3",worldName,worldSize,_coast]] call _check;
if (_coast isEqualTo []) exitWith {};
_coast params ["_shore","_water","_offshore","_inland"];

{
    private _combined=_x;
    private _suffix=["SEPARATE","COMBINED"] select _combined;
    private _boat=createVehicle ["O_Boat_Armed_01_hmg_F",_offshore getPos [40*_forEachIndex,90],[],0,"NONE"];
    _boat setDir (_boat getDir _shore);
    createVehicleCrew _boat;
    private _crewGroup=group driver _boat;
    [_crewGroup] call _pin;
    private _passengerGroup=if (_combined) then {_crewGroup} else {createGroup [east,true]};
    [_passengerGroup] call _pin;
    private _passengers=[];
    for "_index" from 0 to 5 do {
        private _unit=_passengerGroup createUnit ["O_Soldier_F",_offshore,[],0,"NONE"];
        _unit allowDamage false;
        _unit assignAsCargo _boat;
        _unit moveInCargo _boat;
        _unit setVariable ["Waldo_CortexQA_Label",format ["NAVAL %1 P%2",_suffix,_index+1],true];
        _passengers pushBack _unit;
    };
    private _enemy=createVehicle ["B_APC_Wheeled_01_cannon_F",_inland getPos [30*_forEachIndex,270],[],0,"NONE"];
    _enemy allowDamage true;
    _crewGroup reveal [_enemy,4];
    _passengerGroup reveal [_enemy,4];
    private _start=getPosATL _boat;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",(crew _boat)+_passengers+[_enemy],true];
    ["Naval assault: "+toLowerANSI _suffix,"The boat must make a real coastal approach. Operating crew stays aboard; all surviving passengers physically dismount and move onto dry ground. Cyan trails and NAVAL status labels show actual travel and phase.",_shore] call _phase;
    private _started=[{(_boat getVariable ["Waldo_Cortex_NavalPlan",[]]) isNotEqualTo []},35] call _wait;
    ["NAVAL-"+_suffix+"-production-start",_started,str (_boat getVariable ["Waldo_Cortex_NavalPlan",[]])] call _check;
    private _travelled=[{_boat distance2D _start >= 100},120] call _wait;
    ["NAVAL-"+_suffix+"-physical-water-travel",_travelled,str [_start,getPosATL _boat,speed _boat]] call _check;
    private _dismounted=[{_passengers findIf {!alive _x || {vehicle _x != _x}} < 0},90] call _wait;
    ["NAVAL-"+_suffix+"-physical-dismount",_dismounted,str (_passengers apply {[vehicle _x,currentCommand _x]} )] call _check;
    private _dry=[{_passengers findIf {alive _x && {surfaceIsWater getPosATL _x}} < 0},90] call _wait;
    ["NAVAL-"+_suffix+"-dry-egress",_dismounted && {_dry},str (_passengers apply {getPosATL _x})] call _check;
    private _crewRetained=(crew _boat) findIf {
        private _role=(assignedVehicleRole _x) param [0,""];
        alive _x && {!(_x in _passengers)} && {vehicle _x != _boat} && {toUpperANSI _role != "CARGO"}
    } < 0;
    ["NAVAL-"+_suffix+"-crew-retained",_crewRetained,str (crew _boat)] call _check;
    private _released=[{(_boat getVariable ["Waldo_Cortex_NavalPlan",[]]) isEqualTo []},75] call _wait;
    ["NAVAL-"+_suffix+"-finite-cleanup",_released,str [_boat getVariable ["Waldo_Cortex_NavalPlan",[]],getForcedSpeed _boat]] call _check;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    {deleteVehicle _x} forEach ((crew _boat)+_passengers+[_enemy,_boat]);
    deleteGroup _passengerGroup;
    if (_passengerGroup != _crewGroup) then {deleteGroup _crewGroup};
} forEach [false,true];
