/*
 * Author: WaldoTheWarfighter
 * Purpose: Applies enabled WMP crate logistics features by semantic role, excluding starter crates.
 * Locality / Authority: Server-only registration; downstream functions publish replicated state.
 * Repeat / JIP: Registration functions deduplicate objects; clients replay their registries on JIP.
 * Arguments: object <OBJECT>; role <STRING> (SUPPLY, MEDICAL, AMMO, GRENADES,
 *   EXPLOSIVES, CARGO, REARM, FUEL, SPARE or STARTER).
 * Return Value: <BOOL> whether a supported object/role was examined on the server.
 * Current callers: WMP quartermaster, crate issuers, ZEN spawners and composition object Init.
 * Example: [this, "SUPPLY"] call Waldo_fnc_LogisticsRegisterSpawned;
 */
params [["_object", objNull, [objNull]], ["_role", "", [""]]];
if (!isServer || {isRemoteExecuted} || {isNull _object}) exitWith {false};
_role = toUpperANSI _role;
if !(_role in ["SUPPLY", "MEDICAL", "AMMO", "GRENADES", "EXPLOSIVES", "CARGO", "REARM", "FUEL", "SPARE", "STARTER"]) exitWith {false};
if (_role == "STARTER") exitWith {true};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_object, _role] spawn {
        params ["_object", "_role"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {isNull _object}};
        if (!isNull _object) then {[_object, _role] call Waldo_fnc_LogisticsRegisterSpawned};
    };
    true
};
if (missionNamespace getVariable ["Waldo_PhysicalCargo_Enable", false]
    && {!(_object isKindOf "StaticWeapon")}
    && {_role in ["SUPPLY", "MEDICAL", "AMMO", "GRENADES", "EXPLOSIVES", "CARGO", "REARM"]}) then {
    [_object] call Waldo_fnc_PhysicalCargoRegister;
};
if (missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false]
    && {_role in ["SUPPLY", "MEDICAL", "AMMO", "GRENADES", "EXPLOSIVES", "CARGO"]}
    && {maxLoad _object > 0}) then {
    [_object] call Waldo_fnc_SupplyTransfersRegister;
};
true
