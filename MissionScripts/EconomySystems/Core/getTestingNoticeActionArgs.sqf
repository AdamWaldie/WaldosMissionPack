/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getTestingNoticeActionArgs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getTestingNoticeActionArgs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    [
        "Waldos Economy Systems Testing Notice Hook",
        {},
        nil,
        0,
        true,
        true,
        "",
        "private _moduleActive = missionNamespace getVariable ['WaldoEcoCore_ModuleActive', true]; private _noticeEnabled = missionNamespace getVariable ['WaldoEcoCore_TestingNoticeEnabled', false]; private _token = missionNamespace getVariable ['WaldoEcoCore_TestingNoticeToken', 0]; private _shownToken = uiNamespace getVariable ['WaldoEcoCore_TestingNoticeShownToken', -1]; private _isSelf = (_target == player) || (_this == player); private _mustShow = _shownToken != _token; if (_moduleActive && _noticeEnabled && _isSelf && _mustShow) then {private _parent = findDisplay 46; if (!isNull _parent) then {private _existing = uiNamespace getVariable ['WaldoEcoCore_TestingNoticeDisplay', displayNull]; if (!isNull _existing) then {_existing closeDisplay 1;}; private _disp = _parent createDisplay 'RscDisplayEmpty'; if (!isNull _disp) then {uiNamespace setVariable ['WaldoEcoCore_TestingNoticeShown', true]; uiNamespace setVariable ['WaldoEcoCore_TestingNoticeShownToken', _token]; uiNamespace setVariable ['WaldoEcoCore_TestingNoticeDisplay', _disp]; private _bg = _disp ctrlCreate ['RscText', -1]; _bg ctrlSetPosition [0.08, 0.16, 0.84, 0.58]; _bg ctrlSetBackgroundColor [0.02, 0.02, 0.02, 0.92]; _bg ctrlCommit 0; private _bar = _disp ctrlCreate ['RscText', -1]; _bar ctrlSetPosition [0.08, 0.16, 0.84, 0.035]; _bar ctrlSetBackgroundColor [0.85, 0.42, 0.12, 0.95]; _bar ctrlCommit 0; private _title = _disp ctrlCreate ['RscText', -1]; _title ctrlSetPosition [0.105, 0.205, 0.79, 0.055]; _title ctrlSetText 'SERVER TESTING NOTICE'; _title ctrlSetTextColor [1, 0.86, 0.52, 1]; _title ctrlCommit 0; private _lines = ['Warning: this server is currently doing addon and system testing.','Missions are not the main focus while testing is active.','If you want a normal mission-centered Zeus experience, feel free to pick another server.','If you understand the nature of this server and want to help test, carry on.','Things may explode, put people in lists or become dangerously educational.','Thank you for being patient with the lab monkeys.']; {private _line = _disp ctrlCreate ['RscText', -1]; _line ctrlSetPosition [0.11, 0.285 + (_forEachIndex * 0.052), 0.78, 0.045]; _line ctrlSetText _x; _line ctrlSetTextColor [0.92, 0.92, 0.88, 1]; _line ctrlCommit 0;} forEach _lines; private _close = _disp ctrlCreate ['RscButtonMenu', -1]; _close ctrlSetPosition [0.73, 0.665, 0.17, 0.045]; _close ctrlSetText 'CLOSE'; _close ctrlCommit 0; _close ctrlAddEventHandler ['ButtonClick', {params ['_ctrl']; (ctrlParent _ctrl) closeDisplay 1;}];};};}; false",
        0
    ]
