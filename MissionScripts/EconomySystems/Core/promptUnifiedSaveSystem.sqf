/*
 * Author: WaldoTheWarfighter
 * Prompt unified save system.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_ctrl] call Waldo_fnc_EcoCore_promptUnifiedSaveSystem;
 */

    if (!hasInterface) exitWith {};

    private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _zeusDisp) exitWith {};

    [_zeusDisp] call Waldo_fnc_EcoCore_cleanupUnifiedSaveContext;

    private _disp = ["  WALDOS MISSION PACK  |  ECONOMY AUTHORING", true] call Waldo_fnc_EcoCore_createZeusPromptDisplay;
    if (isNull _disp) exitWith {};

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.23, 0.09, 0.54, 0.56];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.82];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.25, 0.11, 0.48, 0.03];
    _title ctrlSetText "Economy Setup Builder";
    _title ctrlCommit 0;

    private _guide = _disp ctrlCreate ["RscStructuredText", -1];
    _guide ctrlSetPosition [0.25, 0.142, 0.48, 0.065];
    _guide ctrlSetStructuredText parseText "<t color='#79C7FF' size='0.78'>ZEUS TO SCRIPT</t><br/><t color='#D9E6F2' size='0.72'>1. Place and configure systems.  2. Select sections below.  3. BUILD + COPY.  4. Paste the generated calls into MissionConfig\economyConfig.sqf.</t>";
    _guide ctrlSetTextColor [0.72, 0.86, 0.96, 1];
    _guide ctrlSetTooltip "The generated SQF contains the public setup calls and their current arguments, including placed fixtures.";
    _guide ctrlCommit 0;

    private _resourcesCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _resourcesCheck ctrlSetPosition [0.25, 0.215, 0.03, 0.03];
    _resourcesCheck cbSetChecked true;
    _resourcesCheck ctrlCommit 0;

    private _resourcesLabel = _disp ctrlCreate ["RscText", -1];
    _resourcesLabel ctrlSetPosition [0.285, 0.217, 0.10, 0.025];
    _resourcesLabel ctrlSetText "RESOURCES";
    _resourcesLabel ctrlCommit 0;

    private _researchCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _researchCheck ctrlSetPosition [0.39, 0.215, 0.03, 0.03];
    _researchCheck cbSetChecked true;
    _researchCheck ctrlCommit 0;

    private _researchLabel = _disp ctrlCreate ["RscText", -1];
    _researchLabel ctrlSetPosition [0.425, 0.217, 0.09, 0.025];
    _researchLabel ctrlSetText "RESEARCH";
    _researchLabel ctrlCommit 0;

    private _buildingsCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _buildingsCheck ctrlSetPosition [0.525, 0.215, 0.03, 0.03];
    _buildingsCheck cbSetChecked true;
    _buildingsCheck ctrlCommit 0;

    private _buildingsLabel = _disp ctrlCreate ["RscText", -1];
    _buildingsLabel ctrlSetPosition [0.56, 0.217, 0.09, 0.025];
    _buildingsLabel ctrlSetText "BUILDINGS";
    _buildingsLabel ctrlCommit 0;

    private _buyCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _buyCheck ctrlSetPosition [0.655, 0.215, 0.03, 0.03];
    _buyCheck cbSetChecked true;
    _buyCheck ctrlCommit 0;

    private _buyLabel = _disp ctrlCreate ["RscText", -1];
    _buyLabel ctrlSetPosition [0.69, 0.217, 0.05, 0.025];
    _buyLabel ctrlSetText "BUY";
    _buyLabel ctrlCommit 0;

    private _additiveCheck = _disp ctrlCreate ["RscCheckBox", -1];
    _additiveCheck ctrlSetPosition [0.25, 0.247, 0.03, 0.03];
    _additiveCheck cbSetChecked false;
    _additiveCheck ctrlCommit 0;

    private _additiveLabel = _disp ctrlCreate ["RscText", -1];
    _additiveLabel ctrlSetPosition [0.285, 0.249, 0.14, 0.025];
    _additiveLabel ctrlSetText "Additive Import";
    _additiveLabel ctrlCommit 0;

    private _text = _disp ctrlCreate ["RscEditMulti", -1];
    _text ctrlSetPosition [0.25, 0.285, 0.48, 0.260];
    _text ctrlSetText ([true, true, true, true, true] call Waldo_fnc_EcoCore_buildMissionSetupScript);
    _text ctrlCommit 0;

    private _import = _disp ctrlCreate ["RscButtonMenu", -1];
    _import ctrlSetPosition [0.53, 0.58, 0.09, 0.04];
    _import ctrlSetText "IMPORT";
    _import ctrlSetTooltip "Import a portable WMP economy configuration string from the text box";
    _import ctrlCommit 0;

    private _export = _disp ctrlCreate ["RscButtonMenu", -1];
    _export ctrlSetPosition [0.25, 0.58, 0.15, 0.04];
    _export ctrlSetText "BUILD + COPY";
    _export ctrlSetTooltip "Generate replayable setup calls with their current arguments and copy them to the clipboard";
    _export ctrlCommit 0;

    private _configExport = _disp ctrlCreate ["RscButtonMenu", -1];
    _configExport ctrlSetPosition [0.41, 0.58, 0.11, 0.04];
    _configExport ctrlSetText "CONFIG COPY";
    _configExport ctrlSetTooltip "Export only the portable catalogue configuration string";
    _configExport ctrlCommit 0;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [0.63, 0.58, 0.10, 0.04];
    _close ctrlSetText "CLOSE";
    _close ctrlCommit 0;

    _disp setVariable ["WaldoEcoCore_SaveBG", _bg];
    _disp setVariable ["WaldoEcoCore_SaveTitle", _title];
    _disp setVariable ["WaldoEcoCore_SaveGuide", _guide];
    _disp setVariable ["WaldoEcoCore_SaveResourcesCheck", _resourcesCheck];
    _disp setVariable ["WaldoEcoCore_SaveResourcesLabel", _resourcesLabel];
    _disp setVariable ["WaldoEcoCore_SaveResearchCheck", _researchCheck];
    _disp setVariable ["WaldoEcoCore_SaveResearchLabel", _researchLabel];
    _disp setVariable ["WaldoEcoCore_SaveBuildingsCheck", _buildingsCheck];
    _disp setVariable ["WaldoEcoCore_SaveBuildingsLabel", _buildingsLabel];
    _disp setVariable ["WaldoEcoCore_SaveBuyCheck", _buyCheck];
    _disp setVariable ["WaldoEcoCore_SaveBuyLabel", _buyLabel];
    _disp setVariable ["WaldoEcoCore_SaveAdditiveCheck", _additiveCheck];
    _disp setVariable ["WaldoEcoCore_SaveAdditiveLabel", _additiveLabel];
    _disp setVariable ["WaldoEcoCore_SaveText", _text];
    _disp setVariable ["WaldoEcoCore_SaveImport", _import];
    _disp setVariable ["WaldoEcoCore_SaveExport", _export];
    _disp setVariable ["WaldoEcoCore_SaveConfigExport", _configExport];
    _disp setVariable ["WaldoEcoCore_SaveClose", _close];
    {
        _x setVariable ["WaldoEcoCore_SaveDisplay", _disp];
    } forEach [_import, _export, _configExport, _close];

    _export ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _textCtrl = _disp getVariable ["WaldoEcoCore_SaveText", controlNull];
        private _resourcesCheck = _disp getVariable ["WaldoEcoCore_SaveResourcesCheck", controlNull];
        private _researchCheck = _disp getVariable ["WaldoEcoCore_SaveResearchCheck", controlNull];
        private _buildingsCheck = _disp getVariable ["WaldoEcoCore_SaveBuildingsCheck", controlNull];
        private _buyCheck = _disp getVariable ["WaldoEcoCore_SaveBuyCheck", controlNull];
        if (isNull _textCtrl || isNull _resourcesCheck || isNull _researchCheck || isNull _buildingsCheck || isNull _buyCheck) exitWith {};

        private _selection = [cbChecked _resourcesCheck, cbChecked _researchCheck, cbChecked _buildingsCheck, cbChecked _buyCheck];
        _selection pushBack true;
        private _payload = _selection call Waldo_fnc_EcoCore_buildMissionSetupScript;

        _textCtrl ctrlSetText _payload;
        _textCtrl ctrlCommit 0;
        copyToClipboard _payload;
        private _guide = _disp getVariable ["WaldoEcoCore_SaveGuide", controlNull];
        if (!isNull _guide) then {
            _guide ctrlSetStructuredText parseText "<t color='#6CE5A8' size='0.80'>COPIED</t><br/><t color='#FFFFFF' size='0.72'>Paste the generated calls into MissionConfig\economyConfig.sqf, then save the mission.</t>";
            _guide ctrlSetTextColor [0.42, 0.90, 0.66, 1];
            _guide ctrlCommit 0;
        };
    }];

    _configExport ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _textCtrl = _disp getVariable ["WaldoEcoCore_SaveText", controlNull];
        private _resourcesCheck = _disp getVariable ["WaldoEcoCore_SaveResourcesCheck", controlNull];
        private _researchCheck = _disp getVariable ["WaldoEcoCore_SaveResearchCheck", controlNull];
        private _buildingsCheck = _disp getVariable ["WaldoEcoCore_SaveBuildingsCheck", controlNull];
        private _buyCheck = _disp getVariable ["WaldoEcoCore_SaveBuyCheck", controlNull];
        if (isNull _textCtrl || isNull _resourcesCheck || isNull _researchCheck || isNull _buildingsCheck || isNull _buyCheck) exitWith {};

        private _selection = [cbChecked _resourcesCheck, cbChecked _researchCheck, cbChecked _buildingsCheck, cbChecked _buyCheck];
        _textCtrl ctrlSetText (_selection call Waldo_fnc_EcoCore_buildUnifiedSaveExportPayload);
        _textCtrl ctrlCommit 0;
    }];

    _import ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _textCtrl = _disp getVariable ["WaldoEcoCore_SaveText", controlNull];
        private _additiveCheck = _disp getVariable ["WaldoEcoCore_SaveAdditiveCheck", controlNull];
        if (isNull _textCtrl) exitWith {};

        private _raw = ctrlText _textCtrl;
        if (_raw isEqualTo "") exitWith {};

        private _payload = [];
        if (isNil { _payload = parseSimpleArray _raw; false }) exitWith {};

        [_payload, name player, (!isNull _additiveCheck) && {cbChecked _additiveCheck}] call Waldo_fnc_EcoCore_importUnifiedSavePayload;
    }];

    _close ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoCore_SaveDisplay", displayNull];
        if (!isNull _disp) then {
            [_disp] call Waldo_fnc_EcoCore_cleanupUnifiedSavePrompt;
        };
    }];

    [_disp, [_text], _text, "WaldoEcoCore_SaveInputTargets", [14, 28, 156, 211]] call Waldo_fnc_EcoCore_setPromptInputTargets;
    [_disp] call Waldo_fnc_EcoCore_fitPromptDisplay;
