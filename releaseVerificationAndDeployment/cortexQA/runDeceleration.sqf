/*
 * Author: WaldoTheWarfighter
 * Compares real cruise braking with correction disabled, enabled and explicitly excluded, using
 * ordinary flight orders and physical speed/route evidence.
 * Locality/authority: scheduled server fixture; the production aircraft-owner tracker applies correction.
 * Repeat/JIP: fresh aircraft per case, public actors/trails, original enable setting restored; the
 * per-aircraft exclusion is confined to its disposable fixture and there is no JIP runner.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required audit callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQADeceleration.sqf";
 */
params ["_check","_phase","_wait"];
private _saved=missionNamespace getVariable ["Waldo_HelicopterDeceleration_Enable",false];
private _results=[];
{
    private _enabled=_x;
    private _id=["DECEL-disabled","DECEL-enabled"] select _enabled;
    missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable",_enabled,true];
    if (_enabled) then {[] call Waldo_fnc_HelicopterDecelerationInit};
    private _aircraft=createVehicle ["B_Heli_Light_01_F",[4500,4500,120],[],0,"FLY"];
    _aircraft setDir 0;
    createVehicleCrew _aircraft;
    private _crew=crew _aircraft;
    private _group=group driver _aircraft;
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _group setVariable ["Waldo_AIPass_Exclude",true,true];
    {_x setVariable ["acex_headless_blacklist",true,true]} forEach _crew;
    _group setBehaviour "CARELESS";
    _group setCombatMode "BLUE";
    _aircraft flyInHeight 120;
    _aircraft setVariable ["Waldo_CortexQA_Label",_id,true];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[_aircraft],true];
    private _wp=_group addWaypoint [[4500,6500,120],0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    [_id+": cruise","The helicopter must reach genuine cruise speed before braking. Cyan trails show its actual flight; no velocity is injected.",[4500,4800,120]] call _phase;
    private _cruise=[{alive _aircraft && {speed _aircraft >= 120} && {(getPosATL _aircraft select 2) >= 80}},90] call _wait;
    [_id+"-cruise-stimulus",_cruise,str [speed _aircraft,getPosATL _aircraft]] call _check;
    [_id+": braking","Watch speed fall and the nose rise during the approach. The enabled flight must limit climb to 10 m in this level-flight fixture and improve on the disabled flight. Travel, clearance and crew retention are measured.",getPosATL _aircraft] call _phase;
    private _startSpeed=abs speed _aircraft;
    private _start=getPosATL _aircraft;
    private _brake=_aircraft getPos [250,getDir _aircraft];
    _brake set [2,120];
    _wp setWaypointPosition [_brake,0];
    _wp setWaypointSpeed "LIMITED";
    _aircraft setVariable ["Waldo_CortexQA_Target",_brake,true];
    private _peak=_start select 2;
    private _minimum=_start select 2;
    private _lowestSpeed=_startSpeed;
    private _activeSeen=false;
    for "_sample" from 1 to 120 do {
        sleep 0.25;
        private _alt=getPosATL _aircraft select 2;
        _peak=_peak max _alt;
        _minimum=_minimum min _alt;
        _lowestSpeed=_lowestSpeed min abs speed _aircraft;
        _activeSeen=_activeSeen || {_aircraft getVariable ["Waldo_HelicopterDeceleration_Active",false]};
        if (_sample % 4 == 0) then {
            _aircraft setVariable ["Waldo_CortexQA_Deceleration",[round _alt,round (_peak-(_start select 2)),_activeSeen,_aircraft getVariable ["Waldo_HelicopterDeceleration_Active",false]],true];
        };
    };
    private _gain=_peak-(_start select 2);
    [_id+"-physical-braking",_cruise && {_startSpeed-_lowestSpeed >= 30},str [_startSpeed,_lowestSpeed]] call _check;
    [_id+"-flight-safe",alive _aircraft && {_minimum >= 25} && {_crew findIf {!alive _x || {vehicle _x != _aircraft}} < 0},str [_minimum,damage _aircraft]] call _check;
    [_id+"-forward-travel",_aircraft distance2D _start >= 50,str (_aircraft distance2D _start)] call _check;
    if (!_enabled) then {[_id+"-no-correction",!_activeSeen] call _check};
    [_id+"-authored-route-preserved",waypointType _wp == "MOVE" && {(waypointPosition _wp) distance2D _brake < 1} && {waypointSpeed _wp == "LIMITED"},str [waypointPosition _wp,waypointType _wp,waypointSpeed _wp]] call _check;
    _results pushBack [_gain,_activeSeen,_cruise,_startSpeed,_start select 2];
    diag_log format ["WMP CORTEX QA DECEL: case=%1 peakGain=%2 activeSeen=%3 minimumAltitude=%4",_id,_gain,_activeSeen,_minimum];
    {deleteVehicle _x} forEach _crew;
    deleteVehicle _aircraft; deleteGroup _group;
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    sleep 3;
} forEach [false,true];
private _baseline=_results select 0;
private _corrected=_results select 1;
private _comparable=abs ((_baseline select 3)-(_corrected select 3)) <= 10 && {abs ((_baseline select 4)-(_corrected select 4)) <= 5};
["DECEL-comparable-entry-conditions",_comparable,str _results] call _check;
["DECEL-enabled-correction-observed",_corrected select 1,str _results] call _check;
["DECEL-comparison-climb-stimulus",(_baseline select 2) && {(_baseline select 0) >= 2},str _results] call _check;
["DECEL-physical-climb-reduced",_comparable && {(_corrected select 2)} && {(_baseline select 0) >= 2} && {(_corrected select 0) < (_baseline select 0)*0.9},str _results] call _check;
// This clear, level-flight fixture starts near 120 m. Ten metres allows a modest
// braking flare; a large zoom-climb must fail even when the baseline is worse.
["DECEL-operational-climb-limit",(_corrected select 2) && {(_corrected select 0) <= 10},format ["peak climb=%1 m; allowed=10 m",_corrected select 0]] call _check;

// A per-aircraft opt-out is a separate public control from the mission-wide switch. Exercise the
// real tracker envelope while enabled so merely observing a quiet or stationary aircraft cannot
// pass this exclusion case.
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable",true,true];
[] call Waldo_fnc_HelicopterDecelerationInit;
private _excludedAircraft=createVehicle ["B_Heli_Light_01_F",[4700,4500,120],[],0,"FLY"];
_excludedAircraft setDir 0;
_excludedAircraft setVariable ["Waldo_HelicopterDeceleration_Exclude",true,true];
createVehicleCrew _excludedAircraft;
private _excludedCrew=crew _excludedAircraft;
private _excludedGroup=group driver _excludedAircraft;
_excludedGroup setVariable ["Waldo_Headless_ExcludeGroup",true,true];
_excludedGroup setVariable ["acex_headless_blacklist",true,true];
_excludedGroup setVariable ["Waldo_AIPass_Exclude",true,true];
{_x setVariable ["acex_headless_blacklist",true,true]} forEach _excludedCrew;
_excludedGroup setBehaviour "CARELESS";
_excludedGroup setCombatMode "BLUE";
_excludedAircraft flyInHeight 120;
_excludedAircraft setVariable ["Waldo_CortexQA_Label","DECEL excluded aircraft",true];
missionNamespace setVariable ["Waldo_CortexQA_Actors",[_excludedAircraft],true];
private _excludedWp=_excludedGroup addWaypoint [[4700,6500,120],0];
_excludedWp setWaypointType "MOVE";
_excludedWp setWaypointSpeed "FULL";
["DECEL exclusion: live braking envelope","This aircraft has the documented per-aircraft exclusion. It must reach cruise speed and physically slow for an ordinary LIMITED waypoint without Cortex ever acquiring the correction controller.",[4700,4800,120]] call _phase;
private _excludedCruise=[{alive _excludedAircraft && {speed _excludedAircraft >= 120} && {(getPosATL _excludedAircraft select 2) >= 80}},90] call _wait;
private _excludedStart=getPosATL _excludedAircraft;
private _excludedBrake=_excludedAircraft getPos [250,getDir _excludedAircraft];
_excludedBrake set [2,120];
_excludedWp setWaypointPosition [_excludedBrake,0];
_excludedWp setWaypointSpeed "LIMITED";
_excludedAircraft setVariable ["Waldo_CortexQA_Target",_excludedBrake,true];
private _excludedActive=false;
for "_sample" from 1 to 120 do {
    sleep 0.25;
    _excludedActive=_excludedActive || {_excludedAircraft getVariable ["Waldo_HelicopterDeceleration_Active",false]};
};
["DECEL-aircraft-exclusion-live-envelope",_excludedCruise && {!_excludedActive},str [speed _excludedAircraft,_excludedAircraft distance2D _excludedStart]] call _check;
["DECEL-aircraft-exclusion-route-preserved",waypointType _excludedWp == "MOVE" && {(waypointPosition _excludedWp) distance2D _excludedBrake < 1} && {waypointSpeed _excludedWp == "LIMITED"},str [waypointPosition _excludedWp,waypointType _excludedWp,waypointSpeed _excludedWp]] call _check;
{deleteVehicle _x} forEach _excludedCrew;
deleteVehicle _excludedAircraft;
deleteGroup _excludedGroup;
missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
missionNamespace setVariable ["Waldo_HelicopterDeceleration_Enable",_saved,true];
