/*
 * Author: Waldo
 * Has unified purge selection.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCore_hasUnifiedPurgeSelection;
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
