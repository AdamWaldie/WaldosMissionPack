/*
 * Author: WaldoTheWarfighter
 * Tests live turret fire priority, hold-fire obedience and physical AT standoff.
 * Locality/authority: scheduled server audit; all disposable crews are server-owned.
 * Repeat/JIP: fresh vehicles per case; public observer data, events die with deleted actors.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAGunnery.sqf";
 */
params ["_check","_phase","_wait"];
private _savedStandoff=missionNamespace getVariable ["Waldo_AIPass_Vehicles_StandoffDistance",250];
missionNamespace setVariable ["Waldo_AIPass_Vehicles_StandoffDistance",250,true];
private _pin={params ["_group"]; _group setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _group setVariable ["acex_headless_blacklist",true,true]; {_x setVariable ["acex_headless_blacklist",true,true]} forEach units _group};
{
    private _standoffCase=_x;
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],["Waldo_AIPass_LambsMode","WMP"],
        ["Waldo_AIPass_Regroup_Enable",false],["Waldo_AIPass_Flank_Enable",false],["Waldo_AIPass_Advance_Enable",false],
        ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_ContactReports_Enable",false],
        ["Waldo_AIPass_CoordinatedAssault_Enable",false],["Waldo_AIPass_Artillery_Enable",false],
        ["Waldo_AIPass_FireControl_Enable",false],["Waldo_AIPass_Vehicles_Enable",true],
        ["Waldo_AIPass_VehicleWithdraw_Enable",false],["Waldo_AIPass_VehicleDismount_Enable",false],
        ["Waldo_AIPass_VehicleGunnery_Enable",!_standoffCase]
    ]] call Waldo_fnc_CortexTuning;
    private _vehicle=createVehicle ["O_APC_Tracked_02_cannon_F",[1750,1100,0],[],0,"NONE"];
    _vehicle setDir 0; createVehicleCrew _vehicle;
    _vehicle allowDamage false;
    private _crew=crew _vehicle;
    private _group=group driver _vehicle; [_group] call _pin;
    _group setCombatMode "BLUE";
    {_x allowDamage false} forEach _crew;
    private _opposition=createGroup [west,true]; [_opposition] call _pin;
    _opposition setVariable ["Waldo_AIPass_Exclude",true,true]; _opposition setCombatMode "BLUE";
    private _at=_opposition createUnit ["B_Soldier_LAT_F",[[1810,1300,0],[1750,1220,0]] select _standoffCase,[],0,"NONE"];
    private _rifle=_opposition createUnit ["B_Soldier_F",[1700,1240,0],[],0,"NONE"];
    {
        _x allowDamage false;
        _x setDir (_x getDir _vehicle);
        _x doWatch _vehicle;
        _x disableAI "PATH";
        _x setVariable ["acex_headless_blacklist",true,true];
    } forEach [_at,_rifle];
    private _facingErrors=[_at,_rifle] apply {
        abs ((((getDir _x)-(_x getDir _vehicle)+540) % 360)-180)
    };
    [format ["GUNNERY-%1-fixture-facing",["fire","standoff"] select _standoffCase],
        _facingErrors findIf {_x > 15} < 0,format ["heading errors=%1 degrees",_facingErrors]] call _check;
    _at setVariable ["Waldo_CortexQA_Label","AT THREAT: PRIORITY",true];
    _rifle setVariable ["Waldo_CortexQA_Label","NEARER RIFLEMAN",true];
    _vehicle setVariable ["Waldo_CortexQA_Label","GUNNERY APC",true];
    _vehicle setVariable ["Waldo_CortexQA_At",_at];
    _vehicle setVariable ["Waldo_CortexQA_Shots",[],true];
    _vehicle addEventHandler ["Fired",{
        params ["_vehicle","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
        if (isNull _projectile) exitWith {};
        private _target=_vehicle getVariable ["Waldo_CortexQA_At",objNull];
        if (isNull _target) exitWith {};
        private _toward=(getPosASL _projectile) vectorFromTo eyePos _target;
        private _direction=vectorNormalized velocity _projectile;
        private _alignment=(_toward vectorDotProduct _direction) max -1 min 1;
        private _shots=_vehicle getVariable ["Waldo_CortexQA_Shots",[]];
        _shots pushBack [_weapon,acos _alignment,assignedTarget gunner _vehicle == _target,serverTime];
        if (count _shots > 200) then {_shots deleteAt 0};
        _vehicle setVariable ["Waldo_CortexQA_Shots",_shots,true];
    }];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[_vehicle,_at,_rifle],true];
    private _origin=getPosATL _vehicle;
    private _nearest=1e9;
    {_nearest=_nearest min (_vehicle distance2D _x)} forEach (allPlayers select {!(_x isKindOf "HeadlessClient_F")});
    ["GUNNERY-fixture-tactical-range",_nearest <= (missionNamespace getVariable ["Waldo_AIPass_FarRange",2500]),format ["nearest player=%1",_nearest]] call _check;
    ["Gunnery: natural detection","The threat soldiers face the APC. Wait for its crew to detect the AT soldier naturally before measuring firing or retreat. No target knowledge is injected.",_origin] call _phase;
    // Observe real engine detection; never reveal targets or inject contact state.
    private _detected=[{
        ([_group] call Waldo_fnc_CortexKnowledge) params ["_known"];
        _known findIf {(_x select 0) == _at && {(_x select 2) <= 15}} >= 0
    },60] call _wait;
    [format ["GUNNERY-%1-natural-AT-detection",["fire","standoff"] select _standoffCase],_detected,
        str [_crew apply {[_x knowsAbout _at,_x targetKnowledge _at]},getDir _at,getDir _rifle]] call _check;
    if (_standoffCase) then {
        ["Vehicle standoff disabled","An AT soldier stands 120 m north of the APC. With gunnery/standoff disabled the stopped APC must stay here. Both sides hold fire so weapon damage cannot explain any movement.",_origin] call _phase;
        private _maxTravel=0;
        for "_sample" from 1 to 15 do {sleep 1; _maxTravel=_maxTravel max (_vehicle distance2D _origin)};
        ["VEH-standoff-disabled-stationary",_maxTravel < 3,str _maxTravel] call _check;
        private _initialDistance=_vehicle distance2D _at;
        _vehicle setVariable ["Waldo_CortexQA_Standoff",[_at,+_origin,_initialDistance,_detected],true];
        [createHashMapFromArray [["Waldo_AIPass_VehicleGunnery_Enable",true]]] call Waldo_fnc_CortexTuning;
        ["Vehicle AT standoff enabled","The APC must drive away from the AT threat by at least 60 m, with all crew still inside. The cyan trail shows actual travel; a retreat waypoint alone does not pass.",_origin] call _phase;
        private _nextLog=0;
        private _moved=[{
            if (diag_tickTime >= _nextLog) then {
                _nextLog=diag_tickTime+10;
                diag_log format ["WMP CORTEX QA STANDOFF: eligible=%1 zeusHeld=%2 phase=%3 knowledge=%4 capabilities=%5 command=%6 destination=%7 waypoints=%8",
                    [_group] call Waldo_fnc_CortexIsEligible,[_group] call Waldo_fnc_CortexZeusHeld,
                    (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase","NONE"],
                    [_group] call Waldo_fnc_CortexKnowledge,[_at] call Waldo_fnc_CortexCapabilities,
                    currentCommand driver _vehicle,expectedDestination driver _vehicle,
                    waypoints _group apply {[waypointPosition _x,waypointDescription _x]}];
            };
            alive _vehicle && {_vehicle distance2D _origin >= 40} && {_vehicle distance2D _at >= _initialDistance+60}
        },90] call _wait;
        ["VEH-standoff-physical-separation",_moved,format ["travel=%1 threat distance=%2 baseline=%3",_vehicle distance2D _origin,_vehicle distance2D _at,_initialDistance]] call _check;
    } else {
        ["Gunnery hold fire","A nearer rifleman and a farther AT soldier are visible. Cortex gunnery is enabled, but BLUE hold fire must prevent actual shots.",_origin] call _phase;
        sleep 15;
        ["GUNNERY-hold-fire-no-projectiles",(_vehicle getVariable ["Waldo_CortexQA_Shots",[]]) isEqualTo []] call _check;
        _group setCombatMode "RED";
        ["Gunnery threat priority","Watch the turret engage the farther AT soldier despite the nearer rifleman. A pass requires an actual fired projectile aimed within 12 degrees of the AT soldier while that soldier is the assigned target. Targets are invulnerable.",_origin] call _phase;
        private _fired=[{(_vehicle getVariable ["Waldo_CortexQA_Shots",[]]) findIf {(_x select 1) <= 12 && {_x select 2}} >= 0},60] call _wait;
        ["GUNNERY-AT-priority-actual-fire",_fired,str (_vehicle getVariable ["Waldo_CortexQA_Shots",[]])] call _check;
        _group setCombatMode "BLUE";
        sleep 3;
        private _before=count (_vehicle getVariable ["Waldo_CortexQA_Shots",[]]);
        sleep 10;
        ["GUNNERY-hold-fire-stops-projectiles",count (_vehicle getVariable ["Waldo_CortexQA_Shots",[]]) == _before] call _check;
    };
    [format ["VEH-%1-crew-retained",["gunnery","standoff"] select _standoffCase],_crew findIf {!alive _x || {vehicle _x != _vehicle}} < 0] call _check;
    sleep 8;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    {deleteVehicle _x} forEach (_crew+[_vehicle,_at,_rifle]);
    deleteGroup _group; deleteGroup _opposition;
} forEach [false,true];

missionNamespace setVariable ["Waldo_AIPass_Vehicles_StandoffDistance",_savedStandoff,true];
