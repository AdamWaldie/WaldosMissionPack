/*
 * Slow recovery discovery for editor-, Zeus- and external-script-created
 * economy objects. High-frequency request handling uses the registries only.
 */
if (!isServer || {!([] call Waldo_fnc_EcoCore_isModuleActive)}) exitWith {};

{
    [_x, "CRATES"] call Waldo_fnc_EcoCore_registerRuntimeObject;
} forEach ((allMissionObjects "Land_PlasticCase_01_medium_F") select {
    _x getVariable ["WaldoEcoResource_IsResourceCrate", false]
});
{
    [_x, "RESEARCH_CENTERS"] call Waldo_fnc_EcoCore_registerRuntimeObject;
} forEach ((allMissionObjects "Land_Research_HQ_F") select {
    _x getVariable ["WaldoEcoResearch_IsResearchCenter", false]
});
{
    [_x, "PURCHASE_TERMINALS"] call Waldo_fnc_EcoCore_registerRuntimeObject;
} forEach ((allMissionObjects "Land_Laptop_unfolded_F") select {
    _x getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]
});
{
    [_x, "CONSTRUCTION_VEHICLES"] call Waldo_fnc_EcoCore_registerRuntimeObject;
} forEach (vehicles select {
    _x getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]
});
{
    if (!isNull _x) then {[_x, "BUILDINGS"] call Waldo_fnc_EcoCore_registerRuntimeObject;};
} forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);
