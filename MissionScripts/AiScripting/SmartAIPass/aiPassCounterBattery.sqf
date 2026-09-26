/*
 * Author: WaldoTheWarfighter
 * Answers enemy artillery fire with counter-battery fire from local batteries, only when the firing
 * battery's position is actually known.
 *
 * Called from the ArtilleryShellFired mission event (Arma 3 2.18) that Waldo_fnc_AIPassInit installs
 * when Waldo_AIPass_CounterBattery_Enable is true. The audit found PROTOCOL's counter-battery
 * omniscient (any enemy artillery within 7 km was answered), so WMP requires knowledge:
 * - "KNOWN" mode: a local friendly squad leader knows about the firing vehicle (knowsAbout 1.5 or
 *   more) with a position error within Waldo_AIPass_CounterBattery_MaxError;
 * - "RADAR" mode: additionally, a counter-battery radar registered with
 *   Waldo_fnc_AIPassRegisterRadar for the answering side is within
 *   Waldo_AIPass_CounterBattery_RadarRange of the firing battery, which gives a 30 m fix.
 * The answer is fired after Waldo_AIPass_CounterBattery_Delay seconds by the first idle battery in
 * range whose role allows counter-battery (Waldo_fnc_AIPassArtilleryRole: COUNTER or BOTH), with
 * Waldo_AIPass_CounterBattery_Rounds rounds and its own shoot-and-scoot setting. Nothing is fired if
 * friendlies or civilians are within Waldo_AIPass_CounterBattery_MinFriendlyDistance of the enemy gun.
 * Each firing battery is answered at most once every Waldo_AIPass_CounterBattery_Interval seconds.
 * These settings are separate from squads' artillery support, which has its own switch and settings.
 * Locality and authority: runs on every AI-owning machine; each uses only its own batteries.
 *
 * Review contract: Delayed fire keeps the original responding side and uses COUNTER policy at execution. Live role, exclusion and safety changes can cancel a queued mission.
 *
 * Arguments:
 * 0: vehicle <OBJECT> - enemy artillery that fired
 * 1: gunner <OBJECT> - its gunner
 *
 * Return Value:
 * Boolean - true when a counter-battery mission was queued
 *
 * Example:
 * [_vehicle, _gunner] call Waldo_fnc_AIPassCounterBattery;
 * Result: an enemy mortar that has been spotted gets shelled back.
 *
 * Current caller: the ArtilleryShellFired handler installed by Waldo_fnc_AIPassInit.
 */

params [["_vehicle", objNull, [objNull]], ["_gunner", objNull, [objNull]]];
if (isNull _vehicle || {!(missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false])}) exitWith {false};
if (time < (_vehicle getVariable ["Waldo_AIPass_CounterBatteryAt", -1])) exitWith {false};
private _enemySide = side group ([_gunner, gunner _vehicle] select isNull _gunner);
private _batteries = (missionNamespace getVariable ["Waldo_AIPass_LocalArtillery", []]) select {
    alive _x && {local _x} && {alive gunner _x} && {!([group gunner _x] call Waldo_fnc_AIPassZeusHeld)} && {(side group gunner _x) getFriend _enemySide < 0.6}
    && {(_x getVariable ["Waldo_AIPass_BusyUntil", -1]) < time} && {[_x, "COUNTER"] call Waldo_fnc_AIPassArtilleryRole}
};
if (_batteries isEqualTo []) exitWith {false};
private _ourSide = side group gunner (_batteries select 0);
private _maxError = missionNamespace getVariable ["Waldo_AIPass_CounterBattery_MaxError", 100];
private _fix = [];
{
    private _leader = leader _x;
    if (local _x && {side _x == _ourSide} && {alive _leader} && {_leader knowsAbout _vehicle >= 1.5}) then {
        private _error = (_leader targetKnowledge _vehicle) select 5;
        if (_error <= _maxError) then {_fix = [_leader getHideFrom _vehicle, _error]};
    };
    if (_fix isNotEqualTo []) exitWith {};
} forEach allGroups;
if (_fix isEqualTo [] && {toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Mode", "KNOWN"]) == "RADAR"}) then {
    private _range = missionNamespace getVariable ["Waldo_AIPass_CounterBattery_RadarRange", 8000];
    private _sideKey = switch (_ourSide) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
    if ((missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]) findIf {
        _x params ["_radar", "_radarSide"];
        alive _radar && {_radarSide == _sideKey} && {_radar distance2D _vehicle <= _range}
    } >= 0) then {_fix = [getPosATL _vehicle, 30]};
};
if (_fix isEqualTo []) exitWith {false};
// Never shell friends or civilians standing near the enemy gun.
private _standoff = missionNamespace getVariable ["Waldo_AIPass_CounterBattery_MinFriendlyDistance", 200];
if (((_fix select 0) nearEntities [["CAManBase", "LandVehicle"], _standoff]) findIf {
    private _otherSide = side group _x;
    alive _x && {_otherSide == civilian || {_ourSide getFriend _otherSide >= 0.6}}
} >= 0) exitWith {false};
_vehicle setVariable ["Waldo_AIPass_CounterBatteryAt", time + (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Interval", 60])];
[{
    params ["_job"];
    {
        if ([_x, _job get "target", _job get "error", "HE",
            missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Rounds", 4],
            missionNamespace getVariable ["Waldo_AIPass_CounterBattery_ShootAndScoot", true], "COUNTER"] call Waldo_fnc_AIPassArtilleryFire) exitWith {};
    } forEach ((_job get "batteries") select {alive _x && {local _x} && {side group gunner _x == (_job get "side")} && {(_x getVariable ["Waldo_AIPass_BusyUntil", -1]) < time}});
    -1
}, createHashMapFromArray [["target", _fix select 0], ["error", _fix select 1], ["batteries", _batteries select {side group gunner _x == _ourSide}], ["side", _ourSide]],
    missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Delay", 20]] call Waldo_fnc_AIPassQueueJob;
true
