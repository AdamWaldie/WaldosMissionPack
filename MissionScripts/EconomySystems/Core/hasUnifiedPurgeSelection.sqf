/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - hasUnifiedPurgeSelection
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_hasUnifiedPurgeSelection via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {false};

    private _checks = [
        _disp getVariable ["WaldoEcoCore_PurgeConfigResourcesCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeConfigBuildingsCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeConfigResearchCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeConfigBuyCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeValuesBuildingsCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeValuesResourcesCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeValuesContainersCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeValuesGroundCommandCheck", controlNull],
        _disp getVariable ["WaldoEcoCore_PurgeModuleCheck", controlNull]
    ];

    (_checks findIf {!isNull _x && {cbChecked _x}}) >= 0
