/*
 * Author: WaldoTheWarfighter, Val
 * Performs the one-shot protection transition for a registered transport after its vehicle or AI
 * group changes locality. It broadcasts only on an actual owner tuple change and returns the
 * updated registry entry to the caller.
 * Locality and authority: server-only transition helper; local damage commands are delegated to
 * Waldo_fnc_TransportSetProtectionLocal on current machines.
 *
 * Arguments:
 * 0: registry entry <HASHMAP>.
 *
 * Return Value: <HASHMAP> - the same entry with its current protection-owner tuple recorded.
 *
 * Example: _entry = [_entry] call Waldo_fnc_TransportRefreshProtectionServer;
 * Current callers: registration and the server monitor's owner-change branch.
 * Wiki: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Transport-Services
 */
params [["_entry", createHashMap, [createHashMap]]];
if (!isServer || {_entry isEqualTo createHashMap}) exitWith {_entry};
private _vehicle = _entry getOrDefault ["vehicle", objNull];
if (isNull _vehicle || {isNull driver _vehicle}) exitWith {_entry};
private _owners = [owner _vehicle, groupOwner group driver _vehicle];
if !(_entry getOrDefault ["protectionOwners", []] isEqualTo _owners) then {
    [_vehicle] remoteExecCall ["Waldo_fnc_TransportSetProtectionLocal", 0];
    _entry set ["protectionOwners", _owners];
};
_entry
