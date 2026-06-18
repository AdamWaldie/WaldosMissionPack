/*
 * Author: Waldo
 * Prompt resource config.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 * 1: _index <ANY> - index
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_ctrl, _index] call Waldo_fnc_EcoResource_promptResourceConfig;
 */

    if (!hasInterface) exitWith {};

    private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _zeusDisp) exitWith {};

    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    [_zeusDisp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;

    private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
    if (isNull _disp) exitWith {};

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.3, 0, 0.8, 0.73];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.82];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.31, 0.05, 0.46, 0.03];
    _title ctrlSetText "Configure Resources";
    _title ctrlCommit 0;

    private _listLabel = _disp ctrlCreate ["RscText", -1];
    _listLabel ctrlSetPosition [0.31, 0.1, 0.22, 0.025];
    _listLabel ctrlSetText "Configured resources";
    _listLabel ctrlCommit 0;

    private _list = _disp ctrlCreate ["RscListbox", -1];
    _list ctrlSetPosition [0.31, 0.13, 0.39, 0.52];
    _list ctrlCommit 0;

    private _nameLabel = _disp ctrlCreate ["RscText", -1];
    _nameLabel ctrlSetPosition [0.71, 0.13, 0.20, 0.025];
    _nameLabel ctrlSetText "Resource name";
    _nameLabel ctrlCommit 0;

    private _nameEdit = _disp ctrlCreate ["RscEdit", -1];
    _nameEdit ctrlSetPosition [0.71, 0.16, 0.375, 0.045];
    _nameEdit ctrlSetText "";
    _nameEdit ctrlCommit 0;

    private _colorLabel = _disp ctrlCreate ["RscText", -1];
    _colorLabel ctrlSetPosition [0.71, 0.21, 0.175, 0.025];
    _colorLabel ctrlSetText "Color (#RRGGBB)";
    _colorLabel ctrlCommit 0;

    private _colorEdit = _disp ctrlCreate ["RscEdit", -1];
    _colorEdit ctrlSetPosition [0.71, 0.24, 0.175, 0.045];
    _colorEdit ctrlSetText "#FFFFFF";
    _colorEdit ctrlCommit 0;

    private _baseStorageLabel = _disp ctrlCreate ["RscText", -1];
    _baseStorageLabel ctrlSetPosition [0.89, 0.21, 0.175, 0.025];
    _baseStorageLabel ctrlSetText "Base Storage";
    _baseStorageLabel ctrlCommit 0;

    private _baseStorageEdit = _disp ctrlCreate ["RscEdit", -1];
    _baseStorageEdit ctrlSetPosition [0.89, 0.24, 0.175, 0.045];
    _baseStorageEdit ctrlSetText "";
    _baseStorageEdit ctrlCommit 0;

    private _iconLabel = _disp ctrlCreate ["RscText", -1];
    _iconLabel ctrlSetPosition [0.71, 0.29, 0.20, 0.025];
    _iconLabel ctrlSetText "Marker icon";
    _iconLabel ctrlCommit 0;

    private _iconPrev = _disp ctrlCreate ["RscButtonMenu", -1];
    _iconPrev ctrlSetPosition [0.71, 0.33, 0.05, 0.05];
    _iconPrev ctrlSetText "<";
    _iconPrev ctrlCommit 0;

    private _iconValue = _disp ctrlCreate ["RscStructuredText", -1];
    _iconValue ctrlSetPosition [0.765, 0.33, 0.335, 0.05];
    _iconValue ctrlSetStructuredText parseText "";
    _iconValue ctrlCommit 0;

    private _iconNext = _disp ctrlCreate ["RscButtonMenu", -1];
    _iconNext ctrlSetPosition [0.99, 0.33, 0.05, 0.05];
    _iconNext ctrlSetText ">";
    _iconNext ctrlCommit 0;

    private _add = _disp ctrlCreate ["RscButtonMenu", -1];
    _add ctrlSetPosition [0.71, 0.38, 0.12, 0.05];
    _add ctrlSetText "Add";
    _add ctrlCommit 0;

    private _remove = _disp ctrlCreate ["RscButtonMenu", -1];
    _remove ctrlSetPosition [0.71, 0.43, 0.12, 0.05];
    _remove ctrlSetText "Remove";
    _remove ctrlCommit 0;

    private _save = _disp ctrlCreate ["RscButtonMenu", -1];
    _save ctrlSetPosition [0.71, 0.48, 0.12, 0.05];
    _save ctrlSetText "Save";
    _save ctrlCommit 0;

    private _close = _disp ctrlCreate ["RscButtonMenu", -1];
    _close ctrlSetPosition [0.71, 0.53, 0.12, 0.05];
    _close ctrlSetText "Cancel";
    _close ctrlCommit 0;

    _disp setVariable ["WaldoEcoResource_ConfigBG", _bg];
    _disp setVariable ["WaldoEcoResource_ConfigTitle", _title];
    _disp setVariable ["WaldoEcoResource_ConfigListLabel", _listLabel];
    _disp setVariable ["WaldoEcoResource_ConfigList", _list];
    _disp setVariable ["WaldoEcoResource_ConfigNameLabel", _nameLabel];
    _disp setVariable ["WaldoEcoResource_ConfigNameEdit", _nameEdit];
    _disp setVariable ["WaldoEcoResource_ConfigColorLabel", _colorLabel];
    _disp setVariable ["WaldoEcoResource_ConfigColorEdit", _colorEdit];
    _disp setVariable ["WaldoEcoResource_ConfigBaseStorageLabel", _baseStorageLabel];
    _disp setVariable ["WaldoEcoResource_ConfigBaseStorageEdit", _baseStorageEdit];
    _disp setVariable ["WaldoEcoResource_ConfigIconLabel", _iconLabel];
    _disp setVariable ["WaldoEcoResource_ConfigIconPrev", _iconPrev];
    _disp setVariable ["WaldoEcoResource_ConfigIconValue", _iconValue];
    _disp setVariable ["WaldoEcoResource_ConfigIconNext", _iconNext];
    _disp setVariable ["WaldoEcoResource_ConfigAdd", _add];
    _disp setVariable ["WaldoEcoResource_ConfigRemove", _remove];
    _disp setVariable ["WaldoEcoResource_ConfigSave", _save];
    _disp setVariable ["WaldoEcoResource_ConfigClose", _close];
    _disp setVariable ["WaldoEcoResource_ConfigIconIndex", 0];
    _disp setVariable ["WaldoEcoResource_ConfigSelectedIndex", -1];
    {
        _x setVariable ["WaldoEcoResource_ZeusDisplay", _disp];
    } forEach [_add, _remove, _save, _close, _iconPrev, _iconNext];

    _list ctrlAddEventHandler [
        "LBSelChanged",
        {
            params ["_ctrl", "_index"];
            private _disp = ctrlParent _ctrl;
            [_disp, _index] call Waldo_fnc_EcoResource_loadResourceIntoPrompt;
        }
    ];

    _iconPrev setVariable ["WaldoEcoResource_Delta", -1];
    _iconNext setVariable ["WaldoEcoResource_Delta", 1];

    {
        _x ctrlAddEventHandler [
            "ButtonClick",
            {
                params ["_ctrl"];

                private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};

                private _delta = _ctrl getVariable ["WaldoEcoResource_Delta", 0];
                [_disp, _delta] call Waldo_fnc_EcoResource_cycleResourceConfigIcon;
            }
        ];
    } forEach [_iconPrev, _iconNext];

    _add ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoResource_collectResourceConfigFormData;
            if ((count _entry) <= 0) exitWith {};

            [_entry param [0, ""], _entry param [1, "#FFFFFF"], _entry param [2, ""], _entry param [3, -1], name player] call Waldo_fnc_EcoResource_addResourceType;

            private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
            private _newIndex = _catalog findIf {((toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""])))};
            _disp setVariable ["WaldoEcoResource_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoResource_populateResourceConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoResource_loadResourceIntoPrompt;
        }
    ];

    _remove ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _list = _disp getVariable ["WaldoEcoResource_ConfigList", controlNull];
            if (isNull _list) exitWith {};

            private _selection = lbCurSel _list;
            if (_selection < 0) exitWith {};

            private _resourceType = _list lbData _selection;
            if (_resourceType isEqualTo "") then {
                _resourceType = _list lbText _selection;
            };

            [_resourceType, name player] call Waldo_fnc_EcoResource_removeResourceType;

            private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
            private _nextIndex = _selection;
            if (_nextIndex >= count _catalog) then {
                _nextIndex = (count _catalog) - 1;
            };
            _disp setVariable ["WaldoEcoResource_ConfigSelectedIndex", _nextIndex];
            [_disp] call Waldo_fnc_EcoResource_populateResourceConfigList;
            [_disp, _nextIndex] call Waldo_fnc_EcoResource_loadResourceIntoPrompt;
        }
    ];

    _save ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            [_disp] call Waldo_fnc_EcoResource_saveResourceConfigSelection;
        }
    ];

    _close ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
            };
        }
    ];

    [_disp, [_nameEdit, _colorEdit, _baseStorageEdit], _nameEdit] call Waldo_fnc_EcoResource_setPromptInputTargets;
    [_disp] call Waldo_fnc_EcoResource_populateResourceConfigList;
    [_disp, lbCurSel _list] call Waldo_fnc_EcoResource_loadResourceIntoPrompt;
