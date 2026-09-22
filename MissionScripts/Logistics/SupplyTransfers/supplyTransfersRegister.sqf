/*
 * Author: WaldoTheWarfighter
 * Give a crate or cargo-capable vehicle the supply-transfer and merge actions.
 * Enable Waldo_SupplyTransfers_Enable first. WMP-issued crates register automatically;
 * use this call for an object placed in Eden or created by your own script.
 *
 * Locality and authority: The server registers the object. An Eden Init runs on every
 * machine; client copies of this call do nothing. The server sends the registered
 * objects to each player so ACE actions appear for players who join later.
 * Repeat and JIP: Calling this twice for the same object does not duplicate actions.
 * If shared settings are still loading, the server finishes registration afterward.
 *
 * Arguments:
 * 0: container <OBJECT> - a crate or cargo-capable vehicle with inventory space.
 * Return Value: <BOOL> - true if registered, already registered or queued until
 * settings are ready; false if called off-server, disabled or the object cannot carry items.
 * Example: In that object's Eden Init field:
 * [this] call Waldo_fnc_SupplyTransfersRegister;
 * Result: Players can use ACE Interact to transfer supplies into or out of this object.
 * Current callers: WMP crate issuers, Eden object Init and ZEN supply registration.
 */
params [["_container", objNull, [objNull]]];
if (!isServer || {isRemoteExecuted} || {isNull _container}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_container] spawn {
        params ["_container"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {isNull _container}};
        if (!isNull _container) then {[_container] call Waldo_fnc_SupplyTransfersRegister};
    };
    true
};
if !(missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false]) exitWith {false};
if (maxLoad _container <= 0) exitWith {false};
private _registry = +(missionNamespace getVariable ["Waldo_SupplyTransfers_Registry", []]);
if (_container in _registry) exitWith {true};
_registry pushBack _container;
missionNamespace setVariable ["Waldo_SupplyTransfers_Registry", _registry, true];
diag_log format ["[WMP SUPPLY] Registered %1 (%2); count=%3", netId _container, typeOf _container, count _registry];
[_registry] remoteExecCall ["Waldo_fnc_SupplyTransfersSetupLocal", 0];
true
