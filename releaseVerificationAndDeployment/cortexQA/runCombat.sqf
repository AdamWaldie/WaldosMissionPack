/*
 * Author: WaldoTheWarfighter
 * Exercises automatic flank/assault and waypoint advance with real opposing soldiers.
 * Locality/authority: scheduled dedicated server; fixtures pinned against both HC distributors.
 * Repeat/JIP: caller owns settings restoration; fresh fixtures and handlers removed after each case.
 * Arguments: check, phase, wait <CODE> callbacks from runServer; no defaults.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQACombat.sqf";
 */
params ["_check","_phase","_wait"];
private _cases = ["FLANK-NATIVE-FIRE","FLANK-YELLOW-NATIVE-FIRE","FLANK-YELLOW","FLANK-AWARE","ADVANCE-AWARE","FLANK","ADVANCE","ADVANCE-YELLOW","ADVANCE-CLOSE","ADVANCE-DISTANT","FLANK-ZEUS","ADVANCE-ZEUS","FLANK-ZEUS-ROE","FLANK-BLOCKED","ADVANCE-BLOCKED","FLANK-GRENADE","FLANK-ZEUS-CONSOLIDATE","ADVANCE-GRENADE"];
private _selected = missionNamespace getVariable ["Waldo_CortexQA_CombatCase",""];
if (_selected != "" && {!(_selected in _cases)}) exitWith {["COMBAT-invalid-case",false,_selected] call _check};
if (_selected != "") then {_cases = [_selected]};
diag_log format ["WMP CORTEX QA COMBAT SCOPE: %1",_cases];
{
    private _case = _x;
    private _blockage = _case in ["FLANK-BLOCKED","ADVANCE-BLOCKED"];
    private _handover = _case in ["FLANK-ZEUS","ADVANCE-ZEUS","FLANK-ZEUS-ROE","FLANK-ZEUS-CONSOLIDATE"];
    private _mode = if ((_case find "FLANK") == 0) then {"FLANK"} else {"ADVANCE"};
    private _enemyPosition = [1200,switch (_case) do {case "ADVANCE-YELLOW": {1450}; case "ADVANCE-AWARE": {1450}; case "ADVANCE-BLOCKED": {1450}; case "ADVANCE-ZEUS": {1450}; case "ADVANCE": {1450}; case "ADVANCE-DISTANT": {1550}; default {1350}},0];
    private _advance = _mode == "ADVANCE";
    private _group = createGroup [east,true];
    private _enemyGroup = createGroup [west,true];
    {
        _x setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _x setVariable ["acex_headless_blacklist",true,true];
    } forEach [_group,_enemyGroup];
    _enemyGroup setVariable ["Waldo_AIPass_Exclude",true,true];
    _group setVariable ["Waldo_AIPass_Profile","ELITE",true];
    _group setGroupIdGlobal [format ["Cortex QA %1",_case]];
    private _members = [];
    private _singleCarrier = objNull;
    {
        private _unit = _group createUnit [_x,[1200+(_forEachIndex mod 3)*4,1200-floor(_forEachIndex/3)*4,0],[],0,"NONE"];
        _unit allowDamage false;
        if (_case == "FLANK-GRENADE") then {_unit addMagazine "HandGrenade"};
        if (_case == "ADVANCE-GRENADE") then {
            {
                private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
                if (getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") == "shotGrenade") then {_unit removeMagazine _x};
            } forEach magazines _unit;
        };
        _unit setVariable ["acex_headless_blacklist",true,true];
        _unit setVariable ["Waldo_CortexQA_Shots",0];
        _unit addEventHandler ["FiredMan",{
            params ["_unit","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
            if (_weapon == "Throw" && {getText (configFile >> "CfgAmmo" >> _ammo >> "simulation") == "shotGrenade"}) then {
                private _records = _unit getVariable ["Waldo_CortexQA_FragShots",[]];
                _records pushBack [_projectile,time,getPosATL _unit];
                _unit setVariable ["Waldo_CortexQA_FragShots",_records];
            };
            if (_weapon in ["Throw","Put"]) exitWith {};
            _unit setVariable ["Waldo_CortexQA_Shots",(_unit getVariable ["Waldo_CortexQA_Shots",0])+1];
            private _drill=((group _unit) getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
            if (abs speed _unit > 1 && {_unit in (_drill getOrDefault ["movers",[]])} && {(_drill getOrDefault ["stage",""]) == "MOVE"}) then {
                _unit setVariable ["Waldo_CortexQA_MovingShots",(_unit getVariable ["Waldo_CortexQA_MovingShots",0])+1];
            };
        }];
        _members pushBack _unit;
    } forEach ["O_Soldier_SL_F","O_Soldier_AR_F","O_Soldier_F","O_Soldier_F","O_Soldier_F","O_Soldier_F"];
    missionNamespace setVariable ["Waldo_CortexQA_Combat",[_group,_case,"WAITING FOR CONTACT",[],[],[],_enemyPosition,-1,[]],true];
    private _enemies = [];
    for "_i" from 0 to 1 do {
        private _enemy = _enemyGroup createUnit ["B_Soldier_F",(_enemyPosition vectorAdd [_i*8,0,0]),[],0,"NONE"];
        _enemy allowDamage false;
        _enemy disableAI "PATH";
        _enemy setVariable ["acex_headless_blacklist",true,true];
        _enemies pushBack _enemy;
    };
    private _fixtureCombatMode = ["RED","YELLOW"] select (_case in ["FLANK-YELLOW","FLANK-YELLOW-NATIVE-FIRE","ADVANCE-YELLOW"]);
    _group setCombatMode _fixtureCombatMode;
    // Group orders can reach unit mode state after this scheduled frame. Observe
    // the applied fixture before snapshotting what production cleanup must restore.
    private _modeReady = [{combatMode _group == _fixtureCombatMode
        && {_members findIf {unitCombatMode _x != _fixtureCombatMode} < 0}},5] call _wait;
    ["COMBAT-"+_case+"-fixture-combat-mode",_modeReady,
        str [_fixtureCombatMode,_members apply {unitCombatMode _x}]] call _check;
    private _originalModes = _members apply {[_x,unitCombatMode _x]};
    _enemyGroup setCombatMode "RED";
    _group setBehaviour "AWARE";
    { _x setDir 0 } forEach _members;
    { _x setDir 180 } forEach _enemies;
    if (_advance) then {
        // Establish real contact before native waypoint travel can consume the stimulus.
        {_x disableAI "PATH"} forEach _members;
        private _waypoint = _group addWaypoint [[1200,1500,0],0];
        _waypoint setWaypointType "MOVE";
        _group setCurrentWaypoint _waypoint;
    };
    [createHashMapFromArray [
        ["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",true],
        ["Waldo_AIPass_LambsMode","WMP"],["Waldo_AIPass_Aggression",2],
        ["Waldo_AIPass_Flank_Enable",!_advance],["Waldo_AIPass_Advance_Enable",_advance],
        ["Waldo_AIPass_Assault_Enable",_case != "ADVANCE-CLOSE"],["Waldo_AIPass_Advance_MinContactSeconds",5],
        ["Waldo_AIPass_FireControl_Enable",!(_case in ["FLANK-NATIVE-FIRE","FLANK-YELLOW-NATIVE-FIRE"])],
        ["Waldo_AIPass_Morale_Enable",false],["Waldo_AIPass_Regroup_Enable",false],
        ["Waldo_AIPass_Reinforce_Enable",false],["Waldo_AIPass_CoordinatedAssault_Enable",false],
        ["Waldo_AIPass_Artillery_Enable",false],["Waldo_AIPass_CounterBattery_Enable",false]
    ]] call Waldo_fnc_CortexTuning;
    [format ["%1 real contact",_case],"Six soldiers face two live enemies. They must detect contact, start the enabled manoeuvre, physically move its element, and fire. Invulnerability keeps this movement test independent of casualties.",[1200,1250,0]] call _phase;
    private _prefix = "COMBAT-"+_case;
    _group setVariable ["Waldo_Cortex_DrillTransitions",[],true];
    _group setVariable ["Waldo_Cortex_DrillTransition",nil,true];
    [_prefix+"-requested-contact-delay",(missionNamespace getVariable ["Waldo_AIPass_Advance_MinContactSeconds",-1]) == 5,str (missionNamespace getVariable ["Waldo_AIPass_Advance_MinContactSeconds",-1])] call _check;
    private _nearestPlayer = 1e9;
    {if (!(_x isKindOf "HeadlessClient_F") && {alive _x}) then {_nearestPlayer=_nearestPlayer min (leader _group distance2D _x)}} forEach allPlayers;
    [_prefix+"-tactical-range",_nearestPlayer <= (missionNamespace getVariable ["Waldo_AIPass_FarRange",2500]),format ["nearestPlayer=%1 farRange=%2",_nearestPlayer,missionNamespace getVariable ["Waldo_AIPass_FarRange",2500]]] call _check;
    private _contact = [{((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""]) == "CONTACT"},60] call _wait;
    [_prefix+"-contact",_contact] call _check;
    if (!_contact) then {
        private _diagnosticState=_group getVariable ["Waldo_AIPass_State",createHashMap];
        diag_log format ["WMP CORTEX QA CONTACT PREREQUISITE: case=%1 owner=%2 local=%3 eligible=%4 phase=%5 hold=%6 waypointsHeld=%7 knowledge=%8",_case,groupOwner _group,local _group,[_group] call Waldo_fnc_CortexIsEligible,_diagnosticState getOrDefault ["phase","NO STATE"],_group getVariable ["Waldo_AIPass_ZeusHold",[]],_group getVariable ["Waldo_AIPass_ZeusWaypoints",false],[_group] call Waldo_fnc_CortexKnowledge];
    };
    if (_advance) then {{_x enableAI "PATH"} forEach _members};
    diag_log format ["WMP CORTEX QA COMBAT START CONDITIONS: case=%1 leader=%2 waypoint=%3 remaining=%4 knowledge=%5",_case,getPosATL leader _group,currentWaypoint _group,leader _group distance2D waypointPosition [_group,currentWaypoint _group],[_group] call Waldo_fnc_CortexKnowledge];
    private _started = [{count ((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) > 0},70] call _wait;
    private _startRefusal=[
        _group getVariable ["Waldo_Cortex_FlankRefusal",[]],
        _group getVariable ["Waldo_Cortex_AdvanceRefusal",[]],
        (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["movementLease",[]],
        [_group] call Waldo_fnc_CortexKnowledge
    ];
    [_prefix+"-started",_started,str _startRefusal] call _check;
    private _drill = (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
    private _drillToken = _drill getOrDefault ["token",""];
    if (_case == "ADVANCE-GRENADE" && {_started}) then {
        private _teams = _drill getOrDefault ["teams",[]];
        if (count _teams == 2 && {(_teams select 0) isNotEqualTo []}) then {
            _singleCarrier = (_teams select 0) select 0;
            _singleCarrier addMagazine "HandGrenade";
            _singleCarrier setVariable ["Waldo_CortexQA_Label","FIRST ELEMENT / ONLY FRAG CARRIER",true];
        };
        [_prefix+"-single-carrier-prerequisite",!isNull _singleCarrier && {"HandGrenade" in magazines _singleCarrier}] call _check;
    };
    if (_started) then {
        private _before = [_drill getOrDefault ["stage",""],_drill getOrDefault ["index",-1],+(_drill getOrDefault ["spots",[]])];
        private _stale = [createHashMapFromArray [["group",_group],["drillToken","QA-RETIRED-DRILL"]]] call Waldo_fnc_CortexFlankStep;
        private _after = [_drill getOrDefault ["stage",""],_drill getOrDefault ["index",-1],+(_drill getOrDefault ["spots",[]])];
        [_prefix+"-stale-step-no-mutation",_stale == -1 && {_before isEqualTo _after}] call _check;
    };
    if (_case in ["FLANK-AWARE","ADVANCE-AWARE"]) then {
        // Diagnostic fixture only: isolate native danger behaviour after real contact.
        // Actors are deleted after this case; no production behaviour policy is changed.
        {
            _x disableAI "AUTOCOMBAT";
            _x setCombatBehaviour "AWARE";
        } forEach _members;
        [_prefix+"-aware-diagnostic-applied",_members findIf {combatBehaviour _x != "AWARE" || {_x checkAIFeature "AUTOCOMBAT"}} < 0] call _check;
    };
    if (_handover) then {
        private _stageReady = true;
        private _interruptionActors = +_members;
        if (_case == "FLANK-ZEUS-CONSOLIDATE") then {
            ["Consolidation interruption prerequisite","Watch the assault clear through, then the covering element move forward. Zeus replacement is tested only after support troops physically move in consolidation.",[1200,1300,0]] call _phase;
            [{
                private _live = (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
                missionNamespace setVariable ["Waldo_CortexQA_Combat",[_group,_case,_live getOrDefault ["stage","ENDED"],
                    _live getOrDefault ["movers",[]],_live getOrDefault ["spots",[]],_live getOrDefault ["points",[]],
                    _enemyPosition,_live getOrDefault ["index",-1],_group getVariable ["Waldo_Cortex_DrillResult",[]]],true];
                count _live == 0 || {_live getOrDefault ["consolidating",false]}
            },600] call _wait;
            private _live = (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
            _stageReady = _live getOrDefault ["consolidating",false];
            _interruptionActors = +(_live getOrDefault ["movers",[]]);
            [_prefix+"-consolidation-prerequisite",_stageReady && {_interruptionActors isNotEqualTo []}] call _check;
        };
        private _origins = _members apply {getPosATL _x};
        [format ["%1: interruption during movement",_case],"Watch for at least one soldier to travel 8 m under the drill. The fixture then invokes the Zeus handover function and issues a westward replacement waypoint. All six must reach it; a cleared state alone does not pass.",[1200,1200,0]] call _phase;
        private _moving = [{
            private _travel = false;
            {if (_x in _interruptionActors && {_x distance2D (_origins select _forEachIndex) >= 8}) then {_travel = true}} forEach _members;
            _stageReady && {_travel} && {count (((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap])) > 0}
        },45] call _wait;
        [_prefix+"-interrupt-physical-prerequisite",_started && {_moving}] call _check;
        private _oldToken = _drill getOrDefault ["token",""];
        if (_case == "FLANK-ZEUS-ROE") then {
            private _ownedModes = (((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) getOrDefault ["combatModes",[]]);
            [_prefix+"-owned-roe-prerequisite",_ownedModes isNotEqualTo []] call _check;
            if (_ownedModes isNotEqualTo []) then {
                private _actor = (_ownedModes select 0) select 0;
                _actor setUnitCombatMode "BLUE";
                private _row = _originalModes findIf {(_x select 0) == _actor};
                if (_row >= 0) then {(_originalModes select _row) set [1,"BLUE"]};
            };
        };
        [_group,true] call Waldo_fnc_CortexZeusMark;
        // End the contact stimulus so this isolates old-order cleanup and replacement travel.
        {deleteVehicle _x} forEach _enemies;
        private _destination = (getPosATL leader _group) vectorAdd [-70,0,0];
        private _wp = _group addWaypoint [_destination,0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius 3;
        _group setCurrentWaypoint _wp;
        {
            _x setVariable ["Waldo_CortexQA_Label",format ["Replacement soldier %1",_forEachIndex+1],true];
            _x setVariable ["Waldo_CortexQA_Target",_destination,true];
        } forEach _members;
        missionNamespace setVariable ["Waldo_CortexQA_Actors",_members,true];
        missionNamespace setVariable ["Waldo_CortexQA_Combat",[],true];
        private _released = [{
            count ((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) == 0
            && {_members findIf {!(_x checkAIFeature "PATH") || {!(_x checkAIFeature "TARGET")} || {!(_x checkAIFeature "AUTOTARGET")}} < 0}
        },15] call _wait;
        [_prefix+"-interrupt-cleanup",_moving && {_released}] call _check;
        private _staleResult = [createHashMapFromArray [["group",_group],["drillToken",_oldToken]]] call Waldo_fnc_CortexFlankStep;
        [_prefix+"-retired-job-rejected",_oldToken != "" && {_staleResult == -1}] call _check;
        // A MOVE destination belongs to the leader; followers must reach their own
        // formation destinations. A radius around the leader falsely rejects a wedge.
        private _formationArrived = {
            private _settled = alive leader _group && {leader _group distance2D _destination <= 3};
            {
                private _expected = expectedDestination _x;
                if (!alive _x || {_x distance2D (_origins select _forEachIndex) < 35}
                    || {_expected isEqualTo []} || {_x distance2D (_expected select 0) > 3}
                    || {_x distance2D leader _group > 30}) then {_settled=false};
            } forEach _members;
            _settled
        };
        private _arrival = [_formationArrived,120] call _wait;
        [_prefix+"-replacement-arrival",_moving && {_released} && {_arrival},str (_members apply {_x distance2D _destination})] call _check;
        diag_log format ["WMP CORTEX QA HANDOVER GEOMETRY: case=%1 leaderRemaining=%2 formation=%3 members=%4",_case,leader _group distance2D _destination,formation _group,_members apply {[netId _x,getPosATL _x,_x distance2D leader _group,currentCommand _x,expectedDestination _x]}];
        private _formationSettled = call _formationArrived;
        [_prefix+"-replacement-formation-arrival",_moving && {_released} && {_formationSettled},str (_members apply {expectedDestination _x})] call _check;
        private _settledOrigins = _members apply {getPosATL _x};
        private _formationDrift = 0;
        private _resurrected = false;
        private _allAlive = true;
        for "_sample" from 1 to 15 do {
            sleep 1;
            {
                if (!alive _x) then {_allAlive=false};
                _formationDrift = _formationDrift max (_x distance2D (_settledOrigins select _forEachIndex));
            } forEach _members;
            if (count ((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) > 0) then {_resurrected=true};
        };
        [_prefix+"-replacement-formation-stable",_formationSettled && {_formationDrift <= 3} && {_allAlive} && {!_resurrected},str _formationDrift] call _check;
        [_prefix+"-replacement-no-resurrection",_arrival && {_formationDrift <= 3} && {_allAlive} && {!_resurrected},str [_formationDrift,_resurrected]] call _check;
    } else {
    private _element = +(_drill getOrDefault ["units",[]]);
    private _starts = _element apply {getPosATL _x};
    private _supportOrigins = (_members - _element) apply {[_x,getPosATL _x]};
    private _clearedObjective = [];
    private _observedAssault = false;
    private _clearThroughTeams = [];
    private _assaultPositionReached = false;
    private _grenadeHoldOrigins = [];
    private _grenadeHoldDrift = 0;
    private _grenadeStageSeen = false;
    private _grenadeUnsafeCrossing = false;
    private _fragShots = 0;
    private _moved = false;
    private _haltMeasurements = [];
    private _arrivedBounds = [];
    private _measuredBounds = [];
    if (_started) then {
        [format ["%1: movement and covering fire",_case],
            ["Watch the manoeuvre element move along the cyan trails while the support element fires. Arrival, frontage, actual shots and final transition are measured separately. Earlier prerequisite failures remain recorded.",
             "Watch alternate fire teams move to each bound while the other holds and fires. Cyan trails show actual travel. A stranded soldier remains a failure even when the viable element continues; role labels alone do not pass."] select _advance,
            [1200,1300,0]] call _phase;
    };
    private _endTime = diag_tickTime + ([240,480] select _advance);
    private _roleTurns=[];
    private _coverSamples=[];
    private _roleKey=[];
    private _coverStart=[];
    private _coverAt=0;
    private _nextLog = 0;
    private _lastVisual = [];
    private _blockedActor = objNull;
    private _releaseAt = -1;
    private _blockOrigin = [];
    private _restOrigins = [];
    private _continued = false;
    private _observedRecovery = false;
    private _respectedBlock = true;
    private _releasedBlock = false;
    if (_started) then {
        waitUntil {
            sleep 0.5;
            private _live = (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
            _observedAssault = _observedAssault || {_live getOrDefault ["assaulting",false]};
            if (_live getOrDefault ["assaulting",false]) then {
                private _objective = _live getOrDefault ["assaultObjective",_enemyPosition];
                _clearedObjective = +_objective;
                _assaultPositionReached = _assaultPositionReached || {count _element >= 2 && {_element findIf {!alive _x || {_x distance2D _objective > 20}} < 0}};
            };
            private _fragRecords = [];
            {_fragRecords append (_x getVariable ["Waldo_CortexQA_FragShots",[]])} forEach _members;
            _fragShots = count _fragRecords;
            private _transitionRows = (_group getVariable ["Waldo_Cortex_DrillTransitions",[]]) select {(_x param [1,""]) == _drillToken};
            private _grenadeQueued = _transitionRows findIf {(_x param [5,""]) == "ASSAULT_GRENADE_QUEUED"} >= 0;
            if (_grenadeQueued) then {
                if (!_grenadeStageSeen) then {
                    _grenadeStageSeen=true;
                    _grenadeHoldOrigins = _element apply {[_x,getPosATL _x]};
                    [format ["%1: grenade hold",_case],"Watch the actual grenade and troop trails. Troops must stay at the assault position until the grenade is gone, then cross beyond the objective. A queued throw alone does not pass.",getPosATL leader _group] call _phase;
                };
                private _grenadeActive = (_live getOrDefault ["grenadeActionUntil",0]) > time
                    || {_fragRecords findIf {!isNull (_x select 0)} >= 0};
                if (_grenadeActive) then {
                    {_grenadeHoldDrift = _grenadeHoldDrift max ((_x select 0) distance2D (_x select 1))} forEach _grenadeHoldOrigins;
                };
            };
            private _liveRoute = _live getOrDefault ["points",[]];
            private _liveIndex = _live getOrDefault ["index",-1];
            if ((_live getOrDefault ["stage",""]) == "MOVE" && {_liveIndex >= 0} && {_liveIndex < count _liveRoute}
                && {((_liveRoute select _liveIndex) select 1) == "CLEAR"}
                && {_fragRecords findIf {!isNull (_x select 0) || {time-(_x select 1) < 8}} >= 0}) then {_grenadeUnsafeCrossing=true};
            if (_blockage && {isNull _blockedActor} && {(_live getOrDefault ["stage",""]) == "MOVE"}
                && {count (_live getOrDefault ["movers",[]]) >= 3}) then {
                _blockedActor = (_live get "movers") select 0;
                _blockOrigin = getPosATL _blockedActor;
                _restOrigins = ((_live get "movers") - [_blockedActor]) apply {[_x,getPosATL _x]};
                _blockedActor disableAI "PATH";
                _releaseAt = time+45;
                diag_log format ["WMP CORTEX QA CONTROLLED BLOCK: case=%1 actor=%2 releaseAt=%3; PATH inhibition, not a geometry obstacle",_case,netId _blockedActor,_releaseAt];
            };
            if (!isNull _blockedActor) then {
                private _recoveryActors = (_live getOrDefault ["recovery",[]]) apply {_x select 0};
                if (!_observedRecovery && {_blockedActor in _recoveryActors}) then {
                    _observedRecovery = true;
                    // Measure continuation AFTER the controller separates the straggler.
                    // Travel on the original bound before the stall cannot pass this check.
                    _restOrigins = (_restOrigins apply {_x select 0}) apply {[_x,getPosATL _x]};
                };
                if (!_releasedBlock) then {
                    _respectedBlock = _respectedBlock && {!(_blockedActor checkAIFeature "PATH")};
                    _continued = _continued || {_observedRecovery && {_restOrigins findIf {(_x select 0) distance2D (_x select 1) < 12} < 0}};
                    if (time >= _releaseAt) then {_blockedActor enableAI "PATH"; _releasedBlock=true};
                };
            };
            private _visual = [_group,_case,_live getOrDefault ["stage","ENDED"],_live getOrDefault ["movers",_element],_live getOrDefault ["spots",[]],_live getOrDefault ["points",[]],_enemyPosition,_live getOrDefault ["index",-1],_group getVariable ["Waldo_Cortex_DrillResult",[]],_members apply {[_x,_x getVariable ["Waldo_CortexQA_Shots",0],_x getVariable ["Waldo_CortexQA_MovingShots",0]]}];
            if (_visual isNotEqualTo _lastVisual) then {missionNamespace setVariable ["Waldo_CortexQA_Combat",_visual,true]; _lastVisual=+_visual};
            private _allMoved = count _element >= 2;
            {if (!alive _x || {_x distance2D (_starts select _forEachIndex) < 12}) then {_allMoved=false}} forEach _element;
            _moved = _moved || _allMoved;
            private _bound = [_live getOrDefault ["index",-1],_live getOrDefault ["teamTurn",0]];
            private _moving = _live getOrDefault ["movers",_element];
            if (_advance && {(_live getOrDefault ["stage",""]) == "MOVE"}) then {
                private _cover=(_element-_moving)-((_live getOrDefault ["recovery",[]]) apply {_x select 0});
                if (_bound isNotEqualTo _roleKey) then {
                    _roleKey=+_bound; _roleTurns pushBack +_bound; _coverAt=time;
                    _coverStart=_cover apply {[_x,getPosATL _x,_x getVariable ["Waldo_CortexQA_Shots",0]]};
                    {_x setVariable ["Waldo_CortexQA_Label",format ["BOUND %1 / MOVING ELEMENT %2",(_bound select 0)+1,(_bound select 1)+1],true]} forEach _moving;
                    {_x setVariable ["Waldo_CortexQA_Label",format ["BOUND %1 / COVERING",(_bound select 0)+1],true]} forEach _cover;
                    missionNamespace setVariable ["Waldo_CortexQA_Actors",_members+_enemies,true];
                };
                if (time-_coverAt >= 3 && {_coverStart isNotEqualTo []}) then {
                    private _held=_coverStart findIf {(_x select 0) distance2D (_x select 1) > 3} < 0;
                    private _fired=_coverStart findIf {((_x select 0) getVariable ["Waldo_CortexQA_Shots",0]) > (_x select 2)} >= 0;
                    _coverSamples pushBack [+_bound,_held,_fired];
                    // Keep the original cover positions and sample throughout the whole bound.
                    _coverAt=time;
                };
            };
            if ((_live getOrDefault ["stage",""]) in ["PAUSE","HOLD"] && {!(_bound in _measuredBounds)} && {count _moving >= 2}) then {
                _measuredBounds pushBack _bound;
                private _assignedSpots = _live getOrDefault ["spots",[]];
                private _physicalArrival = count _moving == count _assignedSpots;
                {
                    if (!alive _x || {_forEachIndex >= count _assignedSpots} || {_x distance2D (_assignedSpots select _forEachIndex) > 3}) then {_physicalArrival=false};
                } forEach _moving;
                if (_physicalArrival) then {_arrivedBounds pushBack +_bound};
                private _route = _live getOrDefault ["points",[]];
                private _routeIndex = _live getOrDefault ["index",-1];
                if (_physicalArrival && {_routeIndex >= 0} && {_routeIndex < count _route}
                    && {((_route select _routeIndex) select 1) == "CLEAR"}) then {
                    private _axis = _live getOrDefault ["assaultDirection",0];
                    private _objective = _live getOrDefault ["assaultObjective",_enemyPosition];
                    private _forward = [sin _axis,cos _axis,0];
                    // Require living actors physically beyond the objective, not a CLEAR flag.
                    if (_moving findIf {((getPosATL _x vectorDiff _objective) vectorDotProduct _forward) < 10} < 0) then {
                        _clearThroughTeams pushBackUnique (_bound select 1);
                    };
                };
                // Recovery movement across the scene is not the halt's formation. Measure only
                // after every assigned actor has physically reached this bound.
                if (_physicalArrival) then {
                    private _centre = [0,0,0];
                    {_centre = _centre vectorAdd getPosATL _x} forEach _moving;
                    _centre = _centre vectorMultiply (1 / count _moving);
                    private _heading = _centre getDir _enemyPosition;
                    private _side = [cos _heading,-sin _heading,0];
                    private _front = [sin _heading,cos _heading,0];
                    private _lateral = _moving apply {((getPosATL _x) vectorDiff _centre) vectorDotProduct _side};
                    private _depth = _moving apply {((getPosATL _x) vectorDiff _centre) vectorDotProduct _front};
                    private _width = (selectMax _lateral)-(selectMin _lateral);
                    private _length = (selectMax _depth)-(selectMin _depth);
                    // Two actors assigned 3 m apart commonly settle just inside that engine
                    // destination. Keep a 0.75 m tolerance while retaining the depth rejection.
                    private _minimumWidth = [2.25,3] select (count _moving > 2);
                    _haltMeasurements pushBack [_bound,_width,_length,_width >= _minimumWidth && {_length <= _width+4}];
                    diag_log format ["WMP CORTEX QA FRONTAGE DETAIL: case=%1 bound=%2 physicalArrival=%3 width=%4 depth=%5 actors=%6 recovery=%7",
                        _case,_bound,_physicalArrival,_width,_length,
                        _moving apply {[netId _x,getPosATL _x,currentCommand _x]},
                        (_live getOrDefault ["recovery",[]]) apply {netId (_x select 0)}];
                };
            };

            if (diag_tickTime >= _nextLog) then {
                _nextLog=diag_tickTime+10;
                private _recoveryDetail = (_live getOrDefault ["recovery",[]]) apply {
                    private _actor = _x select 0;
                    [netId _actor,_x select 1,(_x select 2)-time,getPosATL _actor,
                        currentCommand _actor,expectedDestination _actor,unitCombatMode _actor,
                        _actor checkAIFeature "PATH",_actor checkAIFeature "MOVE"]
                };
                if (_recoveryDetail isNotEqualTo []) then {
                    diag_log format ["WMP CORTEX QA RECOVERY: case=%1 actors=%2",_case,_recoveryDetail];
                };
                diag_log format ["WMP CORTEX QA COMBAT: case=%1 phase=%2 stage=%3 index=%4 positions=%5 spots=%6 result=%7",_case,(_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["phase",""],_live getOrDefault ["stage",""],_live getOrDefault ["index",-1],_element apply {[getPosATL _x,currentCommand _x,expectedDestination _x,stance _x,lifeState _x,getSuppression _x,simulationEnabled _x,_x checkAIFeature "PATH",_x checkAIFeature "AUTOCOMBAT",behaviour _x,unitCombatMode _x,attackEnabled _group,_x checkAIFeature "TARGET",_x checkAIFeature "AUTOTARGET",netId assignedTarget _x]},_live getOrDefault ["spots",[]],_group getVariable ["Waldo_Cortex_DrillResult",[]]];
            };
            count _live == 0 || {diag_tickTime >= _endTime}
        };
    };
    if (_case in ["FLANK-GRENADE","ADVANCE-GRENADE"]) then {
        [_prefix+"-actual-frag-deployed",_fragShots > 0,str _fragShots] call _check;
        [_prefix+"-physical-grenade-hold",_grenadeStageSeen && {_fragShots > 0} && {_grenadeHoldDrift <= 3},str _grenadeHoldDrift] call _check;
        [_prefix+"-no-crossing-live-frag",_fragShots > 0 && {!_grenadeUnsafeCrossing} && {_clearThroughTeams isNotEqualTo []}] call _check;
    };
    if (_case == "ADVANCE-GRENADE") then {
        [_prefix+"-first-element-carrier-fired",!isNull _singleCarrier
            && {count (_singleCarrier getVariable ["Waldo_CortexQA_FragShots",[]]) > 0}] call _check;
    };
    if (_observedAssault) then {
        [_prefix+"-physical-clear-through",count _clearThroughTeams >= ([1,2] select _advance),str _clearThroughTeams] call _check;
    };
    if (_observedAssault) then {
        private _cohesive = _clearedObjective isNotEqualTo [] && {count _members >= 2};
        {
            if (!alive _x || {_x distance2D _clearedObjective > 35}
                || {_x distance2D leader _group > 35}) then {_cohesive=false};
        } forEach _members;
        private _supportAdvanced = _supportOrigins findIf {(_x select 0) distance2D (_x select 1) < 30} < 0;
        [_prefix+"-physical-consolidation",_cohesive && {_supportAdvanced},
            str [_members apply {[_x distance2D _enemyPosition,_x distance2D leader _group]},_supportOrigins apply {(_x select 0) distance2D (_x select 1)}]] call _check;
    };
    if (_blockage) then {
        // Restore only the stimulus installed by this fixture, even on an early abort.
        if (!isNull _blockedActor && {!_releasedBlock}) then {_blockedActor enableAI "PATH"};
        [_prefix+"-tracked-straggler",!isNull _blockedActor && {_observedRecovery}] call _check;
        [_prefix+"-continued-with-blocked-actor",_continued] call _check;
        [_prefix+"-preserved-movement-inhibition",_respectedBlock] call _check;
        private _peers = (_restOrigins apply {_x select 0}) select {alive _x};
        private _rejoined = !isNull _blockedActor && {_releasedBlock}
            && {_blockedActor distance2D _blockOrigin >= 12}
            && {_peers findIf {_blockedActor distance2D _x <= 12} >= 0};
        [_prefix+"-physical-rejoin",_rejoined] call _check;
    };
    private _remainingDrill=(_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
    [_prefix+"-observation-completed",_started && {count _remainingDrill == 0},format ["Observed stage=%1 index=%2; controllerFailure=%3",_remainingDrill getOrDefault ["stage","ENDED"],_remainingDrill getOrDefault ["index",-1],_group getVariable ["Waldo_Cortex_DrillFailure",[]]]] call _check;
    [_prefix+"-physical-movement",_moved] call _check;
    [_prefix+"-threat-facing-frontage",_haltMeasurements isNotEqualTo [] && {_haltMeasurements findIf {!(_x select 3)} < 0},str _haltMeasurements] call _check;
    private _ending = _group getVariable ["Waldo_Cortex_DrillResult",[]];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    private _resultStage = ["ENDED","DEADLINE EXCEEDED"] select (count _remainingDrill > 0);
    missionNamespace setVariable ["Waldo_CortexQA_Combat",[_group,_case,_resultStage,_element,[],[],_enemyPosition,-1,_ending,_members apply {[_x,_x getVariable ["Waldo_CortexQA_Shots",0],_x getVariable ["Waldo_CortexQA_MovingShots",0]]}],true];
    if (_case == "ADVANCE-CLOSE") then {
        private _centre = [0,0,0];
        {_centre = _centre vectorAdd getPosATL _x} forEach _element;
        _centre = _centre vectorMultiply (1 / (count _element max 1));
        [_prefix+"-proximity-stop",count _element >= 2 && {_moved} && {(_ending param [1,""]) == "CLOSE"} && {_centre distance2D _enemyPosition < 35},str [_ending,_centre distance2D _enemyPosition]] call _check;
    } else {
        [_prefix+"-completed",(_ending param [0,""]) == _mode && {(_ending param [1,""]) == "COMPLETE"},str _ending] call _check;
    };
    if (_advance) then {
        [_prefix+"-both-elements-started",_roleTurns findIf {(_x select 1) == 0} >= 0 && {_roleTurns findIf {(_x select 1) == 1} >= 0},str _roleTurns] call _check;
        [_prefix+"-both-elements-bounded",_arrivedBounds findIf {(_x select 1) == 0} >= 0 && {_arrivedBounds findIf {(_x select 1) == 1} >= 0},str _arrivedBounds] call _check;
        [_prefix+"-cover-held-during-bounds",_coverSamples isNotEqualTo [] && {_coverSamples findIf {!(_x select 1)} < 0},str _coverSamples] call _check;
        [_prefix+"-actual-covering-fire",_coverSamples findIf {_x select 2} >= 0,str _coverSamples] call _check;
    };
    [_prefix+"-fire-while-moving",_members findIf {(_x getVariable ["Waldo_CortexQA_MovingShots",0]) > 0} >= 0,str (_members apply {_x getVariable ["Waldo_CortexQA_MovingShots",0]})] call _check;
    [_prefix+"-actual-fire",_members findIf {(_x getVariable ["Waldo_CortexQA_Shots",0]) > 0} >= 0] call _check;
    if (!_advance) then {
        [_prefix+"-assault-entered",_observedAssault] call _check;
        [_prefix+"-assault-position",_assaultPositionReached] call _check;
    };
    // Preserve every deadline finding above. This separate diagnostic distinguishes
    // late physical completion from a controller that never finishes its last stage.
    if (count _remainingDrill > 0) then {
        [format ["%1 late-completion diagnostic",_case],"The original observation deadline failed and remains recorded. Watch for up to two more minutes: does the manoeuvre physically finish, or does it stop progressing?",getPosATL leader _group] call _phase;
        private _lateVisualPrevious = [];
        private _lateEnded = [{
            private _lateDrill = (_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap];
            private _lateVisual = [_group,_case,"LATE: "+(_lateDrill getOrDefault ["stage","ENDED"]),_lateDrill getOrDefault ["movers",_element],_lateDrill getOrDefault ["spots",[]],_lateDrill getOrDefault ["points",[]],_enemyPosition,_lateDrill getOrDefault ["index",-1],_group getVariable ["Waldo_Cortex_DrillResult",[]],_members apply {[_x,_x getVariable ["Waldo_CortexQA_Shots",0],_x getVariable ["Waldo_CortexQA_MovingShots",0]]}];
            if (_lateVisual isNotEqualTo _lateVisualPrevious) then {
                missionNamespace setVariable ["Waldo_CortexQA_Combat",_lateVisual,true];
                _lateVisualPrevious = +_lateVisual;
            };
            count _lateDrill == 0
        },120] call _wait;
        private _lateResult = _group getVariable ["Waldo_Cortex_DrillResult",[]];
        [_prefix+"-late-controller-ended",_lateEnded,str _lateResult] call _check;
        [_prefix+"-late-completed",_lateEnded && {(_lateResult param [1,""]) == "COMPLETE"},str _lateResult] call _check;
        if (_observedAssault && {_clearedObjective isNotEqualTo []}) then {
            private _lateCohesion = _members findIf {!alive _x || {_x distance2D _clearedObjective > 35}
                || {_x distance2D leader _group > 35}} < 0;
            private _lateSupport = _supportOrigins findIf {(_x select 0) distance2D (_x select 1) < 30} < 0;
            [_prefix+"-late-physical-consolidation",_lateEnded && {_lateCohesion} && {_lateSupport},
                str (_members apply {[_x distance2D _clearedObjective,_x distance2D leader _group]})] call _check;
        };
        // Original deadline failures above remain recorded; the visible result uses
        // the actual latest ending rather than the empty pre-diagnostic snapshot.
        _ending = +_lateResult;
        missionNamespace setVariable ["Waldo_CortexQA_Combat",[_group,_case,
            ["LATE: STILL RUNNING","LATE: ENDED"] select _lateEnded,_members,[],[],_enemyPosition,-1,_ending,
            _members apply {[_x,_x getVariable ["Waldo_CortexQA_Shots",0],_x getVariable ["Waldo_CortexQA_MovingShots",0]]}],true];
        diag_log format ["WMP CORTEX QA LATE COMPLETION: case=%1 result=%2 actors=%3",_case,_lateResult,_element apply {[netId _x,getPosATL _x,currentCommand _x,expectedDestination _x]}];
    };
    private _caseTransitions = (_group getVariable ["Waldo_Cortex_DrillTransitions",[]]) select {(_x param [1,""]) == _drillToken};
    [_prefix+"-transition-assault-committed",!_observedAssault || {_caseTransitions findIf {(_x param [5,""]) == "ASSAULT_COMMITTED"} >= 0},str _caseTransitions] call _check;
    [_prefix+"-transition-clear-through",!_observedAssault || {_caseTransitions findIf {(_x param [5,""]) == "CLEAR_THROUGH_ARRIVED"} >= 0},str _caseTransitions] call _check;
    if (_case in ["FLANK-GRENADE","ADVANCE-GRENADE"]) then {
        [_prefix+"-transition-grenade-queued",_caseTransitions findIf {(_x param [5,""]) == "ASSAULT_GRENADE_QUEUED"} >= 0,str _caseTransitions] call _check;
    };
    [format ["%1 result: %2",_case,_ending param [1,"NO DRILL"]],"Compare actual movement with the route. Completion requires every manoeuvre soldier to reach the bounds; firing or an accepted order alone is insufficient.",getPosATL leader _group] call _phase;
    sleep 20;
    };
    private _caseTransitions = (_group getVariable ["Waldo_Cortex_DrillTransitions",[]]) select {(_x param [1,""]) == _drillToken};
    private _chronological = true;
    if (count _caseTransitions > 1) then {
        for "_transitionIndex" from 1 to ((count _caseTransitions)-1) do {
            if ((_caseTransitions select _transitionIndex select 0) < (_caseTransitions select (_transitionIndex-1) select 0)) then {_chronological=false};
        };
    };
    [_prefix+"-transition-start",_drillToken != "" && {_caseTransitions findIf {(_x param [4,""]) == "START"} >= 0},str _caseTransitions] call _check;
    [_prefix+"-transition-move",_caseTransitions findIf {(_x param [4,""]) == "MOVE"} >= 0,str _caseTransitions] call _check;
    [_prefix+"-transition-ended",_caseTransitions findIf {(_x param [4,""]) == "ENDED"} >= 0,str _caseTransitions] call _check;
    [_prefix+"-transition-order",_chronological,str _caseTransitions] call _check;
    // Disable while managed and verify cleanup, without writing successful state into the fixture.
    [createHashMapFromArray [["Waldo_AIPass_Contact_Enable",false]]] call Waldo_fnc_CortexTuning;
    [_prefix+"-disabled-cleanup",[{count ((_group getVariable ["Waldo_AIPass_State",createHashMap]) getOrDefault ["drill",createHashMap]) == 0 && {_members findIf {!(_x checkAIFeature "TARGET") || {!(_x checkAIFeature "AUTOTARGET")}} < 0}},15] call _wait] call _check;
    [_group] call Waldo_fnc_CortexReleaseGroup;
    [_prefix+"-combat-mode-restored",_originalModes findIf {alive (_x select 0) && {unitCombatMode (_x select 0) != (_x select 1)}} < 0,str [_originalModes apply {[netId (_x select 0),_x select 1]},_members apply {[netId _x,unitCombatMode _x]}]] call _check;
    {deleteVehicle _x} forEach (_members+_enemies);
    deleteGroup _group;
    deleteGroup _enemyGroup;
    missionNamespace setVariable ["Waldo_CortexQA_Combat",[],true];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
} forEach _cases;
