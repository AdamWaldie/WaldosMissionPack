/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - loadResourceIntoPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_loadResourceIntoPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_disp", ["_index", -1]];

    if (isNull _disp) exitWith {};

    private _catalog = call Waldo_fnc_EcoResource_getResourceCatalog;
    private _list = _disp getVariable ["WaldoEcoResource_ConfigList", controlNull];
    private _nameCtrl = _disp getVariable ["WaldoEcoResource_ConfigNameEdit", controlNull];
    private _colorCtrl = _disp getVariable ["WaldoEcoResource_ConfigColorEdit", controlNull];
    private _baseStorageCtrl = _disp getVariable ["WaldoEcoResource_ConfigBaseStorageEdit", controlNull];

    if (_index < 0 || {_index >= count _catalog}) exitWith {
        _disp setVariable ["WaldoEcoResource_ConfigSelectedIndex", -1];
        if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText ""; _nameCtrl ctrlCommit 0;};
        if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText "#FFFFFF"; _colorCtrl ctrlCommit 0;};
        if (!isNull _baseStorageCtrl) then {_baseStorageCtrl ctrlSetText ""; _baseStorageCtrl ctrlCommit 0;};
        _disp setVariable ["WaldoEcoResource_ConfigIconIndex", 0];
        [_disp] call Waldo_fnc_EcoResource_refreshResourceConfigIcon;
    };

    private _entry = _catalog select _index;
    _disp setVariable ["WaldoEcoResource_ConfigSelectedIndex", _index];

    if (!isNull _list && {(lbCurSel _list) isNotEqualTo _index}) then {
        _list lbSetCurSel _index;
    };
    if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText (_entry param [0, ""]); _nameCtrl ctrlCommit 0;};
    if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText (_entry param [1, "#FFFFFF"]); _colorCtrl ctrlCommit 0;};
    if (!isNull _baseStorageCtrl) then {
        private _baseStorage = _entry param [3, -1];
        _baseStorageCtrl ctrlSetText ([ "", str _baseStorage ] select (_baseStorage >= 0));
        _baseStorageCtrl ctrlCommit 0;
    };

    _disp setVariable ["WaldoEcoResource_ConfigIconIndex", [(_entry param [2, ""])] call Waldo_fnc_EcoCore_findMarkerIconIndex];
    [_disp] call Waldo_fnc_EcoResource_refreshResourceConfigIcon;
