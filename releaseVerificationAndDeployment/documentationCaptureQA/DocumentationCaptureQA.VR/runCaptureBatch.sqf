/* Cycles documentation states in one Arma process. The capture controller has
 * four seconds after each ready marker before the current UI is closed. */
private _root = missionNamespace getVariable ["Waldo_DocCapture_Root", ""];
private _cases = missionNamespace getVariable ["Waldo_DocCapture_Cases", []];
{
    missionNamespace setVariable ["Waldo_DocCapture_Case", _x];
    call compile preprocessFileLineNumbers (_root + "runCaptureCase.sqf");
    uiSleep 4;

    private _economyDisplay = uiNamespace getVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    if (!isNull _economyDisplay) then {
        _economyDisplay closeDisplay 2;
        uiNamespace setVariable ["WaldoEcoCore_ActiveZeusPromptDisplay", displayNull];
    };
    private _challengeDisplay = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
    if (!isNull _challengeDisplay) then {
        [_challengeDisplay, "CAPTURE_COMPLETE"] call Waldo_fnc_MiniGameEquipmentCleanup;
        _challengeDisplay closeDisplay 2;
        uiNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
    };
    if (_x == "safestart-countdown") then {
        missionNamespace setVariable ["Waldo_SafeStart_Active", false, true];
        missionNamespace setVariable ["Waldo_SafeStart_EndTime", 0, true];
        [false] call Waldo_fnc_SafeStartHud;
    };
    if (_x == "endex") then {
        [] call Waldo_fnc_ENDEXReset;
        uiSleep 0.1;
        private _registry = uiNamespace getVariable ["Waldo_UiPanelRegistry", []];
        private _cleared = (_registry findIf {(_x param [0, ""]) isEqualTo "ENDEX"}) < 0;
        diag_log format ["WMP DOC CAPTURE RESET: case=endex panelCleared=%1", _cleared];
    };
    uiSleep 0.5;
} forEach _cases;
diag_log format ["WMP DOC CAPTURE BATCH COMPLETE: cases=%1", _cases];
