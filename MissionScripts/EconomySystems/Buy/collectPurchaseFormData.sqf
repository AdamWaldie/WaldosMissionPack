/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - collectPurchaseFormData
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_collectPurchaseFormData via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {[]};

        private _nameCtrl = _disp getVariable ["WaldoEcoBuy_ConfigNameEdit", controlNull];
        private _descCtrl = _disp getVariable ["WaldoEcoBuy_ConfigDescEdit", controlNull];
        private _costsCtrl = _disp getVariable ["WaldoEcoBuy_ConfigCostsEdit", controlNull];
        private _reqsCtrl = _disp getVariable ["WaldoEcoBuy_ConfigReqsEdit", controlNull];
        private _classCtrl = _disp getVariable ["WaldoEcoBuy_ConfigClassEdit", controlNull];
        private _colorCtrl = _disp getVariable ["WaldoEcoBuy_ConfigColorEdit", controlNull];

        private _name = if (!isNull _nameCtrl) then {ctrlText _nameCtrl} else {""};
        private _desc = if (!isNull _descCtrl) then {ctrlText _descCtrl} else {""};
        private _costs = if (!isNull _costsCtrl) then {[ctrlText _costsCtrl] call Waldo_fnc_EcoCore_parseNameValueText} else {[]};
        private _reqs = if (!isNull _reqsCtrl) then {[ctrlText _reqsCtrl] call Waldo_fnc_EcoCore_parseNameListText} else {[]};
        private _className = if (!isNull _classCtrl) then {ctrlText _classCtrl} else {""};
        private _color = if (!isNull _colorCtrl) then {ctrlText _colorCtrl} else {call Waldo_fnc_EcoResource_getDefaultResourceColor};

        private _typeChoices = call Waldo_fnc_EcoBuy_getPurchaseTypeChoices;
        private _typeIndex = _disp getVariable ["WaldoEcoBuy_ConfigTypeIndex", 1];
        if (_typeIndex < 0 || {_typeIndex >= count _typeChoices}) then {_typeIndex = 1;};
        private _typeName = _typeChoices select _typeIndex;

        private _sideChoices = call Waldo_fnc_EcoBuy_getPurchaseSideChoices;
        private _sideIndex = _disp getVariable ["WaldoEcoBuy_ConfigSideIndex", 0];
        if (_sideIndex < 0 || {_sideIndex >= count _sideChoices}) then {_sideIndex = 0;};
        private _sideName = _sideChoices select _sideIndex;

        private _iconChoices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _iconIndex = _disp getVariable ["WaldoEcoBuy_ConfigIconIndex", 0];
        if (_iconIndex < 0 || {_iconIndex >= count _iconChoices}) then {_iconIndex = 0;};
        private _iconPath = if ((count _iconChoices) > 0) then {
            (_iconChoices select _iconIndex) param [1, call Waldo_fnc_EcoResource_getDefaultResourceIcon]
        } else {
            call Waldo_fnc_EcoResource_getDefaultResourceIcon
        };

        [[_name, _desc, _costs, _reqs, _className, _typeName, _sideName, _iconPath, _color]] call Waldo_fnc_EcoBuy_normalizePurchaseEntry

