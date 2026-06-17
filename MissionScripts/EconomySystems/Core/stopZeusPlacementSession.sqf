/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - stopZeusPlacementSession
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_stopZeusPlacementSession via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_disp", displayNull],
        ["_pendingVarName", ""],
        ["_mouseVarName", ""],
        ["_keyVarName", ""]
    ];

    if (isNull _disp) exitWith {};

    if !(_mouseVarName isEqualTo "") then {
        private _mouseEH = _disp getVariable [_mouseVarName, -1];
        if ((_mouseEH isEqualType 0) && {_mouseEH >= 0}) then {
            _disp displayRemoveEventHandler ["MouseButtonDown", _mouseEH];
        };
        _disp setVariable [_mouseVarName, -1];
    };

    if !(_keyVarName isEqualTo "") then {
        private _keyEH = _disp getVariable [_keyVarName, -1];
        if ((_keyEH isEqualType 0) && {_keyEH >= 0}) then {
            _disp displayRemoveEventHandler ["KeyDown", _keyEH];
        };
        _disp setVariable [_keyVarName, -1];
    };

    if !(_pendingVarName isEqualTo "") then {
        _disp setVariable [_pendingVarName, false];
    };

    private _activePendingVar = _disp getVariable ["WaldoEcoCore_ActivePlacementPendingVar", ""];
    private _activeMouseVar = _disp getVariable ["WaldoEcoCore_ActivePlacementMouseVar", ""];
    private _activeKeyVar = _disp getVariable ["WaldoEcoCore_ActivePlacementKeyVar", ""];

    if (
        (_activePendingVar isEqualTo _pendingVarName) ||
        (_activeMouseVar isEqualTo _mouseVarName) ||
        (_activeKeyVar isEqualTo _keyVarName)
    ) then {
        _disp setVariable ["WaldoEcoCore_ActivePlacementPendingVar", nil];
        _disp setVariable ["WaldoEcoCore_ActivePlacementMouseVar", nil];
        _disp setVariable ["WaldoEcoCore_ActivePlacementKeyVar", nil];
        _disp setVariable ["WaldoEcoCore_ActivePlacementResolveFn", nil];
        _disp setVariable ["WaldoEcoCore_ActivePlacementConfirmFn", nil];
    };
