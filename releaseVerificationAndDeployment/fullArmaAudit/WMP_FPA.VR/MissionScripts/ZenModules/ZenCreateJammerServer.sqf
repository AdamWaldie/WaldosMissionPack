/*
 * Author: WaldoTheWarfighter
 * Validates a curator request, creates a jammer emitter on the server, and registers its complete
 * radio and interaction configuration. Creation and registry mutation stay server-authoritative;
 * Waldo_fnc_Jammer broadcasts the interaction payload for current clients and JIP. The current
 * named key/value payload is preferred; older positional 9-, 12-, 15- and 18-field payloads remain
 * supported without block-local params shadowing their parsed values.
 *
 * Arguments:
 * 0: placement position <ARRAY>
 * 1: settings <ARRAY> - named key/value pairs, or a legacy positional settings array
 * 2: requesting curator <OBJECT>
 * 3: existing emitter <OBJECT> (default objNull; when supplied, no object is spawned or repositioned)
 *
 * Return Value:
 * Object - created emitter, or objNull when validation fails
 *
 * Current caller: Waldo_fnc_ZenJammerPlace through a server-targeted remote execution.
 *
 * Example:
 * [[100,100,0], [["radius",300],["side","WEST"],["bands","ALL"],
 * ["className","Land_DataTerminal_01_F"]], player]
 *     remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
 */

params [
    ["_position", [], [[]]],
    ["_settings", [], [[]]],
    ["_actor", objNull, [objNull]],
    ["_existingObject", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_position, _settings, player, _existingObject] remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
    objNull
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isRemoteExecuted && {
    isNull _actor
    || {_requestOwner != owner _actor}
    || {isNull (getAssignedCuratorLogic _actor)}
}) exitWith {
    diag_log format ["[WMP ZEN] rejected jammer-create request owner=%1 actor=%2", _requestOwner, _actor];
    objNull
};
if ((count _position) < 2 || {_settings isEqualTo []}) exitWith {objNull};

private _radius = 300;
private _side = "ALL";
private _bands = "ALL";
private _falloff = 50;
private _strength = 1;
private _active = true;
private _marker = false;
private _sector = [];
private _duty = [];
private _jamUAV = false;
private _show3D = false;
private _className = "Land_PowerGenerator_F";
private _disableChallenge = missionNamespace getVariable ["Waldo_Jamming_DisableChallenge", false];
private _challengeId = missionNamespace getVariable ["Waldo_Jamming_DisableChallengeId", "circuit"];
private _difficulty = missionNamespace getVariable ["Waldo_Jamming_DisableDifficulty", "standard"];
private _engineerOnly = missionNamespace getVariable ["Waldo_Jamming_DisableEngineerOnly", true];
private _resultMode = missionNamespace getVariable ["Waldo_Jamming_DisableResult", "DISABLE"];
private _allowPlayerToggle = missionNamespace getVariable ["Waldo_Jamming_AllowPlayerToggle", true];

private _namedSettings = (_settings param [0, []]) isEqualType []
    && {(count (_settings param [0, []])) >= 2}
    && {((_settings param [0, []]) param [0, 0]) isEqualType ""};
if (_namedSettings) then {
    private _settingsMap = createHashMapFromArray _settings;
    _radius = _settingsMap getOrDefault ["radius", _radius];
    _side = _settingsMap getOrDefault ["side", _side];
    _bands = _settingsMap getOrDefault ["bands", _bands];
    _falloff = _settingsMap getOrDefault ["falloff", _falloff];
    _strength = _settingsMap getOrDefault ["strength", _strength];
    _active = _settingsMap getOrDefault ["active", _active];
    _marker = _settingsMap getOrDefault ["marker", _marker];
    _sector = _settingsMap getOrDefault ["sector", _sector];
    _duty = _settingsMap getOrDefault ["duty", _duty];
    _jamUAV = _settingsMap getOrDefault ["jamUAV", _jamUAV];
    _show3D = _settingsMap getOrDefault ["show3D", _show3D];
    _className = _settingsMap getOrDefault ["className", _className];
    _disableChallenge = _settingsMap getOrDefault ["disableChallenge", _disableChallenge];
    _challengeId = _settingsMap getOrDefault ["challengeId", _challengeId];
    _difficulty = _settingsMap getOrDefault ["difficulty", _difficulty];
    _engineerOnly = _settingsMap getOrDefault ["engineerOnly", _engineerOnly];
    _resultMode = _settingsMap getOrDefault ["resultMode", _resultMode];
    _allowPlayerToggle = _settingsMap getOrDefault ["allowPlayerToggle", _allowPlayerToggle];
} else {
    if ((count _settings) >= 18) then {
        _radius = _settings param [0, _radius];
        _side = _settings param [1, _side];
        _bands = _settings param [2, _bands];
        _falloff = _settings param [3, _falloff];
        _strength = _settings param [4, _strength];
        _active = _settings param [5, _active];
        _marker = _settings param [6, _marker];
        _sector = _settings param [7, _sector];
        _duty = _settings param [8, _duty];
        _jamUAV = _settings param [9, _jamUAV];
        _show3D = _settings param [10, _show3D];
        _className = _settings param [11, _className];
        _disableChallenge = _settings param [12, _disableChallenge];
        _challengeId = _settings param [13, _challengeId];
        _difficulty = _settings param [14, _difficulty];
        _engineerOnly = _settings param [15, _engineerOnly];
        _resultMode = _settings param [16, _resultMode];
        _allowPlayerToggle = _settings param [17, _allowPlayerToggle];
    } else {
        if ((count _settings) >= 15) then {
            _radius = _settings param [0, _radius];
            _side = _settings param [1, _side];
            _bands = _settings param [2, _bands];
            _falloff = _settings param [3, _falloff];
            _strength = _settings param [4, _strength];
            _active = _settings param [5, _active];
            _marker = _settings param [6, _marker];
            _sector = _settings param [7, _sector];
            _duty = _settings param [8, _duty];
            _jamUAV = _settings param [9, _jamUAV];
            _show3D = _settings param [10, _show3D];
            _className = _settings param [11, _className];
            _disableChallenge = _settings param [12, _disableChallenge];
            _challengeId = _settings param [13, _challengeId];
            _difficulty = _settings param [14, _difficulty];
            _engineerOnly = true;
            _resultMode = "DISABLE";
            _allowPlayerToggle = !_disableChallenge;
        } else {
            if ((count _settings) >= 12) then {
                _radius = _settings param [0, _radius];
                _side = _settings param [1, _side];
                _bands = _settings param [2, _bands];
                _falloff = _settings param [3, _falloff];
                _strength = _settings param [4, _strength];
                _active = _settings param [5, _active];
                _marker = _settings param [6, _marker];
                _sector = _settings param [7, _sector];
                _duty = _settings param [8, _duty];
                _jamUAV = _settings param [9, _jamUAV];
                _show3D = _settings param [10, _show3D];
                _className = _settings param [11, _className];
            } else {
                _radius = _settings param [0, _radius];
                _side = _settings param [1, _side];
                _falloff = _settings param [2, _falloff];
                _strength = _settings param [3, _strength];
                _marker = _settings param [4, _marker];
                _sector = _settings param [5, _sector];
                _duty = _settings param [6, _duty];
                _jamUAV = _settings param [7, _jamUAV];
                _className = _settings param [8, _className];
            };
        };
    };
};
private _object = _existingObject;
private _created = isNull _object;
if (_created) then {
    if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {
        diag_log format ["[WMP ZEN] rejected jammer class=%1 owner=%2", _className, _requestOwner];
        objNull
    };
    _object = createVehicle [_className, _position, [], 0, "CAN_COLLIDE"];
    private _groundPosition = [_position select 0, _position select 1, 0];
    _object setPosATL _groundPosition;
    _object setVectorUp (surfaceNormal _groundPosition);
    [_object, _requestOwner, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
} else {
    if ((_object distance2D _position) > 25) exitWith {
        diag_log format ["[WMP ZEN] rejected remote existing jammer object=%1 distance=%2 owner=%3", netId _object, _object distance2D _position, _requestOwner];
        _object = objNull;
    };
    {_x addCuratorEditableObjects [[_object], false]} forEach allCurators;
};
if (isNull _object) exitWith {objNull};
private _interactionOptions = createHashMapFromArray [
    ["disableChallenge", _disableChallenge],
    ["challengeId", _challengeId],
    ["difficulty", _difficulty],
    ["engineerOnly", _engineerOnly],
    ["resultMode", _resultMode],
    ["allowPlayerToggle", _allowPlayerToggle]
];
[_object, _radius, _side, _bands, _falloff, _strength, _active, _marker, _sector, _duty, _jamUAV, _show3D, _interactionOptions]
    call Waldo_fnc_Jammer;
[_object, [_allowPlayerToggle, _disableChallenge, _challengeId, _difficulty, _engineerOnly, _resultMode]] spawn {
    params ["_object", "_interactionSettings"];
    sleep 0.35;
    if (!isNull _object) then {
        [_object, _interactionSettings] remoteExec ["Waldo_fnc_JammerInteraction", 0, _object];
    };
};
diag_log format ["[WMP ZEN] jammer configured object=%1 class=%2 source=%3 requestedClass=%4 actor=%5 owner=%6 simulation=%7 challenge=%8 engineerOnly=%9 result=%10", netId _object, typeOf _object, ["EXISTING", "SPAWN"] select _created, _className, if (isNull _actor) then {"<server>"} else {name _actor}, _requestOwner, simulationEnabled _object, _disableChallenge, _engineerOnly, _resultMode];
if (!isNull _actor) then {
    ["JAMMER PLACED", format ["%1 m field affecting %2.", _radius, _side], 6, "SUCCESS"] remoteExecCall ["Waldo_fnc_JammingNotice", owner _actor];
};
_object
