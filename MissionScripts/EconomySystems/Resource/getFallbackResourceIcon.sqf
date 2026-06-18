/*
 * Author: Waldo
 * Get fallback resource icon.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoResource_getFallbackResourceIcon;
 */

    private _fallbackClass = call Waldo_fnc_EcoResource_getFallbackResourceMarkerClass;
    private _fallbackPath = "\A3\ui_f\data\map\markers\military\dot_CA.paa";
    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _index = _choices findIf {
        ((_x param [0, ""]) isEqualTo _fallbackClass)
    };

    if (_index < 0) exitWith {_fallbackPath};
    (_choices select _index) param [1, _fallbackPath]
