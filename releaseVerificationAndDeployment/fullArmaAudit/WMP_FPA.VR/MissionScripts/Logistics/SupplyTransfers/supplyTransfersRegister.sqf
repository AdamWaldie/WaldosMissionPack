/*
 * Author: WaldoTheWarfighter
 * Purpose: Registers a crate or cargo-capable vehicle as a supply source and destination.
 * Locality / Authority: Server-only registration and published registry.
 * Repeat / JIP: Duplicate registration is ignored; the ordered registry snapshot installs client actions.
 * Arguments: container or vehicle <OBJECT>. Return Value: <BOOL> registered.
 * Current callers: WMP crate issuers, object init, and ZEN supply registration.
 * Example: [supplyCrate] call Waldo_fnc_SupplyTransfersRegister;
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
