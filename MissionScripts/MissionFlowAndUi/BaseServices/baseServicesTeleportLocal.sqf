/*
 * Author: WaldoTheWarfighter
 * Purpose: Moves the owning player between registered services with a configurable screen and
 * exposure transition. The move occurs after fade-out, never through a visible world frame.
 * Locality / Authority: Player-owner only; accepts authenticated server dispatch.
 * Repeat / JIP: Each request supersedes an older transition by token; no JIP state persists.
 * Arguments: player <OBJECT>, destination <OBJECT>, transition <STRING preset or ARRAY of
 * [key,value] overrides> (STANDARD), destination label <STRING> (Destination).
 * Keys: preset, fadeOut, hold, fadeIn, colour, text, aperture.
 * Return Value: <BOOL> started. Current caller: Waldo_fnc_BaseServicesTeleportServer.
 * Example: [player, fobRadio, "TRAVEL", "Forward Base"]
 *     remoteExecCall ["Waldo_fnc_BaseServicesTeleportLocal", player];
 */
params [["_unit", objNull, [objNull]], ["_destination", objNull, [objNull]],
    ["_transition", "STANDARD", ["", []]], ["_destinationName", "Destination", [""]]];
if (!hasInterface || {!local _unit} || {_unit isNotEqualTo player} || {isNull _destination}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
private _near = _destination modelToWorld [0, 2, 0];
private _clear = _near findEmptyPosition [0, 6, typeOf _unit];
if (_clear isEqualTo []) exitWith {
    ["BASE SERVICES", "No clear arrival position at that destination.", "WARNING", "BASE_TELEPORT"] call Waldo_fnc_FeatureNotifyLocal;
    false
};
private _options = createHashMap;
if (_transition isEqualType "") then {
    _options set ["preset", toUpperANSI _transition];
} else {
    {
        if (_x isEqualType [] && {count _x == 2} && {(_x select 0) isEqualType ""}) then {
            _options set [toLowerANSI (_x select 0), _x select 1];
        };
    } forEach _transition;
};
private _preset = _options getOrDefault ["preset", "STANDARD"];
if !(_preset isEqualType "") then {_preset = "STANDARD"};
_preset = toUpperANSI _preset;
private _travelText = format ["Traveling to %1...", _destinationName];
private _values = switch (_preset) do {
    case "QUICK": {[0.35, 0, 0.5, "BLACK", "", -1]};
    case "TRAVEL": {[3, 0.5, 5, "BLACK", _travelText, -1]};
    case "NIGHT": {[1.4, 0.5, 2.5, "BLACK", "", 15]};
    case "DAYLIGHT": {[0.8, 0.2, 1.5, "WHITE", "", 50]};
    case "NONE": {[0, 0, 0, "BLACK", "", -1]};
    default {[0.5, 0.1, 0.7, "BLACK", "", -1]};
};
{
    _x params ["_key", "_slot", "_low", "_high"];
    private _candidate = _options getOrDefault [_key, -1];
    if (_candidate isEqualType 0 && {_candidate >= 0}) then {
        _values set [_slot, (_candidate max _low) min _high];
    };
} forEach [["fadeout", 0, 0.1, 8], ["hold", 1, 0, 10], ["fadein", 2, 0.1, 8]];
_values params ["_out", "_hold", "_in", "_colour", "_text", "_aperture"];
private _customColour = _options getOrDefault ["colour", _colour];
if (_customColour isEqualType "" && {toUpperANSI _customColour in ["BLACK", "WHITE"]}) then {
    _colour = toUpperANSI _customColour;
};
private _customText = _options getOrDefault ["text", _text];
if (_customText isEqualType "") then {_text = _customText};
private _customAperture = _options getOrDefault ["aperture", _aperture];
if (_customAperture isEqualType 0) then {_aperture = _customAperture};
if (_aperture < 0.1 || {_aperture > 100}) then {_aperture = -1};

private _priorForced = missionNamespace getVariable ["Waldo_BaseServices_PriorAperture", []];
if (_priorForced isNotEqualTo []) then {
    _priorForced params [["_value", -1, [0]], ["_wasForced", false, [false]]];
    setAperture (if (_wasForced) then {_value} else {-1});
    missionNamespace setVariable ["Waldo_BaseServices_PriorAperture", []];
};
private _token = (missionNamespace getVariable ["Waldo_BaseServices_TeleportToken", 0]) + 1;
missionNamespace setVariable ["Waldo_BaseServices_TeleportToken", _token];
// A zero-fade arrival must remove a curtain left by the transition it superseded.
if (_out <= 0) then {"WMP_BASE_SERVICE_TELEPORT" cutText ["", "PLAIN"]};
[_unit, _destination, _clear, _values, _colour, _text, _aperture, _token] spawn {
    params ["_unit", "_destination", "_clear", "_values", "_colour", "_text", "_aperture", "_token"];
    _values params ["_out", "_hold", "_in"];
    private _layer = "WMP_BASE_SERVICE_TELEPORT";
    if (_out > 0) then {
        _layer cutText [_text, _colour + " OUT", _out];
        uiSleep _out;
    };
    if ((missionNamespace getVariable ["Waldo_BaseServices_TeleportToken", 0]) isNotEqualTo _token) exitWith {};
    if (isNull _unit || {isNull _destination} || {!alive _unit}) exitWith {_layer cutText ["", _colour + " IN", 0.1]};
    _unit setPosATL _clear;
    _unit setDir getDir _destination;
    if (_aperture > 0) then {
        private _current = apertureParams;
        missionNamespace setVariable ["Waldo_BaseServices_PriorAperture", [
            _current param [0, -1, [0]], _current param [1, false, [false]]
        ]];
        setAperture _aperture;
    };
    if (_hold > 0) then {uiSleep _hold};
    if ((missionNamespace getVariable ["Waldo_BaseServices_TeleportToken", 0]) isNotEqualTo _token) exitWith {};
    if (_in > 0) then {
        _layer cutText ["", _colour + " IN", _in];
        uiSleep _in;
    };
    if (_aperture > 0 && {(missionNamespace getVariable ["Waldo_BaseServices_TeleportToken", 0]) isEqualTo _token}) then {
        private _prior = missionNamespace getVariable ["Waldo_BaseServices_PriorAperture", []];
        _prior params [["_value", -1, [0]], ["_wasForced", false, [false]]];
        setAperture (if (_wasForced) then {_value} else {-1});
        missionNamespace setVariable ["Waldo_BaseServices_PriorAperture", []];
    };
};
true
