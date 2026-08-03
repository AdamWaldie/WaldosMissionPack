/*
 * Author: WaldoTheWarfighter
 * Validates a curator request, creates a jammer emitter on the server, and registers its complete
 * radio and interaction configuration. Creation and registry mutation stay server-authoritative;
 * Waldo_fnc_Jammer broadcasts the interaction payload for current clients and JIP. The current
 * simplified 15-field payload and older 9-, 12- and advanced 18-field payloads remain supported.
 *
 * Arguments:
 * 0: placement position <ARRAY>
 * 1: settings <ARRAY> - radio settings followed by optional field-disable settings
 * 2: requesting curator <OBJECT>
 *
 * Return Value:
 * Object - created emitter, or objNull when validation fails
 *
 * Current caller: Waldo_fnc_ZenJammerPlace through a server-targeted remote execution.
 *
 * Example:
 * [[100,100,0], [300,"WEST","ALL",50,1,true,false,[],[],false,false,
 * "Land_PowerGenerator_F",true,"circuit","standard",true,"DISABLE",false], player]
 *     remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
 */

params [
    ["_position", [], [[]]],
    ["_settings", [], [[]]],
    ["_actor", objNull, [objNull]]
];

if (!isServer) exitWith {
    [_position, _settings, player] remoteExecCall ["Waldo_fnc_ZenCreateJammerServer", 2];
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
if ((count _position) < 2 || {(count _settings) < 9}) exitWith {objNull};

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

if ((count _settings) >= 18) then {
    _settings params ["_radius", "_side", "_bands", "_falloff", "_strength", "_active", "_marker", "_sector", "_duty", "_jamUAV", "_show3D", "_className", "_disableChallenge", "_challengeId", "_difficulty", "_engineerOnly", "_resultMode", "_allowPlayerToggle"];
} else {
    if ((count _settings) >= 15) then {
        _settings params ["_radius", "_side", "_bands", "_falloff", "_strength", "_active", "_marker", "_sector", "_duty", "_jamUAV", "_show3D", "_className", "_disableChallenge", "_challengeId", "_difficulty"];
        _engineerOnly = true;
        _resultMode = "DISABLE";
        _allowPlayerToggle = !_disableChallenge;
    } else {
        if ((count _settings) >= 12) then {
            _settings params ["_radius", "_side", "_bands", "_falloff", "_strength", "_active", "_marker", "_sector", "_duty", "_jamUAV", "_show3D", "_className"];
        } else {
            _settings params ["_radius", "_side", "_falloff", "_strength", "_marker", "_sector", "_duty", "_jamUAV", "_className"];
        };
    };
};
if !(isClass (configFile >> "CfgVehicles" >> _className)) then {_className = "Land_PowerGenerator_F";};

private _object = createVehicle [_className, _position, [], 0, "CAN_COLLIDE"];
private _groundPosition = [_position select 0, _position select 1, 0];
_object setPosATL _groundPosition;
_object setVectorUp (surfaceNormal _groundPosition);
private _interactionOptions = createHashMapFromArray [
    ["disableChallenge", _disableChallenge],
    ["challengeId", _challengeId],
    ["difficulty", _difficulty],
    ["engineerOnly", _engineerOnly],
    ["resultMode", _resultMode],
    ["allowPlayerToggle", _allowPlayerToggle]
];
[_object, _requestOwner, false, false] call Waldo_fnc_ZenAssignObjectOwnerServer;
[_object, _radius, _side, _bands, _falloff, _strength, _active, _marker, _sector, _duty, _jamUAV, _show3D, _interactionOptions]
    call Waldo_fnc_Jammer;
[_object, [_allowPlayerToggle, _disableChallenge, _challengeId, _difficulty, _engineerOnly, _resultMode]] spawn {
    params ["_object", "_interactionSettings"];
    sleep 0.35;
    if (!isNull _object) then {
        [_object, _interactionSettings] remoteExec ["Waldo_fnc_JammerInteraction", 0, _object];
    };
};
diag_log format ["[WMP ZEN] jammer created object=%1 class=%2 actor=%3 owner=%4 challenge=%5 engineerOnly=%6 result=%7", netId _object, typeOf _object, if (isNull _actor) then {"<server>"} else {name _actor}, _requestOwner, _disableChallenge, _engineerOnly, _resultMode];
if (!isNull _actor) then {
    ["JAMMER PLACED", format ["%1 m field affecting %2.", _radius, _side], 6, "SUCCESS"] remoteExecCall ["Waldo_fnc_JammingNotice", owner _actor];
};
_object
