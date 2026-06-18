/*
 * Author: Waldo
 * Find marker icon index.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _icon <STRING> - icon (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_icon] call Waldo_fnc_EcoCore_findMarkerIconIndex;
 */

    params [["_icon", ""]];

    private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
    private _index = _choices findIf {((_x param [1, ""]) isEqualTo _icon)};
    if (_index < 0) then {_index = 0;};
    _index
