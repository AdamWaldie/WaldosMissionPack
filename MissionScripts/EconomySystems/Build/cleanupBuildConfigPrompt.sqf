/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - cleanupBuildConfigPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [_disp, "WaldoEcoBuild_InputTargets"] call Waldo_fnc_EcoCore_resetPromptInputTargets;
        [_disp, [
            "WaldoEcoBuild_ConfigBG",
            "WaldoEcoBuild_ConfigTitle",
            "WaldoEcoBuild_ConfigListLabel",
            "WaldoEcoBuild_ConfigList",
            "WaldoEcoBuild_ConfigTabFrame",
            "WaldoEcoBuild_ConfigTabDefinitions",
            "WaldoEcoBuild_ConfigTabEffects",
            "WaldoEcoBuild_ConfigNameLabel",
            "WaldoEcoBuild_ConfigNameEdit",
            "WaldoEcoBuild_ConfigDescLabel",
            "WaldoEcoBuild_ConfigDescEdit",
            "WaldoEcoBuild_ConfigCostsLabel",
            "WaldoEcoBuild_ConfigCostsEdit",
            "WaldoEcoBuild_ConfigReqsLabel",
            "WaldoEcoBuild_ConfigReqsEdit",
            "WaldoEcoBuild_ConfigClassLabel",
            "WaldoEcoBuild_ConfigClassEdit",
            "WaldoEcoBuild_ConfigTimeLabel",
            "WaldoEcoBuild_ConfigTimeEdit",
            "WaldoEcoBuild_ConfigColorLabel",
            "WaldoEcoBuild_ConfigColorEdit",
            "WaldoEcoBuild_ConfigCategoryLabel",
            "WaldoEcoBuild_ConfigCategoryEdit",
            "WaldoEcoBuild_ConfigBuildLimitLabel",
            "WaldoEcoBuild_ConfigBuildLimitEdit",
            "WaldoEcoBuild_ConfigAvailLabel",
            "WaldoEcoBuild_ConfigAvailAllCheck",
            "WaldoEcoBuild_ConfigAvailAllLabel",
            "WaldoEcoBuild_ConfigAvailWestCheck",
            "WaldoEcoBuild_ConfigAvailWestLabel",
            "WaldoEcoBuild_ConfigAvailEastCheck",
            "WaldoEcoBuild_ConfigAvailEastLabel",
            "WaldoEcoBuild_ConfigAvailGuerCheck",
            "WaldoEcoBuild_ConfigAvailGuerLabel",
            "WaldoEcoBuild_ConfigEffectsLabel",
            "WaldoEcoBuild_ConfigProduceResourceLabel",
            "WaldoEcoBuild_ConfigProduceResourceEdit",
            "WaldoEcoBuild_ConfigProduceAmountLabel",
            "WaldoEcoBuild_ConfigProduceAmountEdit",
            "WaldoEcoBuild_ConfigProduceIntervalLabel",
            "WaldoEcoBuild_ConfigProduceIntervalEdit",
            "WaldoEcoBuild_ConfigUpkeepCostsLabel",
            "WaldoEcoBuild_ConfigUpkeepCostsEdit",
            "WaldoEcoBuild_ConfigUpkeepIntervalLabel",
            "WaldoEcoBuild_ConfigUpkeepIntervalEdit",
            "WaldoEcoBuild_ConfigStorageLabel",
            "WaldoEcoBuild_ConfigStorageEdit",
            "WaldoEcoBuild_ConfigUpgradeToLabel",
            "WaldoEcoBuild_ConfigUpgradeToEdit",
            "WaldoEcoBuild_ConfigResearchSpeedLabel",
            "WaldoEcoBuild_ConfigResearchSpeedEdit",
            "WaldoEcoBuild_ConfigBuildSpeedLabel",
            "WaldoEcoBuild_ConfigBuildSpeedEdit",
            "WaldoEcoBuild_ConfigDetectorRangeLabel",
            "WaldoEcoBuild_ConfigDetectorRangeEdit",
            "WaldoEcoBuild_ConfigIconLabel",
            "WaldoEcoBuild_ConfigIconPrev",
            "WaldoEcoBuild_ConfigIconValue",
            "WaldoEcoBuild_ConfigIconNext",
            "WaldoEcoBuild_ConfigAdd",
            "WaldoEcoBuild_ConfigRemove",
            "WaldoEcoBuild_ConfigSave",
            "WaldoEcoBuild_ConfigOk"
        ]] call Waldo_fnc_EcoCore_deleteDisplayControlsByVars;

        [_disp, [
            "WaldoEcoBuild_ConfigIconIndex",
            "WaldoEcoBuild_ConfigSelectedIndex",
            "WaldoEcoBuild_ConfigCurrentTab"
        ]] call Waldo_fnc_EcoCore_clearDisplayVariables;
        [_disp] call Waldo_fnc_EcoCore_closePromptDisplayIfDedicated;

