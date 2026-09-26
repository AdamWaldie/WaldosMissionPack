/*
 * Author: WaldoTheWarfighter
 * Checks the cached assigned observers for an actual counter-battery sighting.
 * Locality/authority: accepts only a server request on server/headless machines; observers must be local.
 * Repeat/JIP: server-side per-target/side cooldown deduplicates replies. No persistent observer job.
 * Arguments: 0: firing vehicle <OBJECT>, objNull.
 * Return Value: Nothing.
 * Current callers: legacy server-script observation requests; automatic counter-battery uses firing events.
 * Example: [_enemyGun] remoteExecCall ["Waldo_fnc_AIPassCounterObserve", 0];
 */
params [["_enemy", objNull, [objNull]]];
if (remoteExecutedOwner != 2 || {hasInterface && {!isServer}}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])} || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {};
[{
    params ["_job"];
    private _enemy = _job get "enemy";
    if (!alive _enemy || {!(missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Enable", false])}) exitWith {-1};
    private _spotters = _job get "spotters";
    private _cursor = _job get "cursor";
{
    private _fix = [_x, _enemy] call Waldo_fnc_AIPassSpotterFix;
    if (_fix isNotEqualTo [] && {(_fix select 1) <= (missionNamespace getVariable ["Waldo_AIPass_CounterBattery_MaxError", 100])}) then {
        [objNull, _fix select 0, _fix select 1, "HE", missionNamespace getVariable ["Waldo_AIPass_CounterBattery_Rounds", 4],
            missionNamespace getVariable ["Waldo_AIPass_CounterBattery_ShootAndScoot", true], "COUNTER", _x, _enemy] call Waldo_fnc_AIPassArtilleryFire;
    };
} forEach (_spotters select [_cursor, 4]);
    _cursor = _cursor + 4;
    _job set ["cursor", _cursor];
    [1, -1] select (_cursor >= count _spotters)
}, createHashMapFromArray [["enemy", _enemy], ["spotters", +(missionNamespace getVariable ["Waldo_AIPass_LocalSpotters", []])], ["cursor", 0]], 0] call Waldo_fnc_AIPassQueueJob;
