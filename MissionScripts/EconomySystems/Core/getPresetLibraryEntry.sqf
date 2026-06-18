/*
 * Author: Waldo
 * Get preset library entry.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _complexityKey <STRING> - complexity key (optional, default: "")
 * 1: _catalogKey <STRING> - catalog key (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_complexityKey, _catalogKey] call Waldo_fnc_EcoCore_getPresetLibraryEntry;
 */

    params [
        ["_complexityKey", ""],
        ["_catalogKey", ""]
    ];

    private _complexity = toUpper _complexityKey;
    private _catalog = toUpper _catalogKey;
    private _index = (call Waldo_fnc_EcoCore_getPresetLibrary) findIf {
        ((toUpper (_x param [0, ""])) isEqualTo _complexity)
        && {((toUpper (_x param [1, ""])) isEqualTo _catalog)}
    };

    if (_index < 0) exitWith {[]};
    +(call Waldo_fnc_EcoCore_getPresetLibrary select _index)
