/*
 * Author: Waldo
 * Publish pub zeus object action.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _flagVar <STRING> - flag var (optional, default: "")
 * 2: _actionArgs <ARRAY> - action args (optional, default: [])
 * 3: _target <SCALAR> - target (optional, default: 0)
 * 4: _useJip <BOOL> - use jip (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_object, _flagVar, _actionArgs, _target, _useJip] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;
 */

    params [
        ["_object", objNull],
        ["_flagVar", ""],
        ["_actionArgs", []],
        ["_target", 0],
        ["_useJip", true]
    ];

    if (isNull _object) exitWith {false};
    if (_flagVar isEqualTo "") exitWith {false};
    if !(_actionArgs isEqualType []) exitWith {false};

    if (!isMultiplayer) exitWith {
        if (!hasInterface) exitWith {false};
        [_object, _flagVar, _actionArgs] call Waldo_fnc_EcoCore_ensureLocalObjectAction;
        true
    };

    private _publishedVar = format ["%1_Published", _flagVar];
    if (_object getVariable [_publishedVar, false]) exitWith {true};

    _object setVariable [_publishedVar, true, true];

    if (_useJip) then {
        private _jipId = [_object, _flagVar] call Waldo_fnc_EcoCore_getPubZeusActionJipId;
        [_object, _actionArgs] remoteExec ["addAction", _target, _jipId];
    } else {
        [_object, _actionArgs] remoteExec ["addAction", _target];
    };

    true
