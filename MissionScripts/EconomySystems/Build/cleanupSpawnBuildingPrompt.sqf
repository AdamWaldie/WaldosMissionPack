/*
 * Author: Waldo
 * Cleanup spawn building prompt.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [_disp, "WaldoEcoBuild_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
        [_disp, [
            "WaldoEcoBuild_SpawnBG",
            "WaldoEcoBuild_SpawnTitle",
            "WaldoEcoBuild_SpawnSideLabel",
            "WaldoEcoBuild_SpawnSidePrev",
            "WaldoEcoBuild_SpawnSideValue",
            "WaldoEcoBuild_SpawnSideNext",
            "WaldoEcoBuild_SpawnListLabel",
            "WaldoEcoBuild_SpawnList",
            "WaldoEcoBuild_SpawnAction",
            "WaldoEcoBuild_SpawnCancel"
        ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

        [_disp, [
            "WaldoEcoBuild_SpawnSideIndex",
            "WaldoEcoBuild_SpawnSelectedIndex",
            "WaldoEcoBuild_SpawnTargetPos"
        ]] call Waldo_fnc_EcoCore_clearDisplayVariables;

