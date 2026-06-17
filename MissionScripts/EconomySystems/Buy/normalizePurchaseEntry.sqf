/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - normalizePurchaseEntry
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_normalizePurchaseEntry via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []]];

        private _name = [(_entry param [0, ""])] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {[]};

        private _desc = [(_entry param [1, ""])] call Waldo_fnc_EcoCore_trimString;
        private _costs = [(_entry param [2, []])] call Waldo_fnc_EcoCore_normalizeNameValueRows;
        private _requirements = [(_entry param [3, []])] call Waldo_fnc_EcoCore_normalizeNameList;
        private _className = [(_entry param [4, ""])] call Waldo_fnc_EcoCore_trimString;
        private _typeName = [(_entry param [5, "Ground"])] call Waldo_fnc_EcoBuy_normalizePurchaseType;
        private _sideChoices = call Waldo_fnc_EcoBuy_getPurchaseSideChoices;
        private _sideName = [(_entry param [6, "EVERYONE"])] call Waldo_fnc_EcoCore_trimString;
        private _sideIndex = _sideChoices findIf {(toLower _x) isEqualTo (toLower _sideName)};
        if (_sideIndex < 0) then {_sideName = "EVERYONE";} else {_sideName = _sideChoices select _sideIndex;};
        private _icon = [(_entry param [7, call Waldo_fnc_EcoResource_getDefaultResourceIcon])] call Waldo_fnc_EcoCore_trimString;
        private _color = [(_entry param [8, call Waldo_fnc_EcoResource_getDefaultResourceColor])] call Waldo_fnc_EcoResource_normalizeResourceColor;

        [_name, _desc, _costs, _requirements, _className, _typeName, _sideName, _icon, _color]

