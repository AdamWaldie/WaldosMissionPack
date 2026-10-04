/*
 * Author: WaldoTheWarfighter
 * Measures two-squad flank and advance against a shared, naturally observed enemy squad.
 * Locality/authority: scheduled server owns disposable fixtures; no behaviour results are injected.
 * On VR the fixture retains its stable flat-range coordinates. On other worlds it performs one
 * bounded pre-case terrain scan and rotates the same fight onto a dry, traversable 360 m corridor
 * with measured relief, cross-slope coverage and no infantry-scale grade above 0.7. The physical
 * drill checks therefore exercise slopes and rough ground without adding terrain polling to
 * production AI.
 * Repeat/JIP: fresh actors per case, public labels and targets for observers; caller restores settings.
 * Arguments: 0: check <CODE>; 1: phase <CODE>; 2: wait <CODE>, required callbacks.
 * Return: Nothing. Current caller: cortexQA/runServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAMultiManoeuvre.sqf";
 */
params ["_check","_phase","_wait"];
private _terrainOrigin=[2200,1100,0];
private _terrainRelief=0;
private _terrainHeading=0;
private _terrainMaximumGrade=0;
private _terrainMinimumNormal=1;
private _terrainScenarioReady=worldName == "VR";
private _terrainWorld={
    params ["_origin","_heading","_localX","_localY"];
    _origin vectorAdd [
        _localX*cos _heading+_localY*sin _heading,
        -_localX*sin _heading+_localY*cos _heading,
        0
    ]
};
if (!_terrainScenarioReady) then {
    private _found=[];
    private _margin=800 min ((worldSize-500)/2);
    private _scanStep=600 max ((worldSize-2*_margin)/5);
    for "_candidateX" from _margin to (worldSize-_margin) step _scanStep do {
        for "_candidateY" from _margin to (worldSize-_margin) step _scanStep do {
            for "_heading" from 0 to 315 step 45 do {
                if (_found isEqualTo []) then {
                    private _heights=[];
                    private _usable=true;
                    private _maximumGrade=0;
                    private _minimumNormal=1;
                    {
                        private _lateral=_x;
                        private _previousHeight=-1e9;
                        for "_along" from 0 to 360 step 30 do {
                            private _sample=[[_candidateX,_candidateY,0],_heading,_lateral,_along] call _terrainWorld;
                            private _normal=(surfaceNormal _sample) select 2;
                            if (surfaceIsWater _sample || {_normal < 0.55}) exitWith {_usable=false};
                            private _height=getTerrainHeightASL _sample;
                            if (_previousHeight > -1e8) then {
                                private _grade=abs (_height-_previousHeight)/30;
                                _maximumGrade=_maximumGrade max _grade;
                                if (_grade > 0.7) then {_usable=false};
                            };
                            _minimumNormal=_minimumNormal min _normal;
                            _previousHeight=_height;
                            _heights pushBack _height;
                        };
                    } forEach [-80,0,80,160];
                    if (_usable && {_heights isNotEqualTo []}) then {
                        private _relief=(selectMax _heights)-(selectMin _heights);
                        if (_relief >= 15 && {_relief <= 120}) then {
                            _found=[_candidateX,_candidateY,0];
                            _terrainHeading=_heading;
                            _terrainRelief=_relief;
                            _terrainMaximumGrade=_maximumGrade;
                            _terrainMinimumNormal=_minimumNormal;
                        };
                    };
                };
            };
        };
    };
    if (_found isNotEqualTo []) then {_terrainOrigin=_found; _terrainScenarioReady=true};
};
private _terrainPosition={
    params ["_x","_y"];
    [_terrainOrigin,_terrainHeading,_x-2200,_y-1100] call _terrainWorld
};
{
    private _mode=_x;
    private _prefix="MULTI-"+_mode;
    [_prefix+"-terrain-scenario",_terrainScenarioReady,
        str [worldName,_terrainOrigin,_terrainHeading,_terrainRelief,_terrainMaximumGrade,_terrainMinimumNormal]] call _check;
    private _savedNearRange=missionNamespace getVariable ["Waldo_AIPass_NearRange",900];
    private _savedFarRange=missionNamespace getVariable ["Waldo_AIPass_FarRange",2500];
    missionNamespace setVariable ["Waldo_AIPass_NearRange",5000];
    missionNamespace setVariable ["Waldo_AIPass_FarRange",5000];
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
            private _unit=_group createUnit ["O_Soldier_F",[2200+_team*100+_index*3,1100] call _terrainPosition,[],0,"NONE"];
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
        _groups pushBack _group;
        _teams pushBack _members;
        _actors append _members;
    };
    private _enemyGroup=createGroup [west,true];
    _enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    _enemyGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _enemyGroup setVariable ["acex_headless_blacklist",true,true];
    _enemyGroup setCombatMode "YELLOW";
    _enemyGroup allowFleeing 0;
    private _enemies=[];
    for "_index" from 0 to 5 do {
        private _enemy=_enemyGroup createUnit ["B_Soldier_F",[2215+_index*14,1360] call _terrainPosition,[],0,"NONE"];
        _enemy allowDamage false; _enemy disableAI "PATH"; _enemy setDir 180; _enemy setUnitPos "UP";
        _enemy setVariable ["Waldo_CortexQA_Label",format ["SHARED ENEMY %1",_index+1],true];
        _enemies pushBack _enemy;
    };
    private _enemy=_enemies select 2;
    private _origins=_actors apply {getPosATL _x};
    private _peaks=_actors apply {0};
    private _lastShots=[0,0];
    private _coverEvents=[0,0];
    private _lastMover=-1;
    private _switches=0;
    private _fireLaneCrossings=[0,0];
    private _drillSeen=[false,false];
    private _expectedDrill=["FLANK","ADVANCE"] select (_mode == "BOUND");
    missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors+_enemies,true];
    [_prefix+": two squads","Both squads must physically manoeuvre against the same enemy, retain their members and finish cohesive. Cyan trails show travel. Moving/covering counts and actual shots show whether one squad supports the other; accepted drill flags do not pass.",[2250,1200] call _terrainPosition] call _phase;
    // Direction is established without revealing the target. setDir gives every actor a genuine
    // visual-acquisition opportunity before doWatch starts tracking; doWatch alone can leave a
    // stationary formation facing its spawn bearing. Both sides remain armed, invulnerable and
    // free to exchange fire so the prerequisite is still a real engine engagement.
    {_x setDir (_x getDir _enemy); _x doWatch (getPosATL _enemy)} forEach _actors;
    {
        private _opponent=leader (_groups select (_forEachIndex mod 2));
        _x setDir (_x getDir _opponent);
        _x doWatch (getPosATL _opponent);
    } forEach _enemies;
    private _contact=[{
        private _allContact=true;
        {
            private _leader=leader _x;
            if ((_enemies findIf {_leader knowsAbout _x >= 1}) < 0) then {_allContact=false};
        } forEach _groups;
        _allContact
    },60] call _wait;
    [_prefix+"-natural-contact",_contact,str (_groups apply {private _leader=leader _x; [_leader getDir _enemy,_enemies apply {_leader knowsAbout _x}]})] call _check;
    // The advance prerequisite must exist when Cortex evaluates it. Issuing this objective before
    // visual contact let native combat consume or complete it during the contact-delay window,
    // turning the test into an expired-waypoint check instead of a bounding-advance check.
    if (_contact && {_mode == "BOUND"}) then {
        {
            private _wp=_x addWaypoint [[2200+_forEachIndex*100,1460] call _terrainPosition,0];
            _wp setWaypointType "MOVE";
        } forEach _groups;
    };
    private _until=diag_tickTime+([0,180] select _contact);
    while {diag_tickTime < _until} do {
        private _movingCounts=[];
        private _shotDeltas=[];
        private _drillActive=[];
        {
            private _teamIndex=_forEachIndex;
            private _state=(_groups select _teamIndex) getVariable ["Waldo_AIPass_State",createHashMap];
            private _drill=_state getOrDefault ["drill",createHashMap];
            private _ownsDrill=(_drill getOrDefault ["type",""]) == _expectedDrill;
            if (_ownsDrill) then {_drillSeen set [_teamIndex,true]};
            _drillActive pushBack _ownsDrill;
            private _moving={abs speed _x > 2} count _x;
            private _shots=0;
            {
                private _index=_teamIndex*6+_forEachIndex;
                private _travel=_x distance2D (_origins select _index);
                if (_ownsDrill) then {_peaks set [_index,(_peaks select _index) max _travel]};
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
            if ((_drillActive select _teamIndex) && {(_movingCounts select _teamIndex) >= 2} && {(_movingCounts select _other) <= 1} && {(_shotDeltas select _other) > 0}) then {
                _coverEvents set [_other,(_coverEvents select _other)+1];
                if (_lastMover >= 0 && {_lastMover != _teamIndex}) then {_switches=_switches+1};
                _lastMover=_teamIndex;
                private _supportMembers=(_teams select _other) select {alive _x};
                if (_supportMembers isNotEqualTo []) then {
                    private _support=[0,0,0];
                    {_support=_support vectorAdd getPosATL _x} forEach _supportMembers;
                    _support=_support vectorMultiply (1/count _supportMembers);
                    private _laneX=(getPosATL _enemy select 0)-(_support select 0);
                    private _laneY=(getPosATL _enemy select 1)-(_support select 1);
                    private _laneLength=sqrt (_laneX*_laneX+_laneY*_laneY);
                    if (_laneLength > 40) then {
                        private _crossing=(_teams select _teamIndex) findIf {
                            private _position=getPosATL _x;
                            private _pointX=(_position select 0)-(_support select 0);
                            private _pointY=(_position select 1)-(_support select 1);
                            private _along=(_pointX*_laneX+_pointY*_laneY)/_laneLength;
                            private _lateral=abs (_pointX*_laneY-_pointY*_laneX)/_laneLength;
                            _along > 20 && {_along < _laneLength-25} && {_lateral < 18}
                        };
                        if (_crossing >= 0) then {_fireLaneCrossings set [_teamIndex,(_fireLaneCrossings select _teamIndex)+1]};
                    };
                };
            };
        };
        // End promptly after both real drills have published a terminal result. Ordinary
        // post-drill waypoint movement must not accumulate more Cortex evidence.
        if ((_drillSeen findIf {!_x}) < 0 && {(_groups findIf {
            private _state=_x getVariable ["Waldo_AIPass_State",createHashMap];
            count (_state getOrDefault ["drill",createHashMap]) > 0
        }) < 0}) then {_until=0};
        sleep 2;
    };
    [_prefix+"-both-tactical-drills-observed",(_drillSeen findIf {!_x}) < 0,str [_expectedDrill,_drillSeen]] call _check;
    {
        private _teamIndex=_forEachIndex;
        private _members=_x;
        private _group=_groups select _teamIndex;
        private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
        private _drill=_state getOrDefault ["drill",createHashMap];
        diag_log format ["WMP CORTEX QA MULTI END: case=%1 team=%2 phase=%3 drillType=%4 stage=%5 bound=%6/%7 result=%8 failure=%9 flankRefusal=%10 advanceRefusal=%11",
            _prefix,_teamIndex+1,_state getOrDefault ["phase","NONE"],_drill getOrDefault ["type","NONE"],
            _drill getOrDefault ["stage","NONE"],_drill getOrDefault ["index",-1],count (_drill getOrDefault ["points",[]]),
            _group getVariable ["Waldo_Cortex_DrillResult",[]],_group getVariable ["Waldo_Cortex_DrillFailure",[]],
            _group getVariable ["Waldo_Cortex_FlankRefusal",[]],_group getVariable ["Waldo_Cortex_AdvanceRefusal",[]]];
        [_prefix+format ["-squad-%1-physical-travel",_teamIndex+1],_contact && {_drillSeen select _teamIndex} && {(_peaks select [_teamIndex*6,6]) findIf {_x < 30} < 0},str (_peaks select [_teamIndex*6,6])] call _check;
        [_prefix+format ["-squad-%1-cohesion",_teamIndex+1],_members findIf {!alive _x || {group _x != _group} || {_x distance2D leader _group > 40}} < 0] call _check;
        [_prefix+format ["-squad-%1-covering-fire",_teamIndex+1],(_drillSeen select _teamIndex) && {(_coverEvents select _teamIndex) > 0},str _coverEvents] call _check;
        if (_mode == "FLANK") then {
            [_prefix+format ["-squad-%1-no-support-fire-lane-crossing",_teamIndex+1],(_drillSeen select _teamIndex) && {(_fireLaneCrossings select _teamIndex) == 0},str _fireLaneCrossings] call _check;
        };
    } forEach _teams;
    if (_mode == "BOUND") then {[_prefix+"-observed-movement-fire-overlap",(_drillSeen findIf {!_x}) < 0 && {_switches >= 2},str [_switches,_coverEvents,_drillSeen]] call _check};
    {deleteVehicle _x} forEach (_actors+_enemies);
    {deleteGroup _x} forEach (_groups+[_enemyGroup]);
    missionNamespace setVariable ["Waldo_AIPass_NearRange",_savedNearRange];
    missionNamespace setVariable ["Waldo_AIPass_FarRange",_savedFarRange];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
} forEach ["FLANK","BOUND"];
