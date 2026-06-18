/*
 * Author: Waldo
 * Get renderable resource icon.
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
 * [_icon] call Waldo_fnc_EcoResource_getRenderableResourceIcon;
 */

    params [["_icon", ""]];

    private _markerClass = [_icon] call Waldo_fnc_EcoResource_getMarkerClassForIconPath;
    if (_markerClass isEqualTo (call Waldo_fnc_EcoResource_getFallbackResourceMarkerClass)) exitWith {
        call Waldo_fnc_EcoResource_getFallbackResourceIcon
    };

    _icon
