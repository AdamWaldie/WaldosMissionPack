/*
 * Author: Waldo
 * Get marker class for icon path.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _icon <STRING> - icon (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_icon] call Waldo_fnc_EcoResource_getMarkerClassForIconPath;
 */

    params [["_icon", ""]];

    private _fallbackClass = call Waldo_fnc_EcoResource_getFallbackResourceMarkerClass;
    if (_icon isEqualTo "") exitWith {_fallbackClass};

    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _index = _choices findIf {
        ((_x param [1, ""]) isEqualTo _icon)
    };

    if (_index < 0) exitWith {_fallbackClass};

    private _markerClass = (_choices select _index) param [0, _fallbackClass];
    if ((toLower _markerClass) isEqualTo "empty") exitWith {_fallbackClass};
    _markerClass
