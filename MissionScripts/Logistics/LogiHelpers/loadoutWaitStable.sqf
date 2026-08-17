/*
 * Author: WaldoTheWarfighter
 * Waits, bounded, until a unit's equipment (per Waldo_fnc_LoadoutCanary) stops changing across two
 * consecutive checks, before an automatic loadout capture treats it as final. A unit object existing
 * (`!isNull`) does not guarantee the engine has finished populating its Eden/mission.sqm-configured
 * inventory at that exact tick - the same class of transient-state race already guarded against on the
 * restore side (respawnRestoreLoadout.sqf's canary-verify-and-retry), but never previously guarded
 * against on the save side. Never blocks indefinitely: if the canary never stabilises within the bound,
 * returns with whatever is current so the caller is never stuck waiting on a unit that will not settle.
 *
 * Arguments:
 * 0: unit <OBJECT>
 * 1: timeout seconds <NUMBER> (default 10)
 *
 * Return Value: ARRAY - [stable <BOOL>, elapsedSeconds <NUMBER>]. stable is false both when the unit
 * went null mid-wait and when the bound was reached without two consecutive matching checks.
 *
 * Example: private _result = [player] call Waldo_fnc_LoadoutWaitStable;
 * Current callers: initPlayerLocal.sqf's mission-start baseline capture, persistenceClientApply.sqf's
 * post-persistence-restore capture.
 */
params [["_unit", objNull, [objNull]], ["_timeoutSeconds", 10, [0]]];
if (isNull _unit) exitWith {[false, 0]};
private _startTick = diag_tickTime;
private _deadline = _startTick + _timeoutSeconds;
private _lastCanary = [_unit] call Waldo_fnc_LoadoutCanary;
private _stableChecks = 0;
waitUntil {
    sleep 0.3;
    if (isNull _unit) exitWith {true};
    private _canary = [_unit] call Waldo_fnc_LoadoutCanary;
    if (_canary isEqualTo _lastCanary) then {
        _stableChecks = _stableChecks + 1;
    } else {
        _stableChecks = 0;
        _lastCanary = _canary;
    };
    _stableChecks >= 2 || {diag_tickTime >= _deadline}
};
private _elapsed = diag_tickTime - _startTick;
private _stable = !(isNull _unit) && {_stableChecks >= 2};
if !(_stable) then {
    diag_log format ["[WMP LOADOUT] LoadoutWaitStable: equipment did not settle within %1s (unit null=%2); proceeding with current state.", _timeoutSeconds, isNull _unit];
};
[_stable, _elapsed]
