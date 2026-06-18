/*
 * Author: Waldo
 * Prompt purchase config.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _ctrl <ANY> - ctrl
 * 1: _index <ANY> - index
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_ctrl, _index] call Waldo_fnc_EcoBuy_promptPurchaseConfig;
 */

        if (!hasInterface) exitWith {};

        private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _zeusDisp) exitWith {};

        [_zeusDisp] call Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt;

        private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
        if (isNull _disp) exitWith {};

                private _bg = _disp ctrlCreate ["RscText", -1];
        _bg ctrlSetPosition [0.08, 0.03, 0.88, 0.92];
        _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
        _bg ctrlCommit 0;

        private _title = _disp ctrlCreate ["RscText", -1];
        _title ctrlSetPosition [0.10, 0.05, 0.82, 0.03];
        _title ctrlSetText "Configure Purchases";
        _title ctrlCommit 0;

        private _nameLabel = _disp ctrlCreate ["RscText", -1];
        _nameLabel ctrlSetPosition [0.10, 0.10, 0.48, 0.025];
        _nameLabel ctrlSetText "Name";
        _nameLabel ctrlCommit 0;

        private _nameEdit = _disp ctrlCreate ["RscEdit", -1];
        _nameEdit ctrlSetPosition [0.10, 0.13, 0.48, 0.045];
        _nameEdit ctrlCommit 0;

        private _descLabel = _disp ctrlCreate ["RscText", -1];
        _descLabel ctrlSetPosition [0.10, 0.185, 0.48, 0.025];
        _descLabel ctrlSetText "Description";
        _descLabel ctrlCommit 0;

        private _descEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _descEdit ctrlSetPosition [0.10, 0.215, 0.48, 0.09];
        _descEdit ctrlCommit 0;

        private _costsLabel = _disp ctrlCreate ["RscText", -1];
        _costsLabel ctrlSetPosition [0.10, 0.32, 0.48, 0.025];
        _costsLabel ctrlSetText "Resource + Cost list (one per line, e.g. Metal=2)";
        _costsLabel ctrlCommit 0;

        private _costsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _costsEdit ctrlSetPosition [0.10, 0.35, 0.48, 0.10];
        _costsEdit ctrlCommit 0;

        private _reqsLabel = _disp ctrlCreate ["RscText", -1];
        _reqsLabel ctrlSetPosition [0.10, 0.47, 0.48, 0.025];
        _reqsLabel ctrlSetText "Requirements (research or buildings, one per line)";
        _reqsLabel ctrlCommit 0;

        private _reqsEdit = _disp ctrlCreate ["RscEditMulti", -1];
        _reqsEdit ctrlSetPosition [0.10, 0.50, 0.48, 0.10];
        _reqsEdit ctrlCommit 0;

        private _classLabel = _disp ctrlCreate ["RscText", -1];
        _classLabel ctrlSetPosition [0.10, 0.615, 0.48, 0.025];
        _classLabel ctrlSetText "Purchase Classname";
        _classLabel ctrlCommit 0;

        private _classEdit = _disp ctrlCreate ["RscEdit", -1];
        _classEdit ctrlSetPosition [0.10, 0.645, 0.48, 0.045];
        _classEdit ctrlCommit 0;

        private _typeLabel = _disp ctrlCreate ["RscText", -1];
        _typeLabel ctrlSetPosition [0.10, 0.705, 0.16, 0.025];
        _typeLabel ctrlSetText "Type of Purchase";
        _typeLabel ctrlCommit 0;

        private _typePrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _typePrev ctrlSetPosition [0.10, 0.735, 0.05, 0.05];
        _typePrev ctrlSetText "<";
        _typePrev ctrlCommit 0;

        private _typeValue = _disp ctrlCreate ["RscText", -1];
        _typeValue ctrlSetPosition [0.16, 0.735, 0.12, 0.05];
        _typeValue ctrlSetText "Ground";
        _typeValue ctrlCommit 0;

        private _typeNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _typeNext ctrlSetPosition [0.29, 0.735, 0.05, 0.05];
        _typeNext ctrlSetText ">";
        _typeNext ctrlCommit 0;

        private _sideLabel = _disp ctrlCreate ["RscText", -1];
        _sideLabel ctrlSetPosition [0.36, 0.705, 0.18, 0.025];
        _sideLabel ctrlSetText "Purchasable By";
        _sideLabel ctrlCommit 0;

        private _sidePrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _sidePrev ctrlSetPosition [0.36, 0.735, 0.05, 0.05];
        _sidePrev ctrlSetText "<";
        _sidePrev ctrlCommit 0;

        private _sideValue = _disp ctrlCreate ["RscText", -1];
        _sideValue ctrlSetPosition [0.42, 0.735, 0.16, 0.05];
        _sideValue ctrlSetText "EVERYONE";
        _sideValue ctrlCommit 0;

        private _sideNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _sideNext ctrlSetPosition [0.59, 0.735, 0.05, 0.05];
        _sideNext ctrlSetText ">";
        _sideNext ctrlCommit 0;

        private _iconLabel = _disp ctrlCreate ["RscText", -1];
        _iconLabel ctrlSetPosition [0.10, 0.80, 0.20, 0.025];
        _iconLabel ctrlSetText "Marker Icon";
        _iconLabel ctrlCommit 0;

        private _iconPrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _iconPrev ctrlSetPosition [0.10, 0.83, 0.05, 0.05];
        _iconPrev ctrlSetText "<";
        _iconPrev ctrlCommit 0;

        private _iconValue = _disp ctrlCreate ["RscStructuredText", -1];
        _iconValue ctrlSetPosition [0.16, 0.83, 0.28, 0.05];
        _iconValue ctrlSetStructuredText parseText "";
        _iconValue ctrlCommit 0;

        private _iconNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _iconNext ctrlSetPosition [0.45, 0.83, 0.05, 0.05];
        _iconNext ctrlSetText ">";
        _iconNext ctrlCommit 0;

        private _colorLabel = _disp ctrlCreate ["RscText", -1];
        _colorLabel ctrlSetPosition [0.52, 0.80, 0.16, 0.025];
        _colorLabel ctrlSetText "Color (#RRGGBB)";
        _colorLabel ctrlCommit 0;

        private _colorEdit = _disp ctrlCreate ["RscEdit", -1];
        _colorEdit ctrlSetPosition [0.52, 0.83, 0.20, 0.045];
        _colorEdit ctrlSetText "#FFFFFF";
        _colorEdit ctrlCommit 0;

        private _listLabel = _disp ctrlCreate ["RscText", -1];
        _listLabel ctrlSetPosition [0.62, 0.10, 0.28, 0.025];
        _listLabel ctrlSetText "Purchase list";
        _listLabel ctrlCommit 0;

        private _list = _disp ctrlCreate ["RscListbox", -1];
        _list ctrlSetPosition [0.62, 0.13, 0.28, 0.72];
        _list ctrlCommit 0;

        private _add = _disp ctrlCreate ["RscButtonMenu", -1];
        _add ctrlSetPosition [0.10, 0.89, 0.10, 0.045];
        _add ctrlSetText "Add";
        _add ctrlCommit 0;

        private _remove = _disp ctrlCreate ["RscButtonMenu", -1];
        _remove ctrlSetPosition [0.24, 0.89, 0.12, 0.045];
        _remove ctrlSetText "Remove";
        _remove ctrlCommit 0;

        private _save = _disp ctrlCreate ["RscButtonMenu", -1];
        _save ctrlSetPosition [0.74, 0.89, 0.10, 0.045];
        _save ctrlSetText "Save";
        _save ctrlCommit 0;

        private _ok = _disp ctrlCreate ["RscButtonMenu", -1];
        _ok ctrlSetPosition [0.86, 0.89, 0.06, 0.045];
        _ok ctrlSetText "Ok";
        _ok ctrlCommit 0;

        _disp setVariable ["WaldoEcoBuy_ConfigBG", _bg];
        _disp setVariable ["WaldoEcoBuy_ConfigTitle", _title];
        _disp setVariable ["WaldoEcoBuy_ConfigNameLabel", _nameLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigNameEdit", _nameEdit];
        _disp setVariable ["WaldoEcoBuy_ConfigDescLabel", _descLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigDescEdit", _descEdit];
        _disp setVariable ["WaldoEcoBuy_ConfigCostsLabel", _costsLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigCostsEdit", _costsEdit];
        _disp setVariable ["WaldoEcoBuy_ConfigReqsLabel", _reqsLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigReqsEdit", _reqsEdit];
        _disp setVariable ["WaldoEcoBuy_ConfigClassLabel", _classLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigClassEdit", _classEdit];
        _disp setVariable ["WaldoEcoBuy_ConfigTypeLabel", _typeLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigTypePrev", _typePrev];
        _disp setVariable ["WaldoEcoBuy_ConfigTypeValue", _typeValue];
        _disp setVariable ["WaldoEcoBuy_ConfigTypeNext", _typeNext];
        _disp setVariable ["WaldoEcoBuy_ConfigSideLabel", _sideLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigSidePrev", _sidePrev];
        _disp setVariable ["WaldoEcoBuy_ConfigSideValue", _sideValue];
        _disp setVariable ["WaldoEcoBuy_ConfigSideNext", _sideNext];
        _disp setVariable ["WaldoEcoBuy_ConfigIconLabel", _iconLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigIconPrev", _iconPrev];
        _disp setVariable ["WaldoEcoBuy_ConfigIconValue", _iconValue];
        _disp setVariable ["WaldoEcoBuy_ConfigIconNext", _iconNext];
        _disp setVariable ["WaldoEcoBuy_ConfigColorLabel", _colorLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigColorEdit", _colorEdit];
        _disp setVariable ["WaldoEcoBuy_ConfigListLabel", _listLabel];
        _disp setVariable ["WaldoEcoBuy_ConfigList", _list];
        _disp setVariable ["WaldoEcoBuy_ConfigAdd", _add];
        _disp setVariable ["WaldoEcoBuy_ConfigRemove", _remove];
        _disp setVariable ["WaldoEcoBuy_ConfigSave", _save];
        _disp setVariable ["WaldoEcoBuy_ConfigOk", _ok];
        _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", -1];
        _disp setVariable ["WaldoEcoBuy_ConfigTypeIndex", 1];
        _disp setVariable ["WaldoEcoBuy_ConfigSideIndex", 0];
        _disp setVariable ["WaldoEcoBuy_ConfigIconIndex", 0];
        {
            _x setVariable ["WaldoEcoBuy_ZeusDisplay", _disp];
        } forEach [_typePrev, _typeNext, _sidePrev, _sideNext, _iconPrev, _iconNext, _add, _remove, _save, _ok];

        _typePrev setVariable ["WaldoEcoBuy_Delta", -1];
        _typeNext setVariable ["WaldoEcoBuy_Delta", 1];
        _sidePrev setVariable ["WaldoEcoBuy_Delta", -1];
        _sideNext setVariable ["WaldoEcoBuy_Delta", 1];
        _iconPrev setVariable ["WaldoEcoBuy_Delta", -1];
        _iconNext setVariable ["WaldoEcoBuy_Delta", 1];

        _list ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_index"];
            private _disp = ctrlParent _ctrl;
            _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", _index];
            [_disp, _index] call Waldo_fnc_EcoBuy_loadPurchaseIntoPrompt;
        }];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuy_Delta", 0]] call Waldo_fnc_EcoBuy_cyclePurchaseConfigType;
            }];
        } forEach [_typePrev, _typeNext];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuy_Delta", 0]] call Waldo_fnc_EcoBuy_cyclePurchaseConfigSide;
            }];
        } forEach [_sidePrev, _sideNext];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuy_Delta", 0]] call Waldo_fnc_EcoBuy_cyclePurchaseConfigIcon;
            }];
        } forEach [_iconPrev, _iconNext];

        _add ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoBuy_collectPurchaseFormData;
            if ((count _entry) <= 0) exitWith {};

            private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
            if ((_catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))}) >= 0) exitWith {};

            _catalog pushBack _entry;
            _catalog = [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog;

            [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalogLocal;
            [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;

            private _newIndex = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))};
            _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoBuy_populatePurchaseConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoBuy_loadPurchaseIntoPrompt;
        }];

        _remove ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _index = _disp getVariable ["WaldoEcoBuy_ConfigSelectedIndex", -1];
            private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
            if (_index < 0 || {_index >= count _catalog}) exitWith {};

            _catalog deleteAt _index;
            _catalog = [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog;

            [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalogLocal;
            [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;

            if (_index >= count _catalog) then {
                _index = (count _catalog) - 1;
            };

            _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", _index];
            [_disp] call Waldo_fnc_EcoBuy_populatePurchaseConfigList;
            [_disp, _index] call Waldo_fnc_EcoBuy_loadPurchaseIntoPrompt;
        }];

        _save ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _index = _disp getVariable ["WaldoEcoBuy_ConfigSelectedIndex", -1];
            private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
            if (_index < 0 || {_index >= count _catalog}) exitWith {};

            private _entry = [_disp] call Waldo_fnc_EcoBuy_collectPurchaseFormData;
            if ((count _entry) <= 0) exitWith {};

            private _duplicate = -1;
            for "_i" from 0 to ((count _catalog) - 1) do {
                if (_i isEqualTo _index) then {continue;};
                if ((toLower ((_catalog select _i) param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))) exitWith {
                    _duplicate = _i;
                };
            };
            if (_duplicate >= 0) exitWith {};

            _catalog set [_index, _entry];
            _catalog = [_catalog] call Waldo_fnc_EcoBuy_normalizePurchaseCatalog;

            [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalogLocal;
            [_catalog] call Waldo_fnc_EcoBuy_setPurchaseCatalog;

            private _newIndex = _catalog findIf {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))};
            _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", _newIndex];
            [_disp] call Waldo_fnc_EcoBuy_populatePurchaseConfigList;
            [_disp, _newIndex] call Waldo_fnc_EcoBuy_loadPurchaseIntoPrompt;
        }];

        _ok ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt;
            };
        }];

        [_disp, [_nameEdit, _descEdit, _costsEdit, _reqsEdit, _classEdit, _colorEdit], _nameEdit] call Waldo_fnc_EcoBuy_setPromptInputTargets;
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigType;
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigSide;
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigIcon;
        [_disp] call Waldo_fnc_EcoBuy_populatePurchaseConfigList;
        [_disp, -1] call Waldo_fnc_EcoBuy_loadPurchaseIntoPrompt;

