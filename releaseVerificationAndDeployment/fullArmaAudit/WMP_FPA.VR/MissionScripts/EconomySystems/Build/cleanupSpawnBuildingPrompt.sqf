/*
 * Author: WaldoTheWarfighter
 * Removes controls and state from the curator building-spawn prompt.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - prompt display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;
 * Locality/Authority: Curator interface client; no world object is deleted.
 * Repeat/JIP Behaviour: Safe for null/already-cleaned displays; no JIP UI replay.
 * Current Callers: Building-spawn prompt close/cancel and Economy UI cleanup.
 * Result: Temporary prompt controls and variables are removed.
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
        [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

