/*
 * Author: WaldoTheWarfighter
 * Acquires a firing-event location for finite counter-battery bursts; radar shortens acquisition.
 * Locality/authority: server consumes the global firing event; guns execute on their owners.
 * Repeat/JIP: server event cooldown and per-side request cooldown prevent duplicate responses across HCs.
 * Arguments: 0: firing vehicle <OBJECT>, objNull; 1: gunner <OBJECT>, objNull.
 * Return Value: Boolean, detection processed.
 * Current callers: ArtilleryShellFired handler.
 * Example: [_vehicle, gunner _vehicle] call Waldo_fnc_AIPassCounterBattery;
 */
params [["_vehicle", objNull, [objNull]], ["_gunner", objNull, [objNull]]];
if (!isServer || {isNull _vehicle} || {!(missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false])}
    || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {false};
private _position = getPosATL _vehicle;
// Update even while a response is active: a new emission may reveal relocation before the next burst.
_vehicle setVariable ["Waldo_AIPass_LastEmission", [time, +_position]];
if (time < (_vehicle getVariable ["Waldo_AIPass_CounterEventAt", -1])) exitWith {false};
_vehicle setVariable ["Waldo_AIPass_CounterEventAt", time + ((missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Interval", 60]) max 10)];
private _enemySide = side group _gunner;
private _sides = [];
{
    private _side = side group gunner _x;
    if (alive gunner _x && {_side getFriend _enemySide < 0.6} && {[_x, "COUNTER"] call Waldo_fnc_AIPassArtilleryRole}) then {_sides pushBackUnique _side};
} forEach (missionNamespace getVariable ["Waldo_AIPass_AllArtillery", []]);
{
    private _side = _x;
    private _pendingKey = "Waldo_AIPass_CounterPending_" + str _side;
    if (time >= (_vehicle getVariable [_pendingKey, -1]) && {time >= (_vehicle getVariable ["Waldo_AIPass_CounterUntil_" + str _side, -1])}) then {
        private _sideKey = switch (_side) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
        private _radar = (missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]) findIf {
            _x params ["_object", "_radarSide"];
            alive _object && {_radarSide == _sideKey} && {_object distance2D _position <= (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_RadarRange", 8000])}
        } >= 0;
        private _normalDelay = (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Delay", 60]) max 1;
        private _delay = if (_radar) then {((missionNamespace getVariable ["Waldo_AIPass_CounterBattery_RadarDelay", 20]) max 1) min _normalDelay} else {_normalDelay};
        _vehicle setVariable [_pendingKey, time + _delay + 1];
        [{
            params ["_vehicle", "_side", "_position", "_generation"];
            if (_generation != (missionNamespace getVariable ["Waldo_AIPass_CounterGeneration", 0])) exitWith {};
            if (isNull _vehicle || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])} || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {};
            {
                if (side group gunner _x == _side && {
                    [_x, _position, 30, "HE", missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Rounds", 4],
                        missionNamespace getVariable ["Waldo_AIPass_CounterBattery_ShootAndScoot", true], "COUNTER", objNull, _vehicle] call Waldo_fnc_AIPassArtilleryFire
                }) exitWith {};
            } forEach (missionNamespace getVariable ["Waldo_AIPass_AllArtillery", []]);
        }, [_vehicle, _side, +_position, missionNamespace getVariable ["Waldo_AIPass_CounterGeneration", 0]], _delay] call CBA_fnc_waitAndExecute;
    };
} forEach _sides;
true
