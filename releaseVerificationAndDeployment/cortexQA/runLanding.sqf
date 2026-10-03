/*
 * Author: WaldoTheWarfighter
 * Tests actual helicopter touchdown and cancelled landing orders on a clear-ground fixture.
 * Locality/authority: scheduled server audit, using the public landing configuration and live waypoints.
 * Repeat/JIP: fresh aircraft per case; settings restored, public labels/trails; only owned fixtures deleted.
 * Arguments: check <CODE>, phase <CODE>, wait <CODE>; required callbacks.
 * Return: Nothing. Current caller: cortexQAServer.sqf.
 * Example: [_check,_phase,_wait] call compile preprocessFileLineNumbers "cortexQALanding.sqf";
 */
params ["_check","_phase","_wait"];
private _names=["Enable","MinimumActivationDistance","TransitAltitude","GlideSlopeRatio","TreeScanRadius","TreeSafetyBuffer","GoAroundHeight","MaximumClimbRate","MaximumDescentRate","MaximumGoArounds","TouchdownHoldSeconds"];
private _defaults=[true,50,30,4,25,5,150,8,10,1,20];
private _saved=[];
{_saved pushBack (missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_"+_x,_defaults select _forEachIndex])} forEach _names;
private _beforeInvalid=missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable",false];
["LAND-reject-short-payload",!([[true,50]] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer)] call _check;
["LAND-reject-wrong-enabled-type",!([[1,50,30,4,25,5,150,8,10,1,20]] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer)] call _check;
["LAND-reject-wrong-numeric-type",!([[true,"bad",30,4,25,5,150,8,10,1,20]] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer)] call _check;
["LAND-invalid-payload-preserves-setting",(missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_Enable",false]) isEqualTo _beforeInvalid] call _check;
{
    private _cancel=_x;
    [[true,50,30,4,25,5,150,8,10,1,20]] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer;
    private _target=[4500,5000,0];
    private _aircraft=createVehicle ["O_Heli_Light_02_unarmed_F",[4500,4500,70],[],0,"FLY"];
    _aircraft setDir 0;
    createVehicleCrew _aircraft;
    private _crew=crew _aircraft;
    private _group=group driver _aircraft;
    _group setVariable ["Waldo_Headless_ExcludeGroup",true,true];
    _group setVariable ["acex_headless_blacklist",true,true];
    _group setVariable ["Waldo_AIPass_Exclude",true,true];
    _group setCombatMode "BLUE";
    {_x setVariable ["acex_headless_blacklist",true,true]} forEach _crew;
    _aircraft flyInHeight 70;
    _aircraft setVariable ["Waldo_CortexQA_Label","LANDING TEST AIRCRAFT",true];
    _aircraft setVariable ["Waldo_CortexQA_Target",_target,true];
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[_aircraft],true];
    ["Helicopter approach","Watch the actual aircraft approach the ground marker. The cyan trail records its flight. Landing acceptance requires physical ground contact within 10 m and a sustained stop, not a landing flag.",[4500,4750,40]] call _phase;
    private _wp=_group addWaypoint [_target,0];
    _wp setWaypointType "GETOUT";
    _wp setWaypointCompletionRadius 5;
    private _acquired=[{_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active",false]},60] call _wait;
    [format ["LAND-%1-controller-acquired",["touchdown","cancel"] select _cancel],_acquired] call _check;
    if (_cancel) then {
        private _redirect=[4900,4800,70];
        ["Landing order replaced","The approach order is replaced with an ordinary MOVE. The helicopter must fly toward the new marker without touching down at the cancelled landing point.",[4500,4750,40]] call _phase;
        deleteWaypoint _wp;
        _wp=_group addWaypoint [_redirect,0]; _wp setWaypointType "MOVE";
        _aircraft setVariable ["Waldo_CortexQA_Target",_redirect,true];
        private _origin=getPosATL _aircraft;
        private _touched=false;
        private _redirected=[{
            if (isTouchingGround _aircraft) then {_touched=true};
            alive _aircraft && {_aircraft distance2D _origin > 150} && {_aircraft distance2D _redirect < 100} && {getPosATL _aircraft select 2 > 15}
        },100] call _wait;
        ["LAND-cancel-physical-redirection",_acquired && {_redirected} && {!_touched},str getPosATL _aircraft] call _check;
        ["LAND-cancel-controller-released",!(_aircraft getVariable ["Waldo_ImprovedHelicopterLanding_Active",false])] call _check;
    } else {
        private _landed=[{alive _aircraft && {isTouchingGround _aircraft} && {_aircraft distance2D _target <= 10} && {abs speed _aircraft < 2}},150] call _wait;
        ["LAND-physical-touchdown",_acquired && {_landed},str [getPosATL _aircraft,speed _aircraft,isTouchingGround _aircraft]] call _check;
        private _held=_landed;
        for "_sample" from 1 to 10 do {sleep 1; if (!alive _aircraft || {!isTouchingGround _aircraft} || {abs speed _aircraft >= 2}) then {_held=false}};
        ["LAND-ground-hold",_held] call _check;
    };
    missionNamespace setVariable ["Waldo_CortexQA_Actors",[],true];
    {deleteVehicle _x} forEach _crew;
    deleteVehicle _aircraft; deleteGroup _group;
} forEach [false,true];
[_saved] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer;
