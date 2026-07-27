/* Server-authoritative deploy/tear-down request for Waldo_fnc_MHQSetup. */
params [
    ["_target", objNull, [objNull]],
    ["_actor", objNull, [objNull]],
    ["_operation", "", [""]]
];

if (!isServer) exitWith {
    _this remoteExecCall ["Waldo_fnc_MHQRequestServer", 2];
    false
};

private _requestOwner = if (isRemoteExecuted) then {remoteExecutedOwner} else {owner _actor};
if (isNull _target || {isNull _actor} || {!alive _actor}) exitWith {false};
if (isRemoteExecuted && {_requestOwner != owner _actor}) exitWith {false};
if (!(_target getVariable ["Waldo_MHQ_ServerConfigured", false])) exitWith {false};
if (_actor distance _target > 6 || {abs speed _target >= 1}) exitWith {
    ["Command post operation rejected: stop the vehicle and remain within 6 metres.", _actor] call Waldo_fnc_DynamicText;
    false
};
if (_target getVariable ["Waldo_MHQ_Transition", false]) exitWith {false};

_operation = toUpper _operation;
private _isDeployed = _target getVariable ["Waldo_MHQ_Status", false];
if (!(_operation in ["DEPLOY", "TEARDOWN"])) exitWith {false};
if ((_operation == "DEPLOY") isEqualTo _isDeployed) exitWith {false};

_target setVariable ["Waldo_MHQ_Transition", true, true];
(_target getVariable ["Waldo_MHQ_Config", ["", false]]) params ["_audioPath", "_logistics"];
private _deployParts = _target getVariable ["Waldo_MHQ_DeployParts", []];

if (_operation == "DEPLOY") then {
    {if (!isNull _x) then {_x hideObjectGlobal false;};} forEach _deployParts;

    private _safePosition = [getPosATL _target, 3.5, getDir _target + 270] call BIS_fnc_relPos;
    private _name = selectRandom ["Able", "Baker", "Charlie", "Delta", "Falcon", "Raven", "Viking", "Northstar", "Iron", "Oak"];
    private _respawn = [side group _actor, _safePosition, "Command Post " + _name] call BIS_fnc_addRespawnPosition;
    private _targetId = (netId _target splitString ":") joinString "_";
    private _markerId = format ["Waldo_MHQ_%1_%2", _targetId, floor diag_tickTime];
    private _marker = createMarker [_markerId, getPosATL _target];
    private _markerColor = switch (side group _actor) do {
        case west: {"ColorWEST"};
        case east: {"ColorEAST"};
        case independent: {"ColorGUER"};
        default {"ColorCIV"};
    };
    _marker setMarkerColor _markerColor;
    _marker setMarkerType "mil_flag";
    _marker setMarkerText ("Command Post " + _name);

    {moveOut _x;} forEach crew _target;
    _target engineOn false;
    _target lock 2;
    _target allowDamage false;
    _target setVariable ["Waldo_MHQ_RespawnHandle", _respawn];
    _target setVariable ["Waldo_MHQ_Marker", _marker];
    _target setVariable ["Waldo_MHQ_Name", _name, true];
    _target setVariable ["Waldo_MHQ_Status", true, true];
    if (_logistics) then {_target setVariable ["Waldo_LogisticsQM_CurrentStatus", true, true];};
    ["Command Post " + _name + " deployed and vehicle locked.", _actor] call Waldo_fnc_DynamicText;
    ["TaskSucceeded", ["", "Command Post " + _name + " Established"]] remoteExecCall ["BIS_fnc_showNotification", 0];
} else {
    {if (!isNull _x) then {_x hideObjectGlobal true;};} forEach _deployParts;
    private _respawn = _target getVariable ["Waldo_MHQ_RespawnHandle", []];
    if !(_respawn isEqualTo []) then {_respawn call BIS_fnc_removeRespawnPosition;};
    private _marker = _target getVariable ["Waldo_MHQ_Marker", ""];
    if (_marker != "") then {deleteMarker _marker;};
    private _name = _target getVariable ["Waldo_MHQ_Name", ""];

    _target lock 0;
    _target allowDamage (_target getVariable ["Waldo_MHQ_OriginalDamageAllowed", true]);
    _target setVariable ["Waldo_MHQ_Status", false, true];
    _target setVariable ["Waldo_MHQ_RespawnHandle", []];
    _target setVariable ["Waldo_MHQ_Marker", ""];
    if (_logistics) then {_target setVariable ["Waldo_LogisticsQM_CurrentStatus", false, true];};
    ["Command Post " + _name + " torn down; vehicle unlocked.", _actor] call Waldo_fnc_DynamicText;
    ["TaskCanceled", ["", "Command Post " + _name + " Torn Down"]] remoteExecCall ["BIS_fnc_showNotification", 0];
};

if (_audioPath != "") then {
    [_target, _audioPath] remoteExecCall ["Waldo_fnc_MHQPlayAudioLocal", 0];
};
_target setVariable ["Waldo_MHQ_Transition", false, true];
diag_log format ["[WMP MHQ] %1 target=%2 actor=%3 owner=%4 parts=%5", _operation, netId _target, name _actor, _requestOwner, count _deployParts];
true
