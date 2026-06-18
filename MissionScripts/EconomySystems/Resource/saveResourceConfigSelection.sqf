/*
 * Author: Waldo
 * Save resource config selection.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResource_saveResourceConfigSelection;
 */

    params ["_disp"];

    if (isNull _disp) exitWith {};
    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    private _index = _disp getVariable ["WaldoEcoResource_ConfigSelectedIndex", -1];
    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    if (_index < 0 || {_index >= count _catalog}) exitWith {};

    private _entry = [_disp] call Waldo_fnc_EcoResource_collectResourceConfigFormData;
    if ((count _entry) <= 0) exitWith {};

    private _duplicate = _catalog findIf {
        (_forEachIndex isNotEqualTo _index)
        && {(toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""]))}
    };
    if (_duplicate >= 0) exitWith {};

    _catalog set [_index, _entry];
    _catalog = [_catalog] call Waldo_fnc_EcoResource_normalizeResourceCatalog;

    private _types = _catalog apply {_x param [0, "Resource"]};
    missionNamespace setVariable ["WaldoEcoResource_ResourceCatalog", _catalog, true];
    missionNamespace setVariable ["WaldoEcoResource_ResourceTypes", _types, true];
    [] call Waldo_fnc_EcoResource_initializeResourceData;

    private _newIndex = _catalog findIf {((toLower (_x param [0, ""])) isEqualTo (toLower (_entry param [0, ""])))};
    _disp setVariable ["WaldoEcoResource_ConfigSelectedIndex", _newIndex];
    [_disp] call Waldo_fnc_EcoResource_populateResourceConfigList;
    [_disp, _newIndex] call Waldo_fnc_EcoResource_loadResourceIntoPrompt;
