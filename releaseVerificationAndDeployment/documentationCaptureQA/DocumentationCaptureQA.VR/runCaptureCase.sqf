/* Opens a deterministic production UI state and emits one capture-ready marker. */
waitUntil {uiSleep 0.05; !isNull findDisplay 46 && {!isNull player}};
showHUD true;
missionNamespace setVariable ["WALDO_INIT_COMPLETE", true];
player allowDamage false;
player setPosATL [0, 0, 0];

private _case = toLower (missionNamespace getVariable ["Waldo_DocCapture_Case", "economy-resources"]);
private _ready = false;
private _display = displayNull;

if ((_case find "economy-") == 0) then {
    // The production prompts require a Zeus display. The capture mission uses
    // the main display as their parent while exercising the same prompt code.
    Waldo_fnc_EcoCore_getZeusDisplay = {findDisplay 46};
    missionNamespace setVariable ["Waldo_Economy_Enable", true];
    missionNamespace setVariable ["WaldoEcoCore_ModuleActive", true];
    missionNamespace setVariable ["WaldoEcoResource_SystemInitialized", true];
    missionNamespace setVariable ["WaldoEcoResearch_SystemInitialized", true];
    missionNamespace setVariable ["WaldoEcoBuild_SystemInitialized", true];
    missionNamespace setVariable ["WaldoEcoBuy_SystemInitialized", true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", [
        ["Money", "#D4C15A", "\A3\ui_f\data\map\markers\military\dot_CA.paa", -1],
        ["Minerals", "#B7A38A", "\A3\ui_f\data\map\markers\military\dot_CA.paa", -1],
        ["Electricity", "#8ED1FC", "\A3\ui_f\data\map\markers\military\dot_CA.paa", 20],
        ["Parts", "#C9C9C9", "\A3\ui_f\data\map\markers\military\dot_CA.paa", 8]
    ]];
    missionNamespace setVariable ["WaldoEcoResearch_ResearchCatalog", [
        ["Mechanized Lvl.1", "Workshop doctrine for basic vehicle crews.", [["Money", 2], ["Parts", 1]], [], 45, "\A3\ui_f\data\map\markers\military\dot_CA.paa", "#E8E8E8", false, []],
        ["Air Lvl.1", "Flight planning and support procedures.", [["Money", 3], ["Parts", 2]], [], 60, "\A3\ui_f\data\map\markers\military\dot_CA.paa", "#8ED1FC", false, []]
    ]];
    missionNamespace setVariable ["WaldoEcoBuild_BuildCatalog", [
        ["Wind Turbine", "A field turbine feeding steady power into the grid.", [["Money", 6], ["Minerals", 10]], [], 70, "\A3\ui_f\data\map\markers\military\dot_CA.paa", "#8ED1FC", false, "Land_wpp_Turbine_V2_F", "Electricity", 4, 20, 0, 0, 0, [], 0, [], "", 0, ["ALL"], "Power"],
        ["Field Fortification", "Precast barriers for a quick defensive line.", [["Money", 3], ["Minerals", 6]], [], 35, "\A3\ui_f\data\map\markers\military\dot_CA.paa", "#D8D0C0", false, "Land_HBarrier_5_F", "", 0, 0, 0, 0, 0, [], 0, [], "", 0, ["ALL"], "Fortification"]
    ]];
    missionNamespace setVariable ["WaldoEcoBuy_PurchaseCatalog", [
        ["Hunter HMG", "NATO mechanized patrol vehicle.", [["Money", 6], ["Parts", 1]], ["Mechanized Lvl.1"], "B_MRAP_01_hmg_F", "Ground", "EVERYONE", "\A3\ui_f\data\map\markers\military\dot_CA.paa", "#66B3FF"],
        ["Ghost Hawk", "Medium transport helicopter.", [["Money", 12], ["Parts", 3]], ["Air Lvl.1"], "B_Heli_Transport_01_F", "Air", "EVERYONE", "\A3\ui_f\data\map\markers\military\dot_CA.paa", "#66B3FF"]
    ]];
    missionNamespace setVariable ["WaldoEcoResource_SideResources_WEST", [["Money", 510], ["Minerals", 260], ["Electricity", 40], ["Parts", 32]]];

    switch (_case) do {
        case "economy-resources": {[] call Waldo_fnc_EcoResource_promptResourceSettings;};
        case "economy-resource-config": {[] call Waldo_fnc_EcoResource_promptResourceConfig;};
        case "economy-research": {[objNull, 0] call Waldo_fnc_EcoResearch_promptResearchConfig;};
        case "economy-build": {[objNull, 0] call Waldo_fnc_EcoBuild_promptBuildConfig;};
        case "economy-purchases": {[objNull, 0] call Waldo_fnc_EcoBuy_promptPurchaseConfig;};
        case "economy-builder": {[] call Waldo_fnc_EcoCore_promptUnifiedSaveSystem;};
        case "economy-drop-point": {[[0, 0, 0], 0] call Waldo_fnc_EcoBuy_promptDropPoint;};
        default {[] call Waldo_fnc_EcoResource_promptResourceSettings;};
    };
    waitUntil {
        uiSleep 0.05;
        _display = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
        !isNull _display && {_display getVariable ["WaldoEcoCore_FitComplete", false]}
    };
    private _findings = _display getVariable ["WaldoEcoCore_FitFindings", []];
    diag_log format ["WMP DOC CAPTURE LAYOUT: case=%1 findings=%2 card=%3", _case, _findings, _display getVariable ["WaldoEcoCore_PromptCardBounds", []]];
    _ready = _findings isEqualTo [];
};

if ((_case find "interaction-") == 0) then {
    private _parts = _case splitString "-";
    private _challengeId = _parts param [1, "wirecut"];
    private _state = _parts param [2, "active"];
    private _config = [_challengeId, "standard"] call Waldo_fnc_MiniGameEquipmentDifficultyConfig;
    private _opened = [_challengeId, _config, {}, {}] call Waldo_fnc_MiniGameChallenge;
    if (_opened) then {
        waitUntil {
            uiSleep 0.02;
            _display = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
            !isNull _display
        };
        if (_state isEqualTo "active") then {
            private _begin = _display getVariable ["Waldo_IMG_BriefingBegin", controlNull];
            if (!isNull _begin) then {
                [_begin] call (_display getVariable ["Waldo_IMG_BriefingActivate", {}]);
            };
            uiSleep 0.35;
        };
        private _findings = [_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;
        diag_log format ["WMP DOC CAPTURE LAYOUT: case=%1 findings=%2 bounds=%3", _case, _findings, _display getVariable ["Waldo_IMG_Bounds", []]];
        _ready = _findings isEqualTo []
            && {if (_state isEqualTo "active") then {_display getVariable ["Waldo_IMG_Started", false]} else {true}};
    };
};

if (_case == "safestart-countdown") then {
    missionNamespace setVariable ["Waldo_SafeStart_Active", true, true];
    missionNamespace setVariable ["Waldo_SafeStart_EndTime", serverTime + 125, true];
    [true, "DOCUMENTATION"] call Waldo_fnc_SafeStartApply;
    uiSleep 1.2;
    private _mainDisplay = findDisplay 46;
    private _hudControl = if (isNull _mainDisplay) then {controlNull} else {_mainDisplay displayCtrl 5300};
    _ready = !isNull _hudControl && {ctrlShown _hudControl};
};

if (_case == "endex") then {
    missionNamespace setVariable ["Waldo_AAR_StartTime", serverTime - 2470, true];
    missionNamespace setVariable ["Waldo_AAR_KIA", [3, 5, 0, 1], true];
    missionNamespace setVariable ["Waldo_AAR_WIA", [7, 2, 0, 0], true];
    missionNamespace setVariable ["Waldo_AAR_VehicleKIA", [1, 2, 0, 0], true];
    missionNamespace setVariable ["Waldo_AAR_FriendlyFire", 0, true];
    missionNamespace setVariable ["Waldo_AAR_Objectives", [["Secure Relay", "SUCCEEDED"], ["Recover Intel", "SUCCEEDED"]], true];
    missionNamespace setVariable ["Waldo_ENDEX_ReportDuration", 60];
    [] call Waldo_fnc_ENDEX;
    uiSleep 1;
    _ready = missionNamespace getVariable ["Waldo_ENDEX_Active", false];
};

if ((_case find "notifications-") == 0) then {
    [] call Waldo_fnc_ClearUiPanels;
    switch (_case) do {
        case "notifications-semantic-states": {
            ["INFORMATION", "A neutral operational update with an [i] symbol.", "INFO", 0, "TOP", "DOC_INFO", "WMP NOTIFICATIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            ["SYSTEM READY", "The requested operation completed successfully.", "SUCCESS", 0, "TOP_RIGHT", "DOC_SUCCESS", "WMP NOTIFICATIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            ["ACTION REQUIRED", "Review the highlighted condition before continuing.", "WARNING", 0, "BOTTOM_LEFT", "DOC_WARNING", "WMP NOTIFICATIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            ["CONNECTION LOST", "The service did not respond; use the documented fallback.", "ERROR", 0, "BOTTOM_RIGHT", "DOC_ERROR", "WMP NOTIFICATIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            uiSleep 0.4;
            _ready = (count (uiNamespace getVariable ["Waldo_UiPanelRegistry", []])) isEqualTo 4;
        };
        case "notifications-channel-stacking": {
            ["RADIO INTERFERENCE", "Signal quality is degraded.", "ERROR", 0, "BOTTOM_RIGHT", "DOC_EW", "ELECTRONIC WARFARE", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            ["SUPPLY DELIVERED", "Forward logistics crate is ready.", "SUCCESS", 0, "BOTTOM_RIGHT", "DOC_LOGISTICS", "WMP OPERATIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            ["OBJECTIVE UPDATED", "Secure the relay station.", "INFO", 0, "BOTTOM_RIGHT", "DOC_OBJECTIVE", "JOINT OPERATIONS", "REPLACE"] call Waldo_fnc_ShowUiNotification;
            uiSleep 0.4;
            _ready = (count (uiNamespace getVariable ["Waldo_UiPanelRegistry", []])) isEqualTo 3;
        };
        case "notifications-fifo-first": {
            ["FIRST MESSAGE", "This card is displayed before the next request in its channel.", "INFO", 0, "TOP_RIGHT", "DOC_FIFO", "WMP MESSAGE QUEUE", "FIFO"] call Waldo_fnc_ShowUiNotification;
            ["SECOND MESSAGE", "This card waits until the first request is dismissed.", "WARNING", 0, "TOP_RIGHT", "DOC_FIFO", "WMP MESSAGE QUEUE", "FIFO"] call Waldo_fnc_ShowUiNotification;
            uiSleep 0.4;
            private _queue = uiNamespace getVariable ["Waldo_UiPanelQueue", []];
            _ready = (count _queue) isEqualTo 1;
        };
        case "notifications-fifo-second": {
            ["FIRST MESSAGE", "The first request expires before the queue advances.", "INFO", 1, "TOP_RIGHT", "DOC_FIFO", "WMP MESSAGE QUEUE", "FIFO"] call Waldo_fnc_ShowUiNotification;
            ["SECOND MESSAGE", "FIFO delivery advances only after the active card leaves.", "WARNING", 0, "TOP_RIGHT", "DOC_FIFO", "WMP MESSAGE QUEUE", "FIFO"] call Waldo_fnc_ShowUiNotification;
            uiSleep 1.4;
            private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
            private _second = _registry findIf {(_x param [0, ""]) isEqualTo "DOC_FIFO"};
            _ready = _second >= 0 && {(count (uiNamespace getVariable ["Waldo_UiPanelQueue", []])) isEqualTo 0};
        };
    };
};

diag_log format ["WMP DOC CAPTURE READY: case=%1 ready=%2", _case, _ready];
