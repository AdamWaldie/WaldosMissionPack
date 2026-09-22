/*
 * Author: WaldoTheWarfighter
 * Purpose: Validates a requested save, heal or spectator service against the live group registry.
 * Locality / Authority: Server only; validates remote owner, living player and distance.
 * Repeat / JIP: Stateless; each request checks the current registration after group edits.
 * Arguments: player <OBJECT>, service object <OBJECT>, service <STRING>.
 * Return Value: <BOOL> accepted. Current caller: local ACE base-service actions.
 * Example: [player, hqDesk, "SAVE"] remoteExecCall ["Waldo_fnc_BaseServicesUseServer", 2];
 */
params [["_player", objNull, [objNull]], ["_object", objNull, [objNull]], ["_service", "", [""]]];
if (!isServer || {!(missionNamespace getVariable ["Waldo_BaseServices_Enable", false])}
    || {isNull _player} || {isNull _object} || {!alive _player} || {_player distance _object > 6}
    || {!(_service in ["SAVE", "HEAL", "SPECTATE"])}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _player}) exitWith {false};
private _registered = false;
{
    if ((_x select 1) findIf {(_x select 0) isEqualTo _object && {_service in (_x select 2)}} >= 0) exitWith {
        _registered = true;
    };
} forEach (missionNamespace getVariable ["Waldo_BaseServices_Registry", []]);
if (!_registered) exitWith {false};
[_player, _service] remoteExecCall ["Waldo_fnc_BaseServicesUseLocal", _player];
true
