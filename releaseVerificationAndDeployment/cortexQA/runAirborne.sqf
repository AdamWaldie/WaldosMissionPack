/*
 * Author: WaldoTheWarfighter
 * Checks a moving aircraft drop, physical flight, parachutes, landing, retained backpacks and operating crew.
 * Locality/authority: scheduled server creates fixtures; passenger owner executes the public order.
 * Repeat/JIP: fresh flight per run; public actor overlay, all surviving fixtures cleaned afterwards.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>, required callbacks.
 * 3: chute override <STRING>, default empty; audit-only invalid-class fallback variant.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQAAirborne.sqf";
 */
params ["_check","_phase","_wait",["_chuteOverride","",[""]]];
private _savedChute=missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE","NonSteerable_Parachute_F"];
if (_chuteOverride != "") then {missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE",_chuteOverride,true]};
[createHashMapFromArray [["Waldo_AIPass_Enable",true],["Waldo_AIPass_Contact_Enable",false],["Waldo_AIPass_Airborne_Enable",false],["Waldo_AIPass_Regroup_Enable",false]]] call Waldo_fnc_CortexTuning;
private _aircraft=createVehicle ["O_Heli_Light_02_unarmed_F",[1800,1100,180],[],0,"FLY"];
createVehicleCrew _aircraft;
private _pilotGroup=group driver _aircraft;
_pilotGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_pilotGroup setVariable ["acex_headless_blacklist",true,true];
_pilotGroup setVariable ["Waldo_AIPass_Exclude",true,true];
_aircraft flyInHeight 180;
_aircraft allowDamage false;
private _crew=crew _aircraft;
{_x setVariable ["acex_headless_blacklist",true,true]; _x allowDamage false} forEach _crew;
private _cargo=createGroup [east,true];
_cargo setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_cargo setVariable ["acex_headless_blacklist",true,true];
private _jumpers=[];
for "_i" from 0 to 1 do {
    private _unit=_cargo createUnit ["O_Soldier_F",[1790+_i*3,1090,0],[],0,"NONE"];
    _unit setVariable ["acex_headless_blacklist",true,true];
    _unit setVariable ["Waldo_CortexQA_Label",format ["PARACHUTIST %1",_i+1],true];
    _unit addEventHandler ["GetInMan",{
        params ["_unit","_role","_vehicle"];
        diag_log format ["WMP CORTEX AIRBORNE BOARD|unit=%1 vehicle=%2 role=%3 position=%4 owner=%5",netId _unit,typeOf _vehicle,_role,getPosATL _vehicle,owner _unit];
    }];
    _unit addEventHandler ["GetOutMan",{
        params ["_unit","_role","_vehicle"];
        diag_log format ["WMP CORTEX AIRBORNE EXIT|unit=%1 vehicle=%2 position=%3 velocity=%4",netId _unit,typeOf _vehicle,getPosATL _unit,velocity _unit];
    }];
    _unit addEventHandler ["Killed",{
        params ["_unit","_killer"];
        diag_log format ["WMP CORTEX AIRBORNE DEATH|unit=%1 vehicle=%2 position=%3 velocity=%4 killer=%5",netId _unit,typeOf vehicle _unit,getPosATL _unit,velocity _unit,_killer];
    }];
    _unit addBackpack "B_FieldPack_ocamo";
    _unit addItemToBackpack "FirstAidKit";
    _unit assignAsCargo _aircraft;
    _unit moveInCargo _aircraft;
    _jumpers pushBack _unit;
};
// Start a real pilot-controlled run after boarding. No velocity injection or fixture teleport.
private _flightOrigin=getPosATL _aircraft;
private _flightDestination=_flightOrigin vectorAdd [0,4000,0];
private _flightWaypoint=_pilotGroup addWaypoint [_flightDestination,0];
_flightWaypoint setWaypointType "MOVE";
_flightWaypoint setWaypointBehaviour "CARELESS";
_flightWaypoint setWaypointSpeed "NORMAL";
_aircraft limitSpeed 100;
private _packs=_jumpers apply {[backpack _x,backpackItems _x]};
diag_log format ["WMP CORTEX AIRBORNE CONFIG|chute=%1",missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE","NonSteerable_Parachute_F"]];
missionNamespace setVariable ["Waldo_CortexQA_Actors",_jumpers+_crew,true];
["Airborne disabled: passengers retained","Automatic insertion is off. Both passengers must remain in the live helicopter; the following explicit order is a separate supported control.",[1800,1100,100]] call _phase;
sleep 8;
["AIRBORNE-disabled-passengers-retained",_jumpers findIf {vehicle _x != _aircraft} < 0] call _check;
private _owners=(missionNamespace getVariable ["Waldo_Headless_Clients",[]]) apply {_x select 0};
if (_owners isNotEqualTo []) then {
    [_cargo,_owners select 0] call Waldo_fnc_HeadlessMigrateGroup;
    ["AIRBORNE-flight-owner-preserved",groupOwner _cargo == 2 && {owner _aircraft == 2},"WMP intentionally refuses migration of helicopter occupants during flight"] call _check;
};
private _high=[{(getPosATL _aircraft select 2) >= 120 && {speed _aircraft >= 50} && {_aircraft distance2D _flightOrigin >= 100}},60] call _wait;
["AIRBORNE-moving-flight-precondition",_high,format ["speed=%1 km/h travel=%2 m altitude=%3 m",speed _aircraft,_aircraft distance2D _flightOrigin,getPosATL _aircraft select 2]] call _check;
["AIRBORNE-flight-precondition",_high && {simulationEnabled _aircraft} && {alive driver _aircraft}] call _check;
["Airborne: explicit drop across owners","Watch each passenger leave the moving helicopter, descend in a parachute, then physically reach the ground. The aircraft must first travel 100 m and reach 50 km/h. The pilot stays aboard. Backpack contents must survive the whole drop.",getPosATL _aircraft] call _phase;
["AIRBORNE-order-accepted",[_cargo] call Waldo_fnc_CortexAirborneDrop] call _check;
["AIRBORNE-repeat-order-refused",!([_cargo] call Waldo_fnc_CortexAirborneDrop),"A second immediate order must not queue another drop for the same aircraft"] call _check;
private _dropOrigin=getPosATL _aircraft;
private _seen=[false,false];
private _chutes=[];
private _parachuteControllerConflict=false;
private _nextFlightSample=0;
private _landed=[{
    if (time >= _nextFlightSample) then {
        _nextFlightSample=time+1;
        diag_log format ["WMP CORTEX AIRBORNE SAMPLE|actors=%1",_jumpers apply {[netId _x,alive _x,typeOf vehicle _x,getPosATL _x,velocity _x,isDamageAllowed _x,owner _x]}];
        private _jobs=(missionNamespace getVariable ["Waldo_AIPass_Jobs",[]]) select {((_x select 2) getOrDefault ["group",grpNull]) == _cargo};
        diag_log format ["WMP CORTEX AIRBORNE JOB|dropping=%1 epoch=%2 adopted=%3 hold=%4 jobs=%5",
            _cargo getVariable ["Waldo_AIPass_Dropping",false],_cargo getVariable ["Waldo_AIPass_Epoch",0],
            _cargo getVariable ["Waldo_AIPass_Adopted",false],_cargo getVariable ["Waldo_AIPass_ZeusHold",[]],
            _jobs apply {private _state=_x select 2; [_x select 0,_state getOrDefault ["phase",""],_state getOrDefault ["ownerEpoch",-1]]}];
    };
    {if (vehicle _x isKindOf "ParachuteBase") then {_seen set [_forEachIndex,true]; _chutes pushBackUnique vehicle _x}} forEach _jumpers;
    if (_chutes findIf {_x getVariable ["Waldo_Headless_HelicopterPinned",false] || {_x getVariable ["Waldo_ImprovedHelicopterLanding_LocalHandlerInstalled",false]}} >= 0) then {_parachuteControllerConflict=true};
    _seen findIf {!_x} < 0 && {_jumpers findIf {!alive _x || {vehicle _x != _x} || {getPosATL _x select 2 > 2}} < 0}
},170] call _wait;
["AIRBORNE-aircraft-continued-flight",_aircraft distance2D _dropOrigin >= 100,format ["aircraft travel after order=%1 m",_aircraft distance2D _dropOrigin]] call _check;
["AIRBORNE-parachutes-not-helicopter-controlled",(_seen findIf {_x} >= 0) && {!_parachuteControllerConflict},format ["observed=%1 controllerConflict=%2",_seen,_parachuteControllerConflict]] call _check;
["AIRBORNE-each-parachute-seen",_seen findIf {!_x} < 0,str _seen] call _check;
["AIRBORNE-physical-landing",_landed,str (_jumpers apply {[alive _x,typeOf vehicle _x,getPosATL _x]})] call _check;
["AIRBORNE-backpack-preserved",(_jumpers apply {[backpack _x,backpackItems _x]}) isEqualTo _packs] call _check;
["AIRBORNE-operating-crew-retained",_crew findIf {!alive _x || {vehicle _x != _aircraft}} < 0] call _check;
if (_landed) then {
    ["AIRBORNE-ground-order-refused",!([_cargo] call Waldo_fnc_CortexAirborneDrop)] call _check;
    private _origins=_jumpers apply {getPosATL _x};
    // Put the destination beyond every landing position. A leader-relative point
    // can leave a dispersed passenger already inside the arrival radius.
    private _destination=+(getPosATL leader _cargo);
    private _north=(_origins select 0) select 1;
    {_north=_north max (_x select 1)} forEach _origins;
    _destination set [1,_north+70];
    _destination set [2,0];
    ["AIRBORNE-ground-route-prerequisite",_origins findIf {_x distance2D _destination < 65} < 0,str [_origins,_destination]] call _check;
    ["Airborne: movement after landing","Both landed passengers must walk at least 30 m toward a new ground waypoint. This catches parachute cleanup that leaves soldiers unable to move.",_destination] call _phase;
    while {count waypoints _cargo > 0} do {deleteWaypoint [_cargo,0]};
    private _waypoint=_cargo addWaypoint [_destination,0];
    _waypoint setWaypointType "MOVE";
    _waypoint setWaypointBehaviour "AWARE";
    private _moved=[{
        private _allMoved=true;
        {
            if (!alive _x || {vehicle _x != _x} || {_x distance2D (_origins select _forEachIndex) < 30} || {_x distance2D _destination > 35}) then {_allMoved=false};
        } forEach _jumpers;
        _allMoved
    },75] call _wait;
    private _movementEvidence=[];
    {_movementEvidence pushBack [netId _x,_x distance2D (_origins select _forEachIndex),_x distance2D _destination,getPosATL _x]} forEach _jumpers;
    ["AIRBORNE-post-landing-movement",_moved,str _movementEvidence] call _check;
} else {
    ["AIRBORNE-post-landing-movement",false,"Prerequisite failed: both passengers did not land alive"] call _check;
};
sleep 15;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
{deleteVehicle _x} forEach (_jumpers+_crew+_chutes+[_aircraft]);
deleteGroup _cargo; deleteGroup _pilotGroup;

missionNamespace setVariable ["WALDO_STATIC_STATICCHUTE",_savedChute,true];
