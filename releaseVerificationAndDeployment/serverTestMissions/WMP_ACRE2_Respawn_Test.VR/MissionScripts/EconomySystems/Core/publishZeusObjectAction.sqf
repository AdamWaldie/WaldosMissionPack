/*
 * Author: WaldoTheWarfighter
 * Publish Zeus object action.
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
 * [_object, _flagVar, _actionArgs, _target, _useJip] call Waldo_fnc_EcoCore_publishZeusObjectAction;
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

    // Publication is global, but ACE/addAction state is local to each player. Always satisfy
    // the local installation first. A server-published marker must never make a joining client
    // skip its own usable action.
    if (hasInterface) then {
        [_object, _flagVar, _actionArgs] call Waldo_fnc_EcoCore_ensureLocalObjectAction;
    };

    if (!isMultiplayer) exitWith {
        hasInterface
    };

    // Clients install locally. Only the authority owns the JIP publication record.
    if (!isServer) exitWith {hasInterface};

    private _publishedVar = format ["%1_Published", _flagVar];
    if (_object getVariable [_publishedVar, false]) exitWith {true};

    _object setVariable [_publishedVar, true, true];

    if (_useJip) then {
        private _jipId = [_object, _flagVar] call Waldo_fnc_EcoCore_getZeusActionJipId;
        [_object, _flagVar, _actionArgs] remoteExec ["Waldo_fnc_EcoCore_ensureLocalObjectAction", _target, _jipId];
    } else {
        [_object, _flagVar, _actionArgs] remoteExec ["Waldo_fnc_EcoCore_ensureLocalObjectAction", _target];
    };

    true
