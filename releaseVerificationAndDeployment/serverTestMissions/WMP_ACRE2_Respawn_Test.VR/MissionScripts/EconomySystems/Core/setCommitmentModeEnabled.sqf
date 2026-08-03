/*
 * Author: WaldoTheWarfighter
 * Set commitment mode enabled.
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
 * [_enabled, _notify] call Waldo_fnc_EcoCore_setCommitmentModeEnabled;
 */

    params [["_enabled", false], ["_notify", true], ["_actor", objNull]];

    if (!isServer) exitWith {
        [_enabled, _notify, if (hasInterface) then {player} else {objNull}]
            remoteExecCall ["Waldo_fnc_EcoCore_setCommitmentModeEnabled", 2];
        _enabled
    };
    if (isRemoteExecuted && {isNull _actor || {owner _actor != remoteExecutedOwner}}) exitWith {false};

    missionNamespace setVariable ["WaldoEcoCore_CommitmentModeEnabled", _enabled, true];

    private _nl = toString [10];
    private _message = format [
            "Commitment Mode %1" + _nl + _nl + "Research, construction, and purchase menus will %2 full config refreshes while this stays %1.",
            ["OFF", "ON"] select _enabled,
            ["resume", "pause"] select _enabled
        ];
    if (_notify) then {
        if (!isNull _actor) then {
            [_actor, _message] call Waldo_fnc_EcoCore_notifyActor;
        } else {
            if (hasInterface) then {[_message] call Waldo_fnc_EcoCore_notifyActorLocal;};
        };
    };

    _enabled
