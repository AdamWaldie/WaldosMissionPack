/*
 * Author: WaldoTheWarfighter
 * Tests hearing, report-led investigation and reinforcement with real firing, detection and travel.
 * VR keeps deterministic geometry; terrain worlds rotate every actor, sight screen and rally onto a
 * measured dry sector so sound/report/support movement is exercised over relief and rough ground.
 * Locality/authority: scheduled server audit; fixtures pinned to the server until explicit transfer.
 * Repeat/JIP: disposable groups and objects, public observer labels; caller restores settings.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>, required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQASupport.sqf";
 */
params ["_check","_phase","_wait"];
private _terrainOrigin=[1525,1100,0];
private _terrainHeading=0;
private _terrainReady=worldName == "VR";
private _terrainRelief=0;
if (!_terrainReady) then {
    private _bestScore=-1;
    private _gridStep=(worldSize/9) max 900;
    for "_gridX" from 2 to 7 do {
        for "_gridY" from 2 to 7 do {
            private _candidateOrigin=[_gridX*_gridStep,_gridY*_gridStep,0];
            for "_heading" from 0 to 315 step 45 do {
                private _forward=[sin _heading,cos _heading,0];
                private _right=[cos _heading,-sin _heading,0];
                private _safe=true;
                private _heights=[];
                {
                    private _lane=_x;
                    private _previous=[];
                    private _previousHeight=0;
                    for "_along" from -80 to 220 step 20 do {
                        private _sample=_candidateOrigin vectorAdd (_right vectorMultiply _lane)
                            vectorAdd (_forward vectorMultiply _along);
                        private _height=getTerrainHeightASL _sample;
                        if (surfaceIsWater _sample || {((surfaceNormal _sample) select 2) < 0.55}) then {_safe=false};
                        if (_previous isNotEqualTo []) then {
                            private _grade=abs (_height-_previousHeight)/((_sample distance2D _previous) max 1);
                            if (_grade > 0.75) then {_safe=false};
                        };
                        _heights pushBack _height;
                        _previous=_sample;
                        _previousHeight=_height;
                    };
                } forEach [-100,0,100];
                private _relief=if (_heights isEqualTo []) then {0} else {(selectMax _heights)-(selectMin _heights)};
                if (_safe && {_relief >= 12} && {_relief <= 120} && {_relief > _bestScore}) then {
                    _bestScore=_relief;
                    _terrainOrigin=_candidateOrigin;
                    _terrainHeading=_heading;
                    _terrainRelief=_relief;
                    _terrainReady=true;
                };
            };
        };
    };
};
private _terrainForward=[sin _terrainHeading,cos _terrainHeading,0];
private _terrainRight=[cos _terrainHeading,-sin _terrainHeading,0];
private _terrainPosition={
    params ["_local"];
    _terrainOrigin vectorAdd (_terrainRight vectorMultiply ((_local select 0)-1525))
        vectorAdd (_terrainForward vectorMultiply ((_local select 1)-1100))
};
["SUPPORT-terrain-scenario",_terrainReady,
    format ["world=%1 origin=%2 heading=%3 relief=%4",worldName,_terrainOrigin,_terrainHeading,_terrainRelief]] call _check;
if (!_terrainReady) exitWith {
    ["Support systems: no evaluative terrain","No dry three-lane sector provided 12-120 m relief without unsafe slope or grade. Hearing, report and reinforcement cases are skipped rather than reverting to flat coordinates.",_terrainOrigin] call _phase;
};
private _groups=[];
private _objects=[];
private _newGroup={
    params ["_side"];
    private _group=createGroup [_side,true];
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _group allowFleeing 0;
    _groups pushBack _group;
    _group
};
private _unit={
    params ["_group","_position","_label"];
    private _unit=_group createUnit [["O_Soldier_F","B_Soldier_F"] select (side _group == west),_position,[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",_label,true];
    _unit allowDamage false;
    _objects pushBack _unit;
    _unit
};
private _cleanup={{deleteVehicle _x} forEach _objects; {deleteGroup _x} forEach _groups; _objects=[]; _groups=[]; missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true]};
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
    ["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Regroup_Enable",false],
    ["Waldo_AIPass_Flank_Enable",false],["Waldo_AIPass_Advance_Enable",false],
    ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Stance_Enable",false],
    ["Waldo_AIPass_FireControl_Enable",false],["Waldo_AIPass_Reinforce_Enable",false],
    ["Waldo_AIPass_CoordinatedAssault_Enable",false],["Waldo_AIPass_Artillery_Enable",false],
    ["Waldo_AIPass_ContactReports_Enable",false],["Waldo_AIPass_Hearing_Enable",false],
    ["Waldo_AIPass_Investigate_Enable",false]
]] call Waldo_fnc_CortexTuning;
// Build the sight screen before either opponent exists; scheduled execution can yield during setup.
for "_i" from -2 to 2 do {
    private _wall=createVehicle ["Land_CncWall4_F",[[1600+_i*4,1100,0]] call _terrainPosition,[],0,"CAN_COLLIDE"];
    _wall setDir _terrainHeading;
    _objects pushBack _wall;
};
private _listeners=[east] call _newGroup;
// Keep the listener outside the investigation arrival radius after sound quantization.
private _listener=[_listeners,[[1600,1070,0]] call _terrainPosition,"LISTENER"] call _unit;
// Targeting is disabled to avoid combat orders; the wall below supplies real visual occlusion.
{_listener disableAI _x} forEach ["TARGET","AUTOTARGET"];
private _shooters=[west] call _newGroup;
_shooters setVariable ["Waldo_AIPass_Exclude",true,true];
private _shooter=[_shooters,[[1600,1135,0]] call _terrainPosition,"AUDIBLE SHOT SOURCE"] call _unit;
_shooter setDir _terrainHeading; _shooter disableAI "PATH";


{_x setCombatMode "BLUE"} forEach [_listeners,_shooters];
_shooter addEventHandler ["Fired",{params ["_unit"]; _unit setVariable ["Waldo_CortexQA_ActualShots",(_unit getVariable ["Waldo_CortexQA_ActualShots",0])+1,true]}];
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
["Hearing disabled: actual gunshot","The shooter fires behind a concrete screen on the measured terrain sector. With hearing disabled, the shot must not create a Cortex sound report.",[[1600,1100,0]] call _terrainPosition] call _phase;
["HEARING-fixture-occluded",(lineIntersectsSurfaces [eyePos _listener,eyePos _shooter,_listener,_shooter,true,1,"VIEW","GEOM"]) isNotEqualTo []] call _check;
["HEARING-fixture-no-prior-contact",_listener knowsAbout _shooter < 1,format ["knowledge=%1 phase=%2",_listener targetKnowledge _shooter,(_listeners getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]]] call _check;
_shooter forceWeaponFire [primaryWeapon _shooter,"Single"];
sleep 3;
["HEARING-disabled-real-shot",(_shooter getVariable ["Waldo_CortexQA_ActualShots",0]) > 0] call _check;
["HEARING-disabled-no-report",(_listeners getVariable ["Waldo_AIPass_AreaReport",[]]) isEqualTo []] call _check;
private _shotsBeforeEnable=_shooter getVariable ["Waldo_CortexQA_ActualShots",0];
[createHashMapFromArray [["Waldo_AIPass_Hearing_Enable",true]]] call Waldo_fnc_CortexTuning;
["Hearing: actual gunshot","The forward soldier fires away from the listener. A concrete screen blocks sight; only a real nearby gunshot may create the uncertain report. No target is revealed by the test.",[[1600,1125,0]] call _terrainPosition] call _phase;
["HEARING-handler-ready",[{(_listeners getVariable ["Waldo_AIPass_HearingHandler",[]]) isNotEqualTo []},20] call _wait] call _check;
for "_i" from 1 to 3 do {_shooter forceWeaponFire [primaryWeapon _shooter,"Single"]; sleep 1};
private _heard=[{((_listeners getVariable ["Waldo_AIPass_AreaReport",[]]) param [3,""]) == "SOUND"},5] call _wait;
["HEARING-real-shot",(_shooter getVariable ["Waldo_CortexQA_ActualShots",0]) > _shotsBeforeEnable] call _check;
["HEARING-uncertain-area",_heard,str (_listeners getVariable ["Waldo_AIPass_AreaReport",[]])] call _check;
private _start=getPosATL _listener;
// Hearing intentionally retains an uncertain area, not the hidden firing object.
// Measure the real approach to that area, including the controller's stand-off.
private _soundReport=+(_listeners getVariable ["Waldo_AIPass_AreaReport",[]]);
private _soundArea=_soundReport param [0,[],[[]]];
private _initialRange=if (count _soundArea >= 2) then {_start distance2D _soundArea} else {-1};
private _peakTravel=0;
private _bestRange=_initialRange;
// Audit-only bounded evidence: capture changes, never drive or reveal the listener.
private _soundTrace=[];
private _nextSoundSample=0;
private _lastSoundPhase="";
[createHashMapFromArray [["Waldo_AIPass_Investigate_Enable",true]]] call Waldo_fnc_CortexTuning;
["Sound investigation: physical approach","The listener must physically approach the approximate sound area by at least 15 m over the measured terrain. The controller stops short to investigate; reaching the hidden shooter's exact position is not required. Watch the travel trail and remaining area distance.",[[1600,1125,0]] call _terrainPosition] call _phase;
private _investigated=[{
    private _travel=_listener distance2D _start;
    private _remaining=if (count _soundArea >= 2) then {_listener distance2D _soundArea} else {-1};
    _peakTravel=_peakTravel max _travel;
    _bestRange=_bestRange min _remaining;
    private _state=_listeners getVariable ["Waldo_AIPass_State",createHashMap];
    private _soundPhase=_state getOrDefault ["phase",""];
    if (diag_tickTime >= _nextSoundSample || {_soundPhase != _lastSoundPhase}) then {
        _nextSoundSample=diag_tickTime+2;
        _lastSoundPhase=_soundPhase;
        if (count _soundTrace < 64) then {
            private _report=_listeners getVariable ["Waldo_AIPass_AreaReport",[]];
            _soundTrace pushBack [serverTime,_soundPhase,currentCommand _listener,
                _listener targetKnowledge _shooter,[_listeners] call Waldo_fnc_CortexKnowledge,
                _report,_travel,_remaining,(lineIntersectsSurfaces [eyePos _listener,eyePos _shooter,_listener,_shooter,true,1,"VIEW","GEOM"]) isNotEqualTo [],waypoints _listeners apply {[_x,waypointPosition _x,waypointDescription _x]}];
        };
    };
    _listener setVariable ["Waldo_CortexQA_Label",format ["SOUND INVESTIGATION | travel %1 m | area %2 m | phase %3",round _travel,round _remaining,_state getOrDefault ["phase",""]],true];
    _heard && {_initialRange >= 15} && {_travel >= 15} && {_initialRange-_remaining >= 15} && {_remaining <= 55}
},45] call _wait;
// Separate samples avoid Arma truncating the transition history at its log-line limit.
{diag_log format ["WMP CORTEX QA SOUND TRACE %1 [time,phase,command,engineKnowledge,cortexKnowledge,report,travel,remaining,occluded,waypoints]: %2",_forEachIndex,_x]} forEach _soundTrace;
["INVESTIGATE-sound-physical-approach",_heard && {_investigated},format ["report=%1 origin=%2 final=%3 peakTravel=%4 initialAreaRange=%5 bestAreaRange=%6 phase=%7",_soundReport,_start,getPosATL _listener,_peakTravel,_initialRange,_bestRange,(_listeners getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]]] call _check;
[createHashMapFromArray [["Waldo_AIPass_Hearing_Enable",false],["Waldo_AIPass_Investigate_Enable",false]]] call Waldo_fnc_CortexTuning;
["HEARING-disable-removes-handler",[{(_listeners getVariable ["Waldo_AIPass_HearingHandler",[]]) isEqualTo []},20] call _wait] call _check;
call _cleanup;

[createHashMapFromArray [["Waldo_AIPass_ContactReports_Enable",true],["Waldo_AIPass_Investigate_Enable",true]]] call Waldo_fnc_CortexTuning;
private _sender=[east] call _newGroup;
private _senderUnit=[_sender,[[1600,1100,0]] call _terrainPosition,"REPORTING SQUAD"] call _unit;
_senderUnit disableAI "PATH";
private _receiver=[east] call _newGroup;
private _receiverUnit=[_receiver,[[1450,1100,0]] call _terrainPosition,"REPORT RECEIVER"] call _unit;
// Screen the receiver's initial sightline without obstructing the sender's northward view.
private _screenDirection=([[1450,1100,0]] call _terrainPosition) getDir ([[1600,1190,0]] call _terrainPosition);
for "_i" from -2 to 2 do {
    private _wall=createVehicle ["Land_CncWall4_F",(([[1490,1124,0]] call _terrainPosition) getPos [_i*4,_screenDirection+90]),[],0,"CAN_COLLIDE"];
    _wall setDir _screenDirection;
    _objects pushBack _wall;
};
{_receiverUnit disableAI _x} forEach ["TARGET","AUTOTARGET"];
_shooters=[west] call _newGroup;
_shooters setVariable ["Waldo_AIPass_Exclude",true,true];
_shooter=[_shooters,[[1600,1190,0]] call _terrainPosition,"SIGHTED OPPOSITION"] call _unit;
_shooter disableAI "PATH";
{_x setCombatMode "BLUE"} forEach [_sender,_receiver,_shooters];
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
_start=getPosATL _receiverUnit;
["Contact report and investigation","The reporting squad sees an opponent across the measured terrain. A concrete screen blocks the receiver's initial sightline; it must approach using Cortex's server-to-owner report path.",[[1525,1140,0]] call _terrainPosition] call _phase;
["REPORT-fixture-receiver-occluded",(lineIntersectsSurfaces [eyePos _receiverUnit,eyePos _shooter,_receiverUnit,_shooter,true,1,"VIEW","GEOM"]) isNotEqualTo []] call _check;
["REPORT-fixture-sender-clear",(lineIntersectsSurfaces [eyePos _senderUnit,eyePos _shooter,_senderUnit,_shooter,true,1,"VIEW","GEOM"]) isEqualTo []] call _check;
private _reportSeen=false;
private _travel=[{
    if (((_receiver getVariable ["Waldo_AIPass_AreaReport",[]]) param [3,""]) == "REPORT") then {_reportSeen=true};
    _receiverUnit distance2D _start >= 40 && {_receiverUnit distance2D _shooter < 100}
},75] call _wait;
["REPORT-receiver-physical-investigation",_travel && {_reportSeen || {((_receiver getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["areaInvestigation",""]) == "REPORT"}},format ["travel=%1 directKnowledge=%2",_receiverUnit distance2D _start,_receiverUnit knowsAbout _shooter]] call _check;
["REPORT-observed-delivery",_reportSeen || {((_receiver getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["areaInvestigation",""]) == "REPORT"}] call _check;
call _cleanup;

[createHashMapFromArray [["Waldo_AIPass_ContactReports_Enable",false],["Waldo_AIPass_Investigate_Enable",false],["Waldo_AIPass_Reinforce_Enable",true],["Waldo_AIPass_CoordinatedAssault_Enable",false]]] call Waldo_fnc_CortexTuning;
_sender=[east] call _newGroup;
_senderUnit=[_sender,[[1600,1200,0]] call _terrainPosition,"SQUAD REQUESTING SUPPORT"] call _unit;
_senderUnit disableAI "PATH";
_receiver=[east] call _newGroup;
private _helpers=[];
for "_i" from 0 to 2 do {
    private _helper=[_receiver,[[1500+_i*3,1050,0]] call _terrainPosition,format ["REINFORCEMENT %1",_i+1]] call _unit;
    {_helper disableAI _x} forEach ["TARGET","AUTOTARGET"];
    _helpers pushBack _helper;
};
_shooters=[west] call _newGroup;
_shooters setVariable ["Waldo_AIPass_Exclude",true,true];
_shooter=[_shooters,[[1600,1290,0]] call _terrainPosition,"SUPPORT THREAT"] call _unit;
_shooter disableAI "PATH";
{_x setCombatMode "BLUE"} forEach [_sender,_receiver,_shooters];
missionNamespace setVariable ["Waldo_CortexQA_Actors",+_objects,true];
private _rally=[[1600,1120,0]] call _terrainPosition;
private _helperStarts=_helpers apply {getPosATL _x};
["Reinforcement travel","The three idle helpers must walk to the rally point behind the squad in contact. All three must arrive within 45 m; a reservation or waypoint is insufficient.",_rally] call _phase;
private _assigned=[{
    private _lease=_receiver getVariable ["Waldo_AIPass_SupportLease",[]];
    count _lease >= 4 && {(_lease select 1) == _sender}
        && {((_receiver getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["supportToken",""]) == (_lease select 0)}
},35] call _wait;
["REINFORCE-correct-requester-assignment",_assigned,str (_receiver getVariable ["Waldo_AIPass_SupportLease",[]])] call _check;
private _assignedLease=+(_receiver getVariable ["Waldo_AIPass_SupportLease",[]]);
if (_assigned && {count _assignedLease >= 4}) then {_rally=+(_assignedLease select 3)};
["Reinforcement assigned rally","Follow the actual assigned rally area. Every helper must travel at least 15 m and finish within 45 m of that area; an assignment alone does not pass.",_rally] call _phase;
private _arrived=[{
    _assigned && {_helpers findIf {!alive _x || {_x distance2D _rally > 45} || {_x distance2D (_helperStarts select (_helpers find _x)) < 15}} < 0}
},100] call _wait;
["REINFORCE-physical-rally",_assigned && {_arrived},format ["assignedRally=%1 starts=%2 final=%3 lease=%4",_rally,_helperStarts,_helpers apply {getPosATL _x},_assignedLease]] call _check;
[createHashMapFromArray [["Waldo_AIPass_Reinforce_Enable",false]]] call Waldo_fnc_CortexTuning;
["REINFORCE-disable-clears-assignment",[{(_receiver getVariable ["Waldo_AIPass_SupportLease",[]]) isEqualTo []},30] call _wait] call _check;
["REINFORCE-disable-cleans-order",[{
    (waypoints _receiver) findIf {waypointDescription _x == "WMP AI PASS"} < 0
        && {!((_receiver getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["responding",false])}
},30] call _wait] call _check;
call _cleanup;
