/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - getPresetLibraryEntry
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_getPresetLibraryEntry via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
