/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - normalizeResourceCatalog
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_normalizeResourceCatalog via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_catalog"];

    private _normalized = [];
    private _used = [];
    private _iconChoices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _defaultIcon = call Waldo_fnc_EcoResource_getDefaultResourceIcon;

    {
        private _name = [(_x param [0, ""])] call Waldo_fnc_EcoResource_normalizeResourceName;
        if (_name isNotEqualTo "") then {
            private _lower = toLower _name;
            if ((_used find _lower) < 0) then {
                _used pushBack _lower;

                private _color = [(_x param [1, call Waldo_fnc_EcoResource_getDefaultResourceColor])] call Waldo_fnc_EcoResource_normalizeResourceColor;
                private _icon = _x param [2, _defaultIcon];
                if ((_iconChoices findIf {((_x param [1, ""]) isEqualTo _icon)}) < 0) then {
                    _icon = _defaultIcon;
                };
                private _baseStorage = [(_x param [3, -1])] call Waldo_fnc_EcoResource_normalizeResourceBaseStorage;

                _normalized pushBack [_name, _color, _icon, _baseStorage];
            };
        };
    } forEach _catalog;

    if ((count _normalized) isEqualTo 0) then {
        _normalized pushBack ["Resource", call Waldo_fnc_EcoResource_getDefaultResourceColor, _defaultIcon, -1];
    };

    _normalized
