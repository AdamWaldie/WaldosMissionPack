/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - refreshSaveTestingNoticeMenuState
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_refreshSaveTestingNoticeMenuState via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_tree", controlNull]];

    if (isNull _tree) then {
        private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _disp) exitWith {};
        _tree = [_disp] call Waldo_fnc_EcoCore_getZeusTreeControl;
    };
    if (isNull _tree) exitWith {};

    private _rootIndex = _tree getVariable ["WaldoEcoCore_SaveRootIndex", -1];
    private _childIndex = _tree getVariable ["WaldoEcoCore_SaveNoticeChildIndex", -1];
    if (_rootIndex < 0 || {_childIndex < 0}) exitWith {};

    private _enabled = [] call Waldo_fnc_EcoCore_isTestingNoticeEnabled;
    _tree tvSetText [[_rootIndex, _childIndex], format ["Testing Notice: %1", ["OFF", "ON"] select _enabled]];
    _tree tvSetColor [[_rootIndex, _childIndex], [[0.70, 0.70, 0.70, 1], [0.95, 0.78, 0.36, 1]] select _enabled];
    _tree tvSetTooltip [[_rootIndex, _childIndex], [
        "Show a one-time testing notice to players when they first spawn.",
        "Testing notice is active. Players who have not seen it this session will get the popup."
    ] select _enabled];
