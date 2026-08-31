/*
 * Author: WaldoTheWarfighter
 * Reconciles client-local Economy actions against the current typed runtime registries.
 *
 * Locality/authority: interface client only; reads server-published registry state and installs
 * local actions without mutating Economy authority. Repeat/JIP behaviour: repeat-safe through each
 * subsystem's action installer. Called after initial/JIP registry arrival, membership changes and
 * the retained ten-second repair callback.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true after reconciliation; false outside an active interface client.
 *
 * Current callers: requestLocalWorldActionRefresh.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_refreshLocalWorldActions;
 */

if (!hasInterface || {!([] call Waldo_fnc_EcoCore_isModuleActive)}) exitWith {false};

if (!isNil "Waldo_fnc_EcoResource_ensureCrateActionLocal") then {
    {[_x] call Waldo_fnc_EcoResource_ensureCrateActionLocal;} forEach (["CRATES"] call Waldo_fnc_EcoCore_getRuntimeObjects);
};
if (!isNil "Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal") then {
    {[_x] call Waldo_fnc_EcoResearch_ensureResearchCenterActionsLocal;} forEach (["RESEARCH_CENTERS"] call Waldo_fnc_EcoCore_getRuntimeObjects);
};
if (!isNil "Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal") then {
    {[_x] call Waldo_fnc_EcoBuild_ensureConstructionVehicleActionLocal;} forEach (["CONSTRUCTION_VEHICLES"] call Waldo_fnc_EcoCore_getRuntimeObjects);
};
if (!isNil "Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal") then {
    {[_x] call Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal;} forEach (["PURCHASE_TERMINALS"] call Waldo_fnc_EcoCore_getRuntimeObjects);
};

true
