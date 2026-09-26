/*
 * Author: WaldoTheWarfighter
 * Purpose: Makes WMP-issued crates ACE-draggable/carryable, then applies enabled
 *   physical-cargo and supply-transfer features by semantic role. Starter crates
 *   keep their existing setup and do not receive optional crate handling here.
 * Locality / Authority: Server-only registration; downstream functions publish replicated state.
 * Repeat / JIP: Registration functions deduplicate objects; clients replay their registries on JIP.
 * Arguments: object <OBJECT>; role <STRING> (SUPPLY, MEDICAL, AMMO, GRENADES,
 *   EXPLOSIVES, CARGO, REARM, FUEL, FUELBARREL, FUELJERRYCAN, TRACK, WHEEL, SPARE or STARTER).
 * Return Value: <BOOL> whether a supported object/role was examined on the server.
 * Current callers: WMP quartermaster, crate issuers, ZEN spawners and composition object Init.
 * Example: [this, "SUPPLY"] call Waldo_fnc_LogisticsRegisterSpawned;
 * Result: A supported new object receives WMP's appropriate ACE handling and registration.
 */
params [["_object", objNull, [objNull]], ["_role", "", [""]]];
if (!isServer || {isRemoteExecuted} || {isNull _object}) exitWith {false};
_role = toUpperANSI _role;
if !(_role in ["SUPPLY", "MEDICAL", "AMMO", "GRENADES", "EXPLOSIVES", "CARGO", "REARM", "FUEL",
    "FUELBARREL", "FUELJERRYCAN", "TRACK", "WHEEL", "SPARE", "STARTER"]) exitWith {false};
if (_role == "STARTER" || {_object getVariable ["Waldo_Logistics_StarterCrate", false]}) exitWith {true};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_object, _role] spawn {
        params ["_object", "_role"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false] || {isNull _object}};
        if (!isNull _object) then {[_object, _role] call Waldo_fnc_LogisticsRegisterSpawned};
    };
    true
};
// Portability belongs to the crate itself, not to either optional logistics
// feature. ACE's global setters install the interaction for current and JIP
// clients; SetCargoAttributes skips unchanged repeat calls.
[_object, _role] call Waldo_fnc_CargoAttributesPrepareObject;
// Every issued store can be mounted, including wheels, tracks, fuel barrels and jerrycans.
// PhysicalCargoRegister itself refuses static weapons and vehicles.
if (missionNamespace getVariable ["Waldo_PhysicalCargo_Enable", false]) then {
    [_object] call Waldo_fnc_PhysicalCargoRegister;
};
if (missionNamespace getVariable ["Waldo_SupplyTransfers_Enable", false]
    && {_role in ["SUPPLY", "MEDICAL", "AMMO", "GRENADES", "EXPLOSIVES", "CARGO"]}
    && {maxLoad _object > 0}) then {
    [_object] call Waldo_fnc_SupplyTransfersRegister;
};
true
