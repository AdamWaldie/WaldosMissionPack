/*
 * Author: WaldoTheWarfighter
 * Compares wheeled, tracked and mixed convoy continuity on a long route at four spacings.
 * Outside VR one bounded scan rotates the 1.8 km route across real relieved terrain; all spacing,
 * heading and order measurements use that selected route axis rather than world X/Y.
 * Locality/authority: scheduled server creates and owns fixtures through the public convoy API.
 * Repeat/JIP: fresh groups per case; public observer vehicles; release and delete each case.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAConvoyMatrix.sqf";
 */
params ["_check","_phase","_wait"];
private _terrainOrigin=[2500,2500,0];
private _terrainHeading=0;
private _terrainRelief=0;
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
private _routeSamples=[];
for "_along" from -180 to 1000 step 50 do {_routeSamples pushBack [0,_along]};
for "_across" from 50 to 400 step 50 do {_routeSamples pushBack [_across,1000]};
for "_along" from 1050 to 1400 step 50 do {_routeSamples pushBack [400,_along]};
if (!_terrainScenarioReady) then {
    private _found=[];
    private _margin=1800;
    private _scanStep=1000 max ((worldSize-2*_margin)/5);
    for "_candidateX" from _margin to (worldSize-_margin) step _scanStep do {
        for "_candidateY" from _margin to (worldSize-_margin) step _scanStep do {
            for "_heading" from 0 to 315 step 45 do {
                if (_found isEqualTo []) then {
                    private _heights=[];
                    private _usable=true;
                    private _maximumGrade=0;
                    private _minimumNormal=1;
                    private _previous=[];
                    {
                        private _sample=[[_candidateX,_candidateY,0],_heading,_x select 0,_x select 1] call _terrainWorld;
                        private _normal=(surfaceNormal _sample) select 2;
                        if (surfaceIsWater _sample || {_normal < 0.65}) exitWith {_usable=false};
                        private _height=getTerrainHeightASL _sample;
                        if (_previous isNotEqualTo [] && {_sample distance2D (_previous select 0) <= 75}) then {
                            private _grade=abs (_height-(_previous select 1))/(_sample distance2D (_previous select 0) max 1);
                            _maximumGrade=_maximumGrade max _grade;
                            if (_grade > 0.8) then {_usable=false};
                        };
                        _minimumNormal=_minimumNormal min _normal;
                        _previous=[_sample,_height];
                        _heights pushBack _height;
                    } forEach _routeSamples;
                    if (_usable && {_heights isNotEqualTo []}) then {
                        private _relief=(selectMax _heights)-(selectMin _heights);
                        if (_relief >= 30 && {_relief <= 220}) then {
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
    [_terrainOrigin,_terrainHeading,_x-2500,_y-2500] call _terrainWorld
};
private _terrainForward=[sin _terrainHeading,cos _terrainHeading,0];
private _terrainRight=[cos _terrainHeading,-sin _terrainHeading,0];
["CNVM-terrain-scenario",_terrainScenarioReady,
    str [worldName,_terrainOrigin,_terrainHeading,_terrainRelief,_terrainMaximumGrade,_terrainMinimumNormal]] call _check;
if (!_terrainScenarioReady) exitWith {};
private _columnOnly=(missionNamespace getVariable ["Waldo_CortexQA_Focus","all"]) in ["convoycolumn","convoytracked"];
private _trackedOnly=(missionNamespace getVariable ["Waldo_CortexQA_Focus","all"]) == "convoytracked";
private _followDiagnostic=(missionNamespace getVariable ["Waldo_CortexQA_Focus","all"]) == "convoyfollow";
private _diagnostic=(missionNamespace getVariable ["Waldo_CortexQA_Focus","all"]) == "convoydiagnostic";
private _types = [
    ["BASELINE-WHEELED",["O_MRAP_02_F","O_Truck_03_transport_F","O_Truck_03_transport_F"]],
    ["BASELINE-TRACKED",["O_APC_Tracked_02_cannon_F","O_APC_Tracked_02_cannon_F","O_APC_Tracked_02_cannon_F"]],
    ["BASELINE-MIXED",["O_MRAP_02_F","O_APC_Tracked_02_cannon_F","O_Truck_03_transport_F"]],
    ["WHEELED",["O_MRAP_02_F","O_Truck_03_transport_F","O_Truck_03_transport_F"]],
    ["TRACKED",["O_APC_Tracked_02_cannon_F","O_APC_Tracked_02_cannon_F","O_APC_Tracked_02_cannon_F"]],
    ["MIXED",["O_MRAP_02_F","O_APC_Tracked_02_cannon_F","O_Truck_03_transport_F"]]
];
if (_diagnostic) then {
    _types=["BASELINE-CONTROL","BASELINE-LEAD-MOVE","BASELINE-FORCE-SPEED","BASELINE-OMIT-LEAD-GAP"] apply {[_x,["O_MRAP_02_F","O_Truck_03_transport_F","O_Truck_03_transport_F"]]};
};
if (_followDiagnostic) then {
    _diagnostic=true;
    _types=["BASELINE-DRIVER-FOLLOW","BASELINE-VEHICLE-FOLLOW","BASELINE-MOVE-FORCE"] apply {[_x,["O_MRAP_02_F","O_Truck_03_transport_F","O_Truck_03_transport_F"]]};
};
if (_columnOnly) then {_types=_types select {(_x select 0) find "BASELINE-" != 0}};
if (_trackedOnly) then {_types=_types select {(_x select 0) == "TRACKED"}};
{
    _x params ["_label","_classes"];
    private _baseline = _label find "BASELINE-" == 0;
    {
        private _spacing = _x;
        private _id = format ["CNVM-%1-%2",_label,_spacing];
        [_id,"This case creates operating crew, no cargo passengers: all must stay aboard. Watch their labelled vehicles and actual tracks on the 1 km straight, then a deliberate halt/resume. Separate cases test corners. BASELINE labels identify engine-only comparisons.",[2500,2500] call _terrainPosition] call _phase;
        private _group = createGroup [east,true];
        _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
        _group setVariable ["acex_headless_blacklist",true,true];
        private _vehicles=[];
        private _fixtureCrew=[];
        _group setGroupIdGlobal [_id];
        {
            private _vehicle=createVehicle [_x,[2500,2500-_forEachIndex*_spacing] call _terrainPosition,[],0,"NONE"];
            _vehicle setDir _terrainHeading;
            _vehicle setVariable ["Waldo_CortexQA_GapBand",[_spacing*0.8,_spacing*1.2],true];
            createVehicleCrew _vehicle;
            private _vehicleNumber=_forEachIndex+1;
            {
                _fixtureCrew pushBack [_x,_vehicle];
                _x setVariable ["Waldo_CortexQA_Label",format ["%1 / vehicle %2 crew",_id,_vehicleNumber],true];
            } forEach crew _vehicle;
            _vehicle setVariable ["Waldo_CortexQA_Case",_id,true];
            _vehicle setVariable ["Waldo_CortexQA_Exits",[],true];
            _vehicle addEventHandler ["GetOut",{
                params ["_vehicle","_role","_unit"];
                if (isNull _unit) exitWith {}; // Deleted fixture occupants are cleanup, not physical exits.
                private _exits=_vehicle getVariable ["Waldo_CortexQA_Exits",[]];
                _exits pushBack [netId _unit,_role,serverTime,getPosATL _vehicle];
                _vehicle setVariable ["Waldo_CortexQA_Exits",_exits,true];
                diag_log format ["WMP CORTEX QA MATRIX CREW EXIT: case=%1 unit=%2 role=%3 position=%4 assigned=%5 assignedRole=%6 command=%7 convoyActive=%8",_vehicle getVariable ["Waldo_CortexQA_Case",""],netId _unit,_role,getPosATL _unit,assignedVehicle _unit,assignedVehicleRole _unit,currentCommand _unit,_vehicle getVariable ["Waldo_Convoy_Active",false]];
            }];
            private _old=group driver _vehicle;
            (crew _vehicle) joinSilent _group;
            deleteGroup _old;
            {_x setVariable ["acex_headless_blacklist",true,true]} forEach crew _vehicle;
            _vehicles pushBack _vehicle;
        } forEach _classes;
        missionNamespace setVariable ["Waldo_CortexQA_Actors",_fixtureCrew apply {_x select 0},true];
        _group selectLeader driver (_vehicles select 0);
        _group setBehaviour "SAFE";
        _group setCombatMode "BLUE";
        private _wp=_group addWaypoint [[2500,3500] call _terrainPosition,0]; _wp setWaypointType "MOVE";
        _wp=_group addWaypoint [[2900,3500] call _terrainPosition,0]; _wp setWaypointType "MOVE";
        _wp=_group addWaypoint [[2900,3900] call _terrainPosition,0]; _wp setWaypointType "MOVE";
        missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",_vehicles,true];
        if (_baseline) then {
            _group setVariable ["Waldo_AIPass_Exclude",true,true];
            _group setFormation "COLUMN"; _group enableAttack false;
            {
                _x limitSpeed 34.5;
                if (_label != "BASELINE-OMIT-LEAD-GAP" || {_forEachIndex > 0}) then {_x setConvoySeparation _spacing};
                _x setUnloadInCombat [false,false];
            } forEach _vehicles;
            if (_label in ["BASELINE-LEAD-MOVE","BASELINE-MOVE-FORCE"]) then {driver (_vehicles select 0) doMove ([2500,3500] call _terrainPosition)};
            if (_label in ["BASELINE-FORCE-SPEED","BASELINE-MOVE-FORCE"]) then {{_x forceSpeed (30/3.6)} forEach _vehicles};
            (_vehicles select 0) limitSpeed 30;
            if (_label == "BASELINE-DRIVER-FOLLOW") then {{if (_forEachIndex > 0) then {(driver _x) doFollow leader _group}} forEach _vehicles};
            if (_label == "BASELINE-VEHICLE-FOLLOW") then {{if (_forEachIndex > 0) then {_x doFollow leader _group}} forEach _vehicles};
            [_id+"-fixture",count _vehicles == 3 && {_vehicles findIf {!alive driver _x} < 0}] call _check;
        } else {[_id+"-start",[_group,30,_spacing,true] call Waldo_fnc_SimpleAiConvoy] call _check};
        private _origins=_vehicles apply {getPosATL _x};
        private _samples=[0,0,0];
        private _stops=[0,0,0];
        private _restartCounts=[0,0,0];
        private _wasStopped=[false,false,false];
        private _count=0;
        private _maxLateral=0;
        private _gapInBand=[0,0];
        private _minimumGaps=[1e9,1e9];
        private _maximumGaps=[0,0];
        private _orderBroken=false;
        private _start=diag_tickTime;
        private _nextLog=0;
        private _nextFollow=0;
        // Startup is assessed separately so a loop cannot hide inside the warm-up window.
        private _startupTurned=false;
        private _startupBackwards=false;
        for "_sample" from 1 to 40 do {
            {
                if (abs speed _x > 2 && {abs (((getDir _x-_terrainHeading+540) mod 360)-180) > 75}) then {_startupTurned=true};
                private _startupDelta=(getPosATL _x) vectorDiff (_origins select _forEachIndex);
                if ((_startupDelta vectorDotProduct _terrainForward) < -5) then {_startupBackwards=true};
            } forEach _vehicles;
            sleep 0.5;
        };
        [_id+"-startup-no-loop",!_startupTurned && {!_startupBackwards},str [_startupTurned,_startupBackwards]] call _check;
        while {diag_tickTime-_start < 80} do {
            if (_baseline && {diag_tickTime >= _nextFollow}) then {
                _nextFollow=diag_tickTime+5;
                {if (speed _x < 5) then {_x doFollow leader _group}; _x setConvoySeparation _spacing} forEach (_vehicles select [1]);
            };
            {
                // This measurement window is the northbound straight. Measure real
                // geometry, not the group formation flag or accepted movement order.
                if (_forEachIndex > 0) then {
                    private _front=_vehicles select (_forEachIndex-1);
                    private _frontPosition=getPosATL _front;
                    private _gap=_x distance2D _front;
                    private _slot=_forEachIndex-1;
                    private _bodyLengths=0;
                    {private _bounds=boundingBoxReal _x; _bodyLengths=_bodyLengths+abs (((_bounds select 1) select 1)-((_bounds select 0) select 1))} forEach [_x,_front];
                    private _targetGap=_spacing max (_bodyLengths*0.5+5);
                    private _tolerance=(_targetGap*0.2) max 3;
                    private _low=(_targetGap-_tolerance) max (_bodyLengths*0.5+5);
                    private _high=_targetGap+_tolerance;
                    _x setVariable ["Waldo_CortexQA_GapBand",[_low,_high],true];
                    if (_gap >= _low && {_gap <= _high}) then {_gapInBand set [_slot,(_gapInBand select _slot)+1]};
                    _minimumGaps set [_slot,(_minimumGaps select _slot) min _gap];
                    _maximumGaps set [_slot,(_maximumGaps select _slot) max _gap];
                    _maxLateral=_maxLateral max abs (((getPosATL _x) vectorDiff _frontPosition) vectorDotProduct _terrainRight);
                };
                if (_forEachIndex > 0 && {(((getPosATL _x) vectorDiff (getPosATL (_vehicles select (_forEachIndex-1)))) vectorDotProduct _terrainForward) > 3}) then {_orderBroken=true};
                private _v=abs speed _x;
                private _i=_forEachIndex;
                _samples set [_i,(_samples select _i)+_v];
                private _stopped=_v < 2;
                if (_stopped) then {_stops set [_i,(_stops select _i)+1]};
                if (!_stopped && {_wasStopped select _i}) then {_restartCounts set [_i,(_restartCounts select _i)+1]};
                _wasStopped set [_i,_stopped];
            } forEach _vehicles;
            _count=_count+1;
            if (diag_tickTime >= _nextLog) then {
                _nextLog=diag_tickTime+5;
                diag_log format ["WMP CORTEX QA CONVOY MATRIX: case=%1 speeds=%2 forced=%3 gaps=%4 motion=%5 formation=%6 steering=%7",_id,_vehicles apply {speed _x},_vehicles apply {getForcedSpeed _x},[(_vehicles select 1) distance2D (_vehicles select 0),(_vehicles select 2) distance2D (_vehicles select 1)],_vehicles apply {[getDir _x,currentCommand driver _x,expectedDestination driver _x,getPosATL _x]},formation _group,_vehicles apply {isAISteeringComponentEnabled _x}];
            };
            sleep 1;
        };
        [_id+"-single-file",_count >= 40 && {_maxLateral <= 8} && {!_orderBroken},format ["maximum predecessor lateral offset=%1 m; order broken=%2",_maxLateral,_orderBroken]] call _check;
        [_id+"-spacing-band",_count >= 40 && {_gapInBand findIf {_x / (_count max 1) < 0.8} < 0},
            format ["in-band samples=%1/%2 min=%3 max=%4",_gapInBand,_count,_minimumGaps,_maximumGaps]] call _check;
        private _averages=_samples apply {_x/(_count max 1)};
        [_id+"-continuous-speed",_count >= 40 && {_averages findIf {_x < 18} < 0},str _averages] call _check;
        [_id+"-stop-fraction",_count >= 40 && {_stops findIf {_x/(_count max 1) > 0.1} < 0},str [_stops,_count]] call _check;
        [_id+"-restart-count",_restartCounts findIf {_x > 2} < 0,str _restartCounts] call _check;
        private _travelled=true;
        {if (_x distance2D (_origins select _forEachIndex) < 300) then {_travelled=false}} forEach _vehicles;
        [_id+"-physical-progress",_travelled,str (_vehicles apply {getPosATL _x})] call _check;
        if (!_baseline) then {
            diag_log format ["WMP CORTEX QA HALT SEATS BEFORE: case=%1 seats=%2",_id,_vehicles apply {fullCrew [_x,"",false]}];
            [_group,0,_spacing,true] call Waldo_fnc_SimpleAiConvoy;
            private _registeredHalt=(missionNamespace getVariable ["Waldo_Convoy_Registry",[]]) select {(_x select 0) == _group};
            diag_log format ["WMP CORTEX QA HALT REQUEST: case=%1 registry=%2",_id,_registeredHalt];
            private _halted=[{_vehicles findIf {abs speed _x > 1} < 0},20] call _wait;
            [_id+"-halt-stationary",_halted,str (_vehicles apply {[speed _x,getForcedSpeed _x,currentCommand driver _x,expectedDestination driver _x,owner _x]})] call _check;
            {
                diag_log format ["WMP CORTEX QA HALT COMMANDERS: case=%1 vehicle=%2 effective=%3 crew=%4",_id,_forEachIndex,effectiveCommander _x,
                    (crew _x) apply {[assignedVehicleRole _x,currentCommand _x,expectedDestination _x]}];
            } forEach _vehicles;
            private _restartOrigins=_vehicles apply {getPosATL _x};
            [_id+" restart","Same straight route after a deliberate stop: every vehicle must resume forwards without a U-turn or long hold. Heading and actual destinations are recorded.",getPosATL (_vehicles select 1)] call _phase;
            [_id+"-resume-accepted",[_group,30,_spacing,true] call Waldo_fnc_SimpleAiConvoy] call _check;
            private _turned=false;
            private _resumed=[{
                private _moving=true;
                {
                    if (abs speed _x > 2 && {abs (((getDir _x-_terrainHeading+540) mod 360)-180) > 75}) then {_turned=true};
                    if (_x distance2D (_restartOrigins select _forEachIndex) < 60 || {abs speed _x < 10}) then {_moving=false};
                } forEach _vehicles;
                _moving
            },60] call _wait;
            [_id+"-resume-forward-progress",_resumed] call _check;
            [_id+"-resume-no-turnaround",!_turned] call _check;
        };
        [_id+"-operating-crew-retained",_fixtureCrew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)}} < 0 && {_vehicles findIf {(_x getVariable ["Waldo_CortexQA_Exits",[]]) isNotEqualTo []} < 0},str (_vehicles apply {_x getVariable ["Waldo_CortexQA_Exits",[]]})] call _check;
        if (!_baseline) then {[_group,0,_spacing,true,true] call Waldo_fnc_SimpleAiConvoy};
        // Delete the original fixture roster, including anyone now on foot or in another seat.
        {deleteVehicle (_x select 0)} forEach _fixtureCrew;
        [_id+"-fixture-cleanup",[{_fixtureCrew findIf {!isNull (_x select 0)} < 0},10] call _wait] call _check;
        missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
        {private _v=_x; {deleteVehicle _x} forEach crew _v; deleteVehicle _v} forEach _vehicles;
        deleteGroup _group;
        missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",[],true];
    } forEach (if (_diagnostic) then {[30]} else {if (_columnOnly) then {[30,50]} else {[[15,30,50,75],[50]] select _baseline}});
} forEach _types;
