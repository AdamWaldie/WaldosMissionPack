/*
 * Author: WaldoTheWarfighter
 * Tests wheeled and tracked escort retention for operating crew, same-group cargo and separate mounted
 * squads. VR keeps a deterministic route; terrain worlds rotate the full 2.5 km journey onto a
 * measured dry corridor so inclines and rough ground are present during travel and owner migration.
 * Locality/authority: scheduled server creates actors; production convoy workers own all commands.
 * Repeat/JIP: fresh case-labelled actors, public observer state; complete roster cleanup, including dismounts.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQASeats.sqf";
 */
params ["_recordCheck","_phase","_wait"];
private _terrainOrigin=[4000,2500,0];
private _terrainHeading=0;
private _terrainReady=worldName == "VR";
private _terrainRelief=0;
if (!_terrainReady) then {
    private _bestScore=-1;
    private _gridStep=(worldSize/10) max 900;
    for "_gridX" from 2 to 8 do {
        for "_gridY" from 2 to 8 do {
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
                    for "_along" from -80 to 2500 step 50 do {
                        private _sample=_candidateOrigin vectorAdd (_right vectorMultiply _lane)
                            vectorAdd (_forward vectorMultiply _along);
                        private _inside=(_sample select 0) > 300 && {(_sample select 1) > 300}
                            && {(_sample select 0) < worldSize-300} && {(_sample select 1) < worldSize-300};
                        private _height=getTerrainHeightASL _sample;
                        if (!_inside || {surfaceIsWater _sample} || {((surfaceNormal _sample) select 2) < 0.65}) then {_safe=false};
                        if (_previous isNotEqualTo []) then {
                            private _grade=abs (_height-_previousHeight)/((_sample distance2D _previous) max 1);
                            if (_grade > 0.8) then {_safe=false};
                        };
                        _heights pushBack _height;
                        _previous=_sample;
                        _previousHeight=_height;
                    };
                } forEach [-20,0,20];
                private _relief=if (_heights isEqualTo []) then {0} else {(selectMax _heights)-(selectMin _heights)};
                if (_safe && {_relief >= 40} && {_relief <= 260} && {_relief > _bestScore}) then {
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
    _terrainOrigin vectorAdd (_terrainRight vectorMultiply ((_local select 0)-4000))
        vectorAdd (_terrainForward vectorMultiply ((_local select 1)-2500))
};
["SEATS-terrain-scenario",_terrainReady,
    format ["world=%1 origin=%2 heading=%3 relief=%4",worldName,_terrainOrigin,_terrainHeading,_terrainRelief]] call _recordCheck;
if (!_terrainReady) then {
    ["Convoy seats: no evaluative terrain","No dry three-lane 2.5 km corridor provided 40-260 m relief without unsafe slope or grade. Seat cases are skipped rather than falling back to flat geometry.",_terrainOrigin] call _phase;
} else {
{
_x params ["_prefix","_leadClass"];
private _check={params ["_id","_passed",["_detail",""]]; [_prefix+_id,_passed,_detail] call _recordCheck};
private _convoy=createGroup [east,true];
private _cargoGroup=createGroup [east,true];
{_x setVariable ["Waldo_Headless_ExcludeGroup",true,true]; _x setVariable ["acex_headless_blacklist",true,true]} forEach [_convoy,_cargoGroup];
_convoy setGroupIdGlobal ["QA SEATS operating crew + same-group cargo"];
_cargoGroup setGroupIdGlobal ["QA SEATS separate cargo squad"];
private _vehicles=[];
private _crew=[];
{
    private _v=createVehicle [_x,[[4000,2500-_forEachIndex*50,0]] call _terrainPosition,[],0,"NONE"];
    _v setDir _terrainHeading; createVehicleCrew _v;
    private _old=group driver _v;
    _crew append (crew _v apply {[_x,_v]});
    (crew _v) joinSilent _convoy; deleteGroup _old;
    _vehicles pushBack _v;
} forEach [_leadClass,"O_Truck_03_transport_F"];
private _truck=_vehicles select 1;
private _passengers=[];
{
    private _g=_x;
    for "_i" from 0 to 1 do {
        private _u=_g createUnit ["O_Soldier_F",[[4000,2430,0]] call _terrainPosition,[],0,"NONE"];
        // Intentional setup: physically mounted cargo with no orderGetIn repair by the test.
        // Production must adopt that actual seat, including a separate-group squad leader.
        _u moveInCargo _truck;
        _u setVariable ["Waldo_CortexQA_Label",["SAME-GROUP CARGO","SEPARATE-GROUP CARGO"] select (_g == _cargoGroup),true];
        _passengers pushBack _u;
    };
} forEach [_convoy,_cargoGroup];
private _actors=(_crew apply {_x select 0})+_passengers;
{(_x select 0) setVariable ["Waldo_CortexQA_Label","OPERATING CREW: STAYS ABOARD",true]} forEach _crew;
{
    _x setVariable ["acex_headless_blacklist",true,true];
    _x setVariable ["Waldo_CortexQA_ExitEvents",[],true];
    _x addEventHandler ["GetOutMan",{
        params ["_u","_role","_v"];
        private _phase=missionNamespace getVariable ["Waldo_CortexQA_SeatPhase","SETUP"];
        private _events=_u getVariable ["Waldo_CortexQA_ExitEvents",[]];
        _events pushBack [_phase,_role,serverTime];
        _u setVariable ["Waldo_CortexQA_ExitEvents",_events,true];
        diag_log format ["WMP CORTEX QA SEAT EXIT: label=%1 phase=%2 role=%3 command=%4 assignedRole=%5",_u getVariable ["Waldo_CortexQA_Label",""],_phase,_role,currentCommand _u,assignedVehicleRole _u];
    }];
} forEach _actors;
_convoy selectLeader driver (_vehicles select 0);
{_x setCombatMode "BLUE"} forEach [_convoy,_cargoGroup];
private _wp=_convoy addWaypoint [[[4000,5000,0]] call _terrainPosition,0]; _wp setWaypointType "MOVE";
missionNamespace setVariable ["Waldo_CortexQA_Actors",_actors,true];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",_vehicles,true];
missionNamespace setVariable ["Waldo_CortexQA_SeatPhase","TRAVEL",true];
["SEATS-start",[_convoy,30,50,true] call Waldo_fnc_SimpleAiConvoy] call _check;
["Convoy seat retention","Two operating vehicles carry both same-group cargo and a separate mounted squad over the measured terrain route. All labelled actors must stay aboard throughout travel. No test command repairs their seats after setup.",[[4000,2475,0]] call _terrainPosition] call _phase;
private _start=getPosATL _truck;
sleep 60;
["SEATS-real-travel",_truck distance2D _start > 150,str getPosATL _truck] call _check;
["SEATS-travel-no-exits",_actors findIf {(_x getVariable ["Waldo_CortexQA_ExitEvents",[]]) isNotEqualTo []} < 0,str (_actors apply {[_x getVariable ["Waldo_CortexQA_Label",""],_x getVariable ["Waldo_CortexQA_ExitEvents",[]]]})] call _check;
["SEATS-all-cargo-still-mounted",_passengers findIf {!alive _x || {vehicle _x != _truck}} < 0] call _check;
["SEATS-operating-crew-still-mounted",_crew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)}} < 0] call _check;
// Split the vehicle controller and the separate passenger squad across real owners.
private _owners=(missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0};
["SEATS-two-headless-clients",count _owners >= 2] call _check;
if (count _owners >= 2) then {
    private _convoyOwner=_owners select 0;
    private _cargoOwner=_owners select 1;
    // Release the fixture-only server pin before exercising the real migration API.
    {_x setVariable ["Waldo_Headless_ExcludeGroup",false,true]} forEach [_convoy,_cargoGroup];
    [_cargoGroup,_cargoOwner] call Waldo_fnc_HeadlessMigrateGroup;
    [_convoy,_convoyOwner] call Waldo_fnc_HeadlessMigrateGroup;
    ["SEATS-split-owner-adoption",[{
        groupOwner _cargoGroup == _cargoOwner && {groupOwner _convoy == _convoyOwner}
        && {_vehicles findIf {owner _x != _convoyOwner || {owner driver _x != _convoyOwner}} < 0}
    },30] call _wait] call _check;
    ["Convoy seats across headless clients","The operating crew and same-group cargo now run on HC1; the separate passenger squad runs on HC2. Every actor must remain aboard while the truck physically continues. The following halt must unload cargo across both owners.",getPosATL _truck] call _phase;
    private _splitStart=getPosATL _truck;
    private _unexpectedExit=false;
    private _until=diag_tickTime+45;
    waitUntil {
        if (_passengers findIf {!alive _x || {vehicle _x != _truck}} >= 0
            || {_crew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)}} >= 0}) then {_unexpectedExit=true};
        sleep 0.2;
        diag_tickTime >= _until
    };
    ["SEATS-split-owner-no-dismount",!_unexpectedExit] call _check;
    ["SEATS-split-owner-real-travel",_truck distance2D _splitStart > 100,str getPosATL _truck] call _check;
};
missionNamespace setVariable ["Waldo_CortexQA_SeatPhase","MANUAL HALT",true];
["Convoy commanded unload","A deliberate halt now requires all four cargo soldiers to exit and move clear. Driver, gunner and commander must stay aboard. Labels distinguish their roles.",getPosATL _truck] call _phase;
[_convoy,0,50,true] call Waldo_fnc_SimpleAiConvoy;
["SEATS-same-and-separate-cargo-exit",[{_passengers findIf {!alive _x || {vehicle _x != _x}} < 0},40] call _wait] call _check;
["SEATS-halt-operating-crew-retained",_crew findIf {!alive (_x select 0) || {vehicle (_x select 0) != (_x select 1)} || {((_x select 0) getVariable ["Waldo_CortexQA_ExitEvents",[]]) isNotEqualTo []}} < 0] call _check;
sleep 10;
[_convoy,0,50,true,true] call Waldo_fnc_SimpleAiConvoy;
{deleteVehicle _x} forEach _actors;
{deleteVehicle _x} forEach _vehicles;
deleteGroup _convoy; deleteGroup _cargoGroup;
["SEATS-cleanup-includes-dismounted",[{_actors findIf {!isNull _x} < 0},10] call _wait] call _check;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
missionNamespace setVariable ["Waldo_CortexQA_ConvoyVehicles",[],true];

} forEach [["","O_MRAP_02_hmg_F"],["TRACKED-","O_APC_Tracked_02_cannon_F"]];
};
