/*
 * Author: WaldoTheWarfighter
 * Removes WMP-owned transient HUD controls and modal displays when the local
 * player dies, the mission ends, or a test harness requests a clean viewport.
 * It does not touch Arma, ACE, ACRE2, TFAR or mission-maker controls.
 *
 * Arguments: None
 * Return Value: Boolean - true after local cleanup
 * Example: [] call Waldo_fnc_CleanupTransientUi;
 */
if (!hasInterface) exitWith {false};

uiNamespace setVariable ["Waldo_SafeStart_NoticeToken", ""];
uiNamespace setVariable ["Waldo_JammingNoticeToken", ""];
uiNamespace setVariable ["Waldo_JammingHudChannels", []];
uiNamespace setVariable ["WaldoEcoCore_NoticeToken", ""];
uiNamespace setVariable ["Waldo_MG_NoticeToken", ""];

// Dynamic mission-maker panels use control references rather than global IDCs.
// Delete only controls registered by Waldo_fnc_ShowUiNotification.
{
    {if (!isNull _x) then {ctrlDelete _x;};} forEach (_x param [1, []]);
} forEach (uiNamespace getVariable ["Waldo_UiPanelRegistry", []]);
uiNamespace setVariable ["Waldo_UiPanelRegistry", []];
uiNamespace setVariable ["Waldo_UiPanelQueue", []];

private _mainDisplay = findDisplay 46;
if (!isNull _mainDisplay) then {
    {
        private _control = _mainDisplay displayCtrl _x;
        if (!isNull _control) then {_control ctrlShow false;};
    } forEach [5299, 5300, 5301, 5309, 5310, 5311, 5312, 5330, 5331, 5340, 5341];
};

if !(isNil "Waldo_MG_fnc_closeTableGameDisplaysLocal") then {
    call Waldo_MG_fnc_closeTableGameDisplaysLocal;
};

private _challenge = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
if (!isNull _challenge) then {
    [_challenge] call Waldo_fnc_MiniGameEquipmentCleanup;
    _challenge closeDisplay 2;
};
uiNamespace setVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
true
