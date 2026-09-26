/*
 * Author: WaldoTheWarfighter
 * Requests counter-battery reports from assigned observers, or uses a registered radar fix.
 * Locality/authority: server consumes the global firing event; observation runs on AI owners.
 * Repeat/JIP: server event cooldown and per-side request cooldown prevent duplicate responses across HCs.
 * Arguments: 0: firing vehicle <OBJECT>, objNull; 1: gunner <OBJECT>, objNull.
 * Return Value: Boolean, observation requests dispatched.
 * Current callers: ArtilleryShellFired handler.
 * Example: [_vehicle, gunner _vehicle] call Waldo_fnc_AIPassCounterBattery;
 */
params [["_vehicle", objNull, [objNull]], ["_gunner", objNull, [objNull]]];
if (!isServer || {isNull _vehicle} || {!(missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false])}
    || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {false};
if (time < (_vehicle getVariable ["Waldo_AIPass_CounterEventAt", -1])) exitWith {false};
_vehicle setVariable ["Waldo_AIPass_CounterEventAt", time + ((missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Interval", 60]) max 10)];
[{
    params ["_vehicle", "_enemySide", "_emissionPosition"];
    if (!alive _vehicle || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])}
        || {!(missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false])} || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {};
    [_vehicle] remoteExecCall ["Waldo_fnc_AIPassCounterObserve", 0];
    if (toUpperANSI (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Mode", "KNOWN"]) == "RADAR") then {
        {
            private _battery = _x;
            private _side = side group gunner _battery;
            private _sideKey = switch (_side) do {case west: {"WEST"}; case east: {"EAST"}; case independent: {"GUER"}; default {"CIV"}};
            if (_side getFriend _enemySide < 0.6 && {[_battery, "COUNTER"] call Waldo_fnc_AIPassArtilleryRole}
                && {(missionNamespace getVariable ["Waldo_AIPass_CounterBatteryRadars", []]) findIf {
                    _x params ["_radar", "_radarSide"];
                    alive _radar && {_radarSide == _sideKey} && {_radar distance2D _emissionPosition <= (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_RadarRange", 8000])}
                } >= 0}) then {
                // Radar sees this emission, not future movement. There is no automatic later correction.
                [_battery, _emissionPosition, 30, "HE", missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Rounds", 4],
                    missionNamespace getVariable ["Waldo_AIPass_CounterBattery_ShootAndScoot", true], "COUNTER", objNull, _vehicle] call Waldo_fnc_AIPassArtilleryFire;
            };
        } forEach (missionNamespace getVariable ["Waldo_AIPass_AllArtillery", []]);
    };
}, [_vehicle, side group _gunner, getPosATL _vehicle], missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Delay", 20]] call CBA_fnc_waitAndExecute;
true
