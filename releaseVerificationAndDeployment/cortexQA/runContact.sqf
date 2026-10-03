/*
 * Author: WaldoTheWarfighter
 * Tests real occlusion, physical exposure, sight loss, post-contact flow and reacquisition without
 * injected knowledge, including live contact interrupting an active search.
 * Locality/authority: scheduled server audit; both fixture groups pinned against HC distributors.
 * Repeat/JIP: fresh actors and walls; public visual targets; removes only its own fixtures.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAContact.sqf";
 */
params ["_check","_phase","_wait"];
[createHashMapFromArray [
    ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
    ["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Regroup_Enable",false],
    ["Waldo_AIPass_Flank_Enable",false],["Waldo_AIPass_Advance_Enable",false],
    ["Waldo_AIPass_FireControl_Enable",false],["Waldo_AIPass_Morale_Enable",false],
    ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_ContactReports_Enable",false],
    ["Waldo_AIPass_Artillery_Enable",false],["Waldo_AIPass_CoordinatedAssault_Enable",false]
]] call Waldo_fnc_CortexTuning;
private _group=createGroup [east,true];
private _opposition=createGroup [west,true];
{
    _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _x setVariable ["acex_headless_blacklist",true,true];
    _x setCombatMode "BLUE";
} forEach [_group,_opposition];
_opposition setVariable ["Waldo_AIPass_Exclude",true,true];
private _walls=[];
for "_i" from -4 to 4 do {
    private _wall=createVehicle ["Land_CncWall4_F",[2000+_i*4,1450,0],[],0,"CAN_COLLIDE"];
    _wall setDir 0;
    _walls pushBack _wall;
};
private _units=[];
for "_i" from 0 to 1 do {
    private _unit=_group createUnit ["O_Soldier_F",[1998+_i*4,1350,0],[],0,"NONE"];
    _unit setDir 0;
    _unit disableAI "PATH";
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["OBSERVER %1",_i+1],true];
    _units pushBack _unit;
};
private _enemy=_opposition createUnit ["B_Soldier_F",[2000,1470,0],[],0,"NONE"];
_enemy setDir 180;
_enemy setVariable ["acex_headless_blacklist",true,true];
_enemy setVariable ["Waldo_CortexQA_Label","HIDDEN ENEMY: MUST WALK INTO VIEW",true];
_enemy disableAI "PATH";
missionNamespace setVariable ["Waldo_CortexQA_Actors",_units+[_enemy],true];
["Contact: hidden enemy","The two observers face the concrete screen. The enemy behind it must remain unknown. This checks real sight rays and engine knowledge; no reveal command is used.",[2000,1400,0]] call _phase;
private _blocked=_units findIf {
    private _rays=lineIntersectsSurfaces [eyePos _x,eyePos _enemy,_x,_enemy,true,-1,"VIEW","GEOM"];
    _rays findIf {(_x select 2) in _walls || {(_x select 3) in _walls}} < 0
} < 0;
["CONTACT-fixture-occlusion",_blocked] call _check;
private _hidden=true;
for "_i" from 1 to 15 do {
    sleep 1;
    if ((([_group] call Waldo_fnc_CortexKnowledge) select 0) findIf {(_x select 0) == _enemy} >= 0) then {_hidden=false};
};
["CONTACT-no-hidden-acquisition",_blocked && {_hidden},str (_units apply {_x knowsAbout _enemy})] call _check;
["Contact: physical exposure","Watch the enemy walk around the screen to the yellow destination. Observers must naturally detect him there. The cyan trace is actual travel; setting a contact flag cannot pass this stage.",[2000,1420,0]] call _phase;
private _destination=[2040,1450,0];
_enemy setVariable ["Waldo_CortexQA_Target",_destination,true];
_enemy enableAI "PATH";
_enemy doMove _destination;
private _arrived=[{alive _enemy && {_enemy distance2D _destination < 3}},65] call _wait;
["CONTACT-enemy-physical-exposure",_arrived,str getPosATL _enemy] call _check;
private _detected=[{
    private _knowledge=([_group] call Waldo_fnc_CortexKnowledge) select 0;
    _knowledge findIf {(_x select 0) == _enemy && {(_x select 2) <= 5}} >= 0
},45] call _wait;
["CONTACT-natural-visible-acquisition",_arrived && {_detected},str (_units apply {_x targetKnowledge _enemy})] call _check;
["CONTACT-live-contact-phase",_detected && {[{((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT"},15] call _wait}] call _check;
// Losing sight must age knowledge rather than continuously refreshing a hidden target.
private _hiddenDestination=[2000,1470,0];
["Contact: lose visual contact","The same enemy walks back behind the concrete screen. Watch the cyan travel and remaining distance. Once every observer's sight line is blocked, the last-seen age must increase; remembered contact is allowed, fresh hidden sight is not.",[2000,1450,0]] call _phase;
_enemy setVariable ["Waldo_CortexQA_Target",_hiddenDestination,true];
_enemy doMove _hiddenDestination;
private _hiddenArrival=[{_enemy distance2D _hiddenDestination < 3},65] call _wait;
private _hiddenAgain=_units findIf {
    private _rays=lineIntersectsSurfaces [eyePos _x,eyePos _enemy,_x,_enemy,true,-1,"VIEW","GEOM"];
    _rays findIf {(_x select 2) in _walls || {(_x select 3) in _walls}} < 0
} < 0;
["CONTACT-reocclusion-physical-prerequisite",_hiddenArrival && {_hiddenAgain},str getPosATL _enemy] call _check;
sleep 12;
private _remembered=([_group] call Waldo_fnc_CortexKnowledge) select 0;
["CONTACT-hidden-sighting-ages",_detected && {_hiddenArrival} && {_hiddenAgain} && {_remembered findIf {(_x select 0) == _enemy && {(_x select 2) <= 5}} < 0},str (_units apply {_x targetKnowledge _enemy})] call _check;
["Contact: reacquire the same enemy","The enemy walks out again. Without reveal, a forced contact flag or new actors, the observers must produce a fresh natural sighting. This checks the full visible-hidden-visible transition.",[2020,1450,0]] call _phase;
_enemy setVariable ["Waldo_CortexQA_Target",_destination,true];
_enemy doMove _destination;
private _returned=[{_enemy distance2D _destination < 3},65] call _wait;
private _reacquired=[{(([_group] call Waldo_fnc_CortexKnowledge) select 0) findIf {(_x select 0) == _enemy && {(_x select 2) <= 5}} >= 0},45] call _wait;
["CONTACT-natural-reacquisition",_hiddenArrival && {_hiddenAgain} && {_returned} && {_reacquired},str (_units apply {_x targetKnowledge _enemy})] call _check;
// Add physical lifecycle acceptance after the original sight-loss comparisons.
// Remove the stimulus, not Cortex state. Release fixture-only observer path locks.
[createHashMapFromArray [["Waldo_AIPass_PostContact_Enable",true]]] call Waldo_fnc_CortexTuning;
private _contactBeforeRemoval=((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT";
private _lastPosition=getPosATL _enemy;
deleteVehicle _enemy;
{_x enableAI "PATH"; _x setVariable ["Waldo_CortexQA_Target",_lastPosition,true]} forEach _units;
private _sequence=[];
private _transitionSamples=[];
private _searchStart=createHashMap;
private _searchTravel=0;
private _searchApproach=false;
private _lastPhase="";
private _searchInterrupted=false;
private _searchReleased=false;
private _interruptEnemy=objNull;
private _interruptSpawned=false;
["Transitions: contact lost","The enemy is removed. The same soldiers must hold, physically search the last sighting, rejoin and return to calm. No state is assigned by this test; yellow destinations and cyan trails show real movement.",_lastPosition] call _phase;
private _calm=[{
    private _state=_group getVariable ["Waldo_AIPass_State",createHashMap];
    private _current=_state getOrDefault ["phase","UNMANAGED"];
    if (_current != _lastPhase) then {
        _lastPhase=_current;
        _sequence pushBack _current;
        private _sample=[serverTime,_current,_units apply {[netId _x,getPosATL _x,currentCommand _x]}];
        _transitionSamples pushBack _sample;
        diag_log format ["WMP CORTEX QA TRANSITION: %1",_sample];
        {_x setVariable ["Waldo_CortexQA_Label",format ["TRANSITION %1 | %2",_current,_forEachIndex+1],true]} forEach _units;
        ["Transitions: "+_current,"Watch the current action and actual travel. Search must approach the former contact; regroup must close the squad. A phase name alone cannot pass.",getPosATL leader _group] call _phase;
    };
    if (_current == "SEARCH") then {
        {
            private _key=netId _x;
            if !(_key in _searchStart) then {_searchStart set [_key,getPosATL _x]};
            _searchTravel=_searchTravel max (_x distance2D (_searchStart get _key));
            if (_x distance2D _lastPosition < 20) then {_searchApproach=true};
        } forEach (_state getOrDefault ["searchTeam",[]]);
        // Reacquire a real visible opponent during the first search. This must interrupt the
        // search through production sensing; no reveal, phase write or direct callback is used.
        if (!_interruptSpawned && {_searchTravel >= 5}) then {
            _interruptEnemy=_opposition createUnit ["B_Soldier_F",_lastPosition getPos [12,90],[],0,"NONE"];
            _interruptEnemy setDir (_interruptEnemy getDir leader _group);
            _interruptEnemy disableAI "PATH";
            _interruptEnemy setVariable ["acex_headless_blacklist",true,true];
            _interruptEnemy setVariable ["Waldo_CortexQA_Label","SEARCH INTERRUPTION: NATURAL CONTACT",true];
            _interruptSpawned=true;
            missionNamespace setVariable ["Waldo_CortexQA_Actors",_units+[_interruptEnemy],true];
            ["Transitions: search interrupted by contact","A real opponent has appeared while the search team is moving. Cortex must release the old search movement, return to CONTACT and later complete a fresh post-contact cycle.",getPosATL _interruptEnemy] call _phase;
        };
    };
    if (_interruptSpawned && {!_searchInterrupted} && {_current == "CONTACT"}) then {
        _searchInterrupted=true;
        _searchReleased=(_state getOrDefault ["searchTeam",[]]) isEqualTo [];
        deleteVehicle _interruptEnemy;
        _interruptEnemy=objNull;
        missionNamespace setVariable ["Waldo_CortexQA_Actors",_units,true];
    };
    _current == "CALM" && {_searchInterrupted} && {"REGROUP" in _sequence}
},180] call _wait;
private _orderedSequence=(["SECURITY","SEARCH","REGROUP","CALM"] findIf {!(_x in _sequence)}) < 0
    && {(_sequence find "SECURITY") < (_sequence find "SEARCH")}
    && {(_sequence find "SEARCH") < (_sequence find "REGROUP")}
    && {(_sequence find "REGROUP") < (_sequence find "CALM")};
["TRANS-contact-postcontact-sequence",_contactBeforeRemoval && {_orderedSequence} && {_calm},str _sequence] call _check;
private _phaseHistory=_group getVariable ["Waldo_Cortex_PhaseTransitions",[]];
private _publishedPhases=_phaseHistory apply {_x param [2,""]};
private _publishedOrder=("SECURITY" in _publishedPhases) && {"SEARCH" in _publishedPhases}
    && {"REGROUP" in _publishedPhases} && {"CALM" in _publishedPhases}
    && {(_publishedPhases find "SECURITY") < (_publishedPhases find "SEARCH")}
    && {(_publishedPhases find "SEARCH") < (_publishedPhases find "REGROUP")}
    && {(_publishedPhases find "REGROUP") < (_publishedPhases find "CALM")};
private _latestPhase=_group getVariable ["Waldo_Cortex_PhaseTransition",[]];
["TRANS-published-phase-ledger",_calm && {_publishedOrder} && {count _phaseHistory <= 32}
    && {(_latestPhase param [2,""]) == "CALM"},str _phaseHistory] call _check;
private _searchContactTransition=_phaseHistory findIf {
    (_x param [1,""]) == "SEARCH" && {(_x param [2,""]) == "CONTACT"}
        && {(_x param [3,""]) == "VISIBLE_CONTACT"}
};
["TRANS-search-contact-interruption",_searchInterrupted && {_searchReleased}
    && {_searchContactTransition >= 0},str [_searchReleased,_phaseHistory]] call _check;
["TRANS-search-physical-approach",_searchTravel >= 15 && {_searchApproach},str [_searchTravel,_searchApproach,_transitionSamples]] call _check;
["TRANS-regroup-physical-cohesion",_calm && {_units findIf {!alive _x || {_x distance2D leader _group > 20}} < 0},str (_units apply {getPosATL _x})] call _check;
private _resumeDestination=(getPosATL leader _group) getPos [70,90];
private _resumeStart=_units apply {getPosATL _x};
private _resumeWP=_group addWaypoint [_resumeDestination,0];
_resumeWP setWaypointType "MOVE";
_resumeWP setWaypointCompletionRadius 4;
_group setCurrentWaypoint _resumeWP;
{_x setVariable ["Waldo_CortexQA_Target",_resumeDestination,true]} forEach _units;
["Transitions: fresh orders after calm","Both soldiers must now physically walk to the new waypoint. No posture, behaviour or Cortex state reset is supplied; lingering search or regroup orders must not pull them back.",_resumeDestination] call _phase;
private _resumed=[{_units findIf {!alive _x || {_x distance2D _resumeDestination > 12} || {_x distance2D (_resumeStart select (_units find _x)) < 30}} < 0},90] call _wait;
["TRANS-calm-new-orders-physical-arrival",_calm && {_resumed},str (_units apply {getPosATL _x})] call _check;
private _heldDestination=_resumed;
private _largestReturnDistance=0;
for "_sample" from 1 to 15 do {
    sleep 1;
    {
        _largestReturnDistance=_largestReturnDistance max (_x distance2D _resumeDestination);
        if (!alive _x || {_x distance2D _resumeDestination > 15}) then {_heldDestination=false};
    } forEach _units;
};
["TRANS-no-old-search-order-resurrection",_heldDestination,format ["maximumDistance=%1",_largestReturnDistance]] call _check;

sleep 8;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_units+[_enemy]+_walls);
deleteGroup _group; deleteGroup _opposition;
