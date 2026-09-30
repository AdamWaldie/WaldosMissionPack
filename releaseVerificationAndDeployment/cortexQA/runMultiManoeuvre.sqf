/*
 * Author: WaldoTheWarfighter
 * Measures two-squad flank and advance against a shared, naturally observed enemy.
 * Locality/authority: scheduled server owns disposable fixtures; no behaviour results are injected.
 * Repeat/JIP: fresh actors per case, public labels and targets for observers; caller restores settings.
 * Arguments: 0: check <CODE>; 1: phase <CODE>; 2: wait <CODE>, required callbacks.
 * Return: Nothing. Current caller: cortexQA/runServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAMultiManoeuvre.sqf";
 */
params ["_check","_phase","_wait"];
{
    private _mode=_x;
    private _prefix="MULTI-"+_mode;
    // Independent-drill baseline: mutual timing is observed, not a coordination claim.
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Flank_Enable",_mode == "FLANK"],
        ["Waldo_AIPass_Advance_Enable",_mode == "BOUND"],["Waldo_AIPass_Aggression",2],
        ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Regroup_Enable",false],
        ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_CoordinatedAssault_Enable",false],
        ["Waldo_AIPass_Artillery_Enable",false],["Waldo_AIPass_FireControl_Enable",true]
    ]] call Waldo_fnc_CortexTuning;
    private _groups=[];
    private _teams=[];
    private _actors=[];
    for "_team" from 0 to 1 do {
        private _group=createGroup [east,true];
        _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _group setVariable ["acex_headless_blacklist",true,true];
        _group setVariable ["Waldo_AIPass_Profile","ELITE",true];
        _group setCombatMode "YELLOW";
        _group allowFleeing 0;
        private _members=[];
        for "_index" from 0 to 5 do {
            private _unit=_group createUnit ["O_Soldier_F",[2200+_team*100+_index*3,1100,0],[],0,"NONE"];
            _unit setVariable ["acex_headless_blacklist",true,true];
            _unit setDir 0;
            _unit allowDamage false;
            _unit setVariable ["Waldo_CortexQA_MultiShots",0];
            _unit addEventHandler ["FiredMan",{
                params ["_unit","_weapon"];
                if !(_weapon in ["Throw","Put"]) then {_unit setVariable ["Waldo_CortexQA_MultiShots",(_unit getVariable ["Waldo_CortexQA_MultiShots",0])+1]};
            }];
            _members pushBack _unit;
        };
        if (_mode == "BOUND") then {
            private _wp=_group addWaypoint [[2250,1310,0],0];
            _wp setWaypointType "MOVE";
        };
        _groups pushBack _group;
        _teams pushBack _members;
        _actors append _members;
    };
    private _enemyGroup=createGroup [west,true];
    _enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    _enemyGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _enemyGroup setVariable ["acex_headless_blacklist",true,true];
    _enemyGroup setCombatMode "BLUE";
    private _enemy=_enemyGroup createUnit ["B_Soldier_F",[2250,1360,0],[],0,"NONE"];
    _enemy allowDamage false; _enemy disableAI "PATH"; _enemy setDir 180;
    _enemy setVariable ["Waldo_CortexQA_Label","SHARED ENEMY OBJECTIVE",true];
    private _origins=_actors apply {getPosATL _x};
    private _peaks=_actors apply {0};
    private _lastShots=[0,0];
    private _coverEvents=[0,0];
    private _lastMover=-1;
    private _switches=0;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors+[_enemy],true];
    [_prefix+": two squads","Both squads must physically manoeuvre against the same enemy, retain their members and finish cohesive. Cyan trails show travel. Moving/covering counts and actual shots show whether one squad supports the other; accepted drill flags do not pass.",[2250,1200,0]] call _phase;
    private _contact=[{_groups findIf {leader _x knowsAbout _enemy <= 1} < 0},40] call _wait;
    [_prefix+"-natural-contact",_contact] call _check;
    private _until=diag_tickTime+180;
    while {diag_tickTime < _until} do {
        private _movingCounts=[];
        private _shotDeltas=[];
        {
            private _teamIndex=_forEachIndex;
            private _moving={abs speed _x > 2} count _x;
            private _shots=0;
            {
                private _index=_teamIndex*6+_forEachIndex;
                private _travel=_x distance2D (_origins select _index);
                _peaks set [_index,(_peaks select _index) max _travel];
                _shots=_shots+(_x getVariable ["Waldo_CortexQA_MultiShots",0]);
                _x setVariable ["Waldo_CortexQA_Label",format ["%1 squad %2 | travel %3 m | moving %4/6 | shots %5",_mode,_teamIndex+1,round _travel,_moving,_x getVariable ["Waldo_CortexQA_MultiShots",0]],true];
                _x setVariable ["Waldo_CortexQA_Target",getPosATL _enemy,true];
            } forEach _x;
            _movingCounts pushBack _moving;
            _shotDeltas pushBack (_shots-(_lastShots select _teamIndex));
            _lastShots set [_teamIndex,_shots];
        } forEach _teams;
        for "_teamIndex" from 0 to 1 do {
            private _other=1-_teamIndex;
            if ((_movingCounts select _teamIndex) >= 3 && {(_movingCounts select _other) <= 1} && {(_shotDeltas select _other) > 0}) then {
                _coverEvents set [_other,(_coverEvents select _other)+1];
                if (_lastMover >= 0 && {_lastMover != _teamIndex}) then {_switches=_switches+1};
                _lastMover=_teamIndex;
            };
        };
        sleep 2;
    };
    {
        private _teamIndex=_forEachIndex;
        private _members=_x;
        private _group=_groups select _teamIndex;
        private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
        private _drill=_state getOrDefault ["drill",createHashMap];
        diag_log format ["WMP CORTEX QA MULTI END: case=%1 team=%2 phase=%3 drillType=%4 stage=%5 bound=%6/%7 result=%8 failure=%9",
            _prefix,_teamIndex+1,_state getOrDefault ["phase","NONE"],_drill getOrDefault ["type","NONE"],
            _drill getOrDefault ["stage","NONE"],_drill getOrDefault ["index",-1],count (_drill getOrDefault ["points",[]]),
            _group getVariable ["Waldo_Cortex_DrillResult",[]],_group getVariable ["Waldo_Cortex_DrillFailure",[]]];
        [_prefix+format ["-squad-%1-physical-travel",_teamIndex+1],_contact && {(_peaks select [_teamIndex*6,6]) findIf {_x < 30} < 0},str (_peaks select [_teamIndex*6,6])] call _check;
        [_prefix+format ["-squad-%1-cohesion",_teamIndex+1],_members findIf {!alive _x || {group _x != _group} || {_x distance2D leader _group > 40}} < 0] call _check;
        [_prefix+format ["-squad-%1-covering-fire",_teamIndex+1],(_coverEvents select _teamIndex) > 0,str _coverEvents] call _check;
    } forEach _teams;
    if (_mode == "BOUND") then {[_prefix+"-observed-movement-fire-overlap",_switches >= 2,str [_switches,_coverEvents]] call _check};
    {deleteVehicle _x} forEach (_actors+[_enemy]);
    {deleteGroup _x} forEach (_groups+[_enemyGroup]);
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
} forEach ["FLANK","BOUND"];
