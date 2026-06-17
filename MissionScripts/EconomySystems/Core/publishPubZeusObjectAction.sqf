/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - publishPubZeusObjectAction
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_publishPubZeusObjectAction via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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
