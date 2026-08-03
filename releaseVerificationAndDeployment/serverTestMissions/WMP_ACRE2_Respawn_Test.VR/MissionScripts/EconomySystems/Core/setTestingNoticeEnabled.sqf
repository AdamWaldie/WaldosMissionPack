/*
 * Author: WaldoTheWarfighter
 * Set testing notice enabled.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _enabled <BOOL> - enabled (optional, default: false)
 * 1: _notify <BOOL> - notify (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_enabled, _notify] call Waldo_fnc_EcoCore_setTestingNoticeEnabled;
 */

    params [["_enabled", false], ["_notify", true], ["_actor", objNull]];

    if (!isServer) exitWith {
        [_enabled, _notify, if (hasInterface) then {player} else {objNull}]
            remoteExecCall ["Waldo_fnc_EcoCore_setTestingNoticeEnabled", 2];
        _enabled
    };
    if (isRemoteExecuted && {isNull _actor || {owner _actor != remoteExecutedOwner}}) exitWith {false};

    private _wasEnabled = [] call Waldo_fnc_EcoCore_isTestingNoticeEnabled;
    missionNamespace setVariable ["WaldoEcoCore_TestingNoticeEnabled", _enabled, true];
    if (_enabled && {!_wasEnabled}) then {
        private _oldToken = missionNamespace getVariable ["WaldoEcoCore_TestingNoticeToken", 0];
        missionNamespace setVariable ["WaldoEcoCore_TestingNoticeToken", _oldToken + 1, true];
    };

    private _nl = toString [10];
    private _message = format [
            "Testing Notice %1" + _nl + _nl + "Players will %2 receive the one-time testing popup.",
            ["OFF", "ON"] select _enabled,
            ["not", "now"] select _enabled
        ];
    if (_notify) then {
        if (!isNull _actor) then {
            [_actor, _message] call Waldo_fnc_EcoCore_notifyActor;
        } else {
            if (hasInterface) then {[_message] call Waldo_fnc_EcoCore_notifyActorLocal;};
        };
    };

    _enabled
