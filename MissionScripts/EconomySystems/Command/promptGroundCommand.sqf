/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - promptGroundCommand
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_promptGroundCommand via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    if (!hasInterface) exitWith {};

    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _disp) exitWith {};

    [_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
    [_disp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    [_disp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.33, 0.18, 0.34, 0.46];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.35, 0.20, 0.26, 0.03];
    _title ctrlSetText "Ground Command";
    _title ctrlCommit 0;

    private _listLabel = _disp ctrlCreate ["RscText", -1];
    _listLabel ctrlSetPosition [0.35, 0.24, 0.22, 0.03];
    _listLabel ctrlSetText "Players (GC marked on right)";
    _listLabel ctrlCommit 0;

    private _list = _disp ctrlCreate ["RscListbox", -1];
    _list ctrlSetPosition [0.35, 0.28, 0.30, 0.24];
    _list ctrlCommit 0;

    private _promote = _disp ctrlCreate ["RscButtonMenu", -1];
    _promote ctrlSetPosition [0.35, 0.55, 0.11, 0.05];
    _promote ctrlSetText "Promote";
    _promote ctrlCommit 0;

    private _remove = _disp ctrlCreate ["RscButtonMenu", -1];
    _remove ctrlSetPosition [0.475, 0.55, 0.11, 0.05];
    _remove ctrlSetText "Remove";
    _remove ctrlCommit 0;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [0.60, 0.55, 0.05, 0.05];
    _close ctrlSetText "Ok";
    _close ctrlCommit 0;

    _disp setVariable ["WaldoEcoCommand_PromptBG", _bg];
    _disp setVariable ["WaldoEcoCommand_PromptTitle", _title];
    _disp setVariable ["WaldoEcoCommand_PromptListLabel", _listLabel];
    _disp setVariable ["WaldoEcoCommand_PromptList", _list];
    _disp setVariable ["WaldoEcoCommand_PromptPromote", _promote];
    _disp setVariable ["WaldoEcoCommand_PromptRemove", _remove];
    _disp setVariable ["WaldoEcoCommand_PromptClose", _close];
    _disp setVariable ["WaldoEcoCommand_PromptSelectedIndex", 0];
    _list ctrlAddEventHandler ["LBSelChanged", {
        params ["_ctrl", "_index"];
        private _disp = ctrlParent _ctrl;
        _disp setVariable ["WaldoEcoCommand_PromptSelectedIndex", _index];
        [_disp] call Waldo_fnc_EcoCommand_refreshGroundCommandPrompt;
    }];

    _promote ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = ctrlParent _ctrl;
        if (isNull _disp) exitWith {};

        private _list = _disp getVariable ["WaldoEcoCommand_PromptList", controlNull];
        if (isNull _list) exitWith {};
        private _index = lbCurSel _list;
        if (_index < 0) exitWith {};
        private _uid = _list lbData _index;
        if (_uid isEqualTo "") exitWith {};

        [_uid] call Waldo_fnc_EcoCommand_promoteGroundCommand;
        [_disp] spawn {
            uiSleep 0.2;
            [_this select 0] call Waldo_fnc_EcoCommand_refreshGroundCommandPrompt;
        };
    }];

    _remove ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = ctrlParent _ctrl;
        if (isNull _disp) exitWith {};

        private _list = _disp getVariable ["WaldoEcoCommand_PromptList", controlNull];
        if (isNull _list) exitWith {};
        private _index = lbCurSel _list;
        if (_index < 0) exitWith {};
        private _uid = _list lbData _index;
        if (_uid isEqualTo "") exitWith {};

        [_uid] call Waldo_fnc_EcoCommand_removeGroundCommand;
        [_disp] spawn {
            uiSleep 0.2;
            [_this select 0] call Waldo_fnc_EcoCommand_refreshGroundCommandPrompt;
        };
    }];

    _close ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        [ctrlParent _ctrl] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
    }];

    [_disp] call Waldo_fnc_EcoCommand_refreshGroundCommandPrompt;
