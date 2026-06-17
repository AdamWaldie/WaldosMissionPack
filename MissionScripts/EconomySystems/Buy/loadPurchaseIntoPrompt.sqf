/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - loadPurchaseIntoPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_loadPurchaseIntoPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull], ["_index", -1]];

        if (isNull _disp) exitWith {};

        private _catalog = call Waldo_fnc_EcoBuy_getPurchaseCatalog;
        private _nameCtrl = _disp getVariable ["WaldoEcoBuy_ConfigNameEdit", controlNull];
        private _descCtrl = _disp getVariable ["WaldoEcoBuy_ConfigDescEdit", controlNull];
        private _costsCtrl = _disp getVariable ["WaldoEcoBuy_ConfigCostsEdit", controlNull];
        private _reqsCtrl = _disp getVariable ["WaldoEcoBuy_ConfigReqsEdit", controlNull];
        private _classCtrl = _disp getVariable ["WaldoEcoBuy_ConfigClassEdit", controlNull];
        private _colorCtrl = _disp getVariable ["WaldoEcoBuy_ConfigColorEdit", controlNull];

        if (_index < 0 || {_index >= count _catalog}) exitWith {
            _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", -1];
            if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText ""; _nameCtrl ctrlCommit 0;};
            if (!isNull _descCtrl) then {_descCtrl ctrlSetText ""; _descCtrl ctrlCommit 0;};
            if (!isNull _costsCtrl) then {_costsCtrl ctrlSetText ""; _costsCtrl ctrlCommit 0;};
            if (!isNull _reqsCtrl) then {_reqsCtrl ctrlSetText ""; _reqsCtrl ctrlCommit 0;};
            if (!isNull _classCtrl) then {_classCtrl ctrlSetText ""; _classCtrl ctrlCommit 0;};
            if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText "#FFFFFF"; _colorCtrl ctrlCommit 0;};
            _disp setVariable ["WaldoEcoBuy_ConfigTypeIndex", 1];
            _disp setVariable ["WaldoEcoBuy_ConfigSideIndex", 0];
            _disp setVariable ["WaldoEcoBuy_ConfigIconIndex", 0];
            [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigType;
            [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigSide;
            [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigIcon;
        };

        private _entry = _catalog select _index;
        _disp setVariable ["WaldoEcoBuy_ConfigSelectedIndex", _index];

        if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText (_entry param [0, ""]); _nameCtrl ctrlCommit 0;};
        if (!isNull _descCtrl) then {_descCtrl ctrlSetText (_entry param [1, ""]); _descCtrl ctrlCommit 0;};
        if (!isNull _costsCtrl) then {_costsCtrl ctrlSetText ([(_entry param [2, []])] call Waldo_fnc_EcoCore_formatNameValueText); _costsCtrl ctrlCommit 0;};
        if (!isNull _reqsCtrl) then {_reqsCtrl ctrlSetText ([(_entry param [3, []])] call Waldo_fnc_EcoCore_formatNameListText); _reqsCtrl ctrlCommit 0;};
        if (!isNull _classCtrl) then {_classCtrl ctrlSetText (_entry param [4, ""]); _classCtrl ctrlCommit 0;};
            if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText (_entry param [8, "#FFFFFF"]); _colorCtrl ctrlCommit 0;};

        private _typeChoices = call Waldo_fnc_EcoBuy_getPurchaseTypeChoices;
        private _typeIndex = _typeChoices find (_entry param [5, "Ground"]);
        if (_typeIndex < 0) then {_typeIndex = 1;};
        _disp setVariable ["WaldoEcoBuy_ConfigTypeIndex", _typeIndex];
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigType;

        private _sideChoices = call Waldo_fnc_EcoBuy_getPurchaseSideChoices;
        private _sideIndex = _sideChoices find (_entry param [6, "EVERYONE"]);
        if (_sideIndex < 0) then {_sideIndex = 0;};
        _disp setVariable ["WaldoEcoBuy_ConfigSideIndex", _sideIndex];
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigSide;

        private _iconChoices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _iconIndex = _iconChoices findIf {((_x param [1, ""]) isEqualTo (_entry param [7, ""]))};
        if (_iconIndex < 0) then {_iconIndex = 0;};
        _disp setVariable ["WaldoEcoBuy_ConfigIconIndex", _iconIndex];
        [_disp] call Waldo_fnc_EcoBuy_refreshPurchaseConfigIcon;

