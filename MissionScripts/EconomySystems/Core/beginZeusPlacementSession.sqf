/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - beginZeusPlacementSession
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_beginZeusPlacementSession via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_disp", displayNull],
        ["_pendingVarName", ""],
        ["_mouseVarName", ""],
        ["_keyVarName", ""],
        ["_resolvePayloadFn", {}],
        ["_confirmPayloadFn", {}]
    ];

    if (isNull _disp) exitWith {false};
    if (_pendingVarName isEqualTo "") exitWith {false};
    if (_mouseVarName isEqualTo "") exitWith {false};
    if (_keyVarName isEqualTo "") exitWith {false};

    [_disp, _pendingVarName, _mouseVarName, _keyVarName] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

    _disp setVariable [_pendingVarName, true];
    _disp setVariable ["WaldoEcoCore_ActivePlacementPendingVar", _pendingVarName];
    _disp setVariable ["WaldoEcoCore_ActivePlacementMouseVar", _mouseVarName];
    _disp setVariable ["WaldoEcoCore_ActivePlacementKeyVar", _keyVarName];
    _disp setVariable ["WaldoEcoCore_ActivePlacementResolveFn", _resolvePayloadFn];
    _disp setVariable ["WaldoEcoCore_ActivePlacementConfirmFn", _confirmPayloadFn];

    private _mouseEH = _disp displayAddEventHandler [
        "MouseButtonDown",
        {
            params ["_display", "_button"];

            private _pendingVarName = _display getVariable ["WaldoEcoCore_ActivePlacementPendingVar", ""];
            private _mouseVarName = _display getVariable ["WaldoEcoCore_ActivePlacementMouseVar", ""];
            private _keyVarName = _display getVariable ["WaldoEcoCore_ActivePlacementKeyVar", ""];

            if (_pendingVarName isEqualTo "") exitWith {false};
            if !(_display getVariable [_pendingVarName, false]) exitWith {false};
            if !(_button isEqualTo 0) exitWith {false};

            private _resolvePayloadFn = _display getVariable ["WaldoEcoCore_ActivePlacementResolveFn", {}];
            private _confirmPayloadFn = _display getVariable ["WaldoEcoCore_ActivePlacementConfirmFn", {}];
            private _payload = [_display] call _resolvePayloadFn;

            [_display, _pendingVarName, _mouseVarName, _keyVarName] call Waldo_fnc_EcoCore_stopZeusPlacementSession;
            [_display, _payload] call _confirmPayloadFn;

            true
        }
    ];

    private _keyEH = _disp displayAddEventHandler [
        "KeyDown",
        {
            params ["_display", "_key"];

            private _pendingVarName = _display getVariable ["WaldoEcoCore_ActivePlacementPendingVar", ""];
            private _mouseVarName = _display getVariable ["WaldoEcoCore_ActivePlacementMouseVar", ""];
            private _keyVarName = _display getVariable ["WaldoEcoCore_ActivePlacementKeyVar", ""];

            if (_pendingVarName isEqualTo "") exitWith {false};
            if !(_display getVariable [_pendingVarName, false]) exitWith {false};

            if (_key isEqualTo 1) then {
                [_display, _pendingVarName, _mouseVarName, _keyVarName] call Waldo_fnc_EcoCore_stopZeusPlacementSession;
                true
            } else {
                false
            };
        }
    ];

    _disp setVariable [_mouseVarName, _mouseEH];
    _disp setVariable [_keyVarName, _keyEH];
    true
