/*
 * Author: WaldoTheWarfighter
 * Get testing notice action args.
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
 * [_ctrl] call Waldo_fnc_EcoCore_getTestingNoticeActionArgs;
 */

    [
        "Waldos Economy Systems Testing Notice Hook",
        {},
        nil,
        0,
        true,
        true,
        "",
        "private _moduleActive = missionNamespace getVariable ['WaldoEcoCore_ModuleActive', true]; private _noticeEnabled = missionNamespace getVariable ['WaldoEcoCore_TestingNoticeEnabled', false]; private _token = missionNamespace getVariable ['WaldoEcoCore_TestingNoticeToken', 0]; private _shownToken = uiNamespace getVariable ['WaldoEcoCore_TestingNoticeShownToken', -1]; private _isSelf = (_target == player) || (_this == player); if (_moduleActive && _noticeEnabled && _isSelf && {_shownToken != _token}) then {uiNamespace setVariable ['WaldoEcoCore_TestingNoticeShown', true]; uiNamespace setVariable ['WaldoEcoCore_TestingNoticeShownToken', _token]; ['SERVER TESTING IS ACTIVE. Validate the system normally and report the action, object and observed result.', 18] call Waldo_fnc_EcoCore_notifyActorLocal;}; false",
        0
    ]
