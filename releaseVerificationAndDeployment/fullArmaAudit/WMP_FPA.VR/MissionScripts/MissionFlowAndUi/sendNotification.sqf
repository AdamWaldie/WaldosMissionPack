/*
 * Author: WaldoTheWarfighter
 * Provides a simple, safe mission-script call for sending one WMP notification to all players, one
 * side, one group, one player, or an explicit list of players. The function accepts plain arguments,
 * validates them locally, converts the audience into the server API's named configuration, and then
 * uses Waldo_fnc_NotificationBroadcast. It is safe to call from initServer.sqf, a trigger, an object
 * init, or another script: clients forward the request to the server and the server resolves the
 * current player owners. Notifications are transient and intentionally are not replayed to JIP.
 * Reusing the same channel lets the shared notification UI coalesce related updates.
 *
 * Arguments:
 * 0: title <STRING> - short heading (default "NOTICE").
 * 1: message <STRING> - body text; an empty message is rejected (default "").
 * 2: type <STRING> - INFO, SUCCESS, WARNING or ERROR (default "INFO").
 * 3: recipients <STRING|SIDE|GROUP|OBJECT|ARRAY> (default "ALL"):
 *    "ALL" sends to every connected player; west/east/independent/civilian sends to that side;
 *    a GROUP sends to its player members; a player OBJECT sends only to that player; and an ARRAY
 *    may contain player objects. Non-player/null objects are ignored.
 * 4: duration <NUMBER> - seconds; 0 is persistent, otherwise clamped to 1-60 (default 8).
 * 5: placement <STRING> - TOP, TOP_RIGHT, CENTER, BOTTOM_LEFT, BOTTOM_CENTER or BOTTOM_RIGHT
 *    (default "TOP_RIGHT").
 * 6: channel <STRING> - replacement/coalescing key for related messages (default "MISSION_MESSAGE").
 * 7: source <STRING> - small source label shown by the theme (default "MISSION").
 *
 * Return Value:
 * Number - players reached when called on the server; 0 when a client has safely forwarded the
 * asynchronous request, or when validation fails.
 *
 * Current callers:
 * Public mission-maker API; the ZEN Send Notification module uses the same broadcast backend.
 *
 * Examples:
 * ["COMMAND", "Move to the marked assembly area.", "INFO"] call Waldo_fnc_SendNotification;
 * ["FALL BACK", "Return to base.", "WARNING", west, 10] call Waldo_fnc_SendNotification;
 * ["DRIVER", "Your vehicle is ready.", "SUCCESS", _driver] call Waldo_fnc_SendNotification;
 */
params [
    ["_title", "NOTICE", [""]],
    ["_message", "", [""]],
    ["_state", "INFO", [""]],
    ["_recipients", "ALL", ["", west, grpNull, objNull, []]],
    ["_duration", 8, [0]],
    ["_placement", "TOP_RIGHT", [""]],
    ["_channel", "MISSION_MESSAGE", [""]],
    ["_source", "MISSION", [""]]
];

if (_message isEqualTo "") exitWith {
    diag_log "[WMP UI] SendNotification rejected an empty message.";
    0
};

_state = toUpperANSI _state;
if !(_state in ["INFO", "SUCCESS", "WARNING", "ERROR"]) then {
    diag_log format ["[WMP UI] SendNotification replaced invalid type '%1' with INFO.", _state];
    _state = "INFO";
};

_placement = toUpperANSI _placement;
if !(_placement in ["TOP", "TOP_RIGHT", "CENTER", "BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"]) then {
    diag_log format ["[WMP UI] SendNotification replaced invalid placement '%1' with TOP_RIGHT.", _placement];
    _placement = "TOP_RIGHT";
};

_duration = if (_duration <= 0) then {0} else {1 max _duration min 60};
private _config = createHashMapFromArray [
    ["title", _title],
    ["message", _message],
    ["state", _state],
    ["duration", _duration],
    ["placement", _placement],
    ["channel", _channel],
    ["source", _source]
];

switch (typeName _recipients) do {
    case "STRING": {
        if !(toUpperANSI _recipients isEqualTo "ALL") then {
            diag_log format ["[WMP UI] SendNotification rejected unknown string audience '%1'; use ALL, a SIDE, GROUP, player OBJECT or player ARRAY.", _recipients];
            _config = createHashMap;
        } else {
            _config set ["audience", "ALL"];
        };
    };
    case "SIDE": {
        _config set ["audience", "SIDE"];
        _config set ["side", _recipients];
    };
    case "GROUP": {
        _config set ["audience", "UNITS"];
        _config set ["units", (units _recipients) select {isPlayer _x}];
    };
    case "OBJECT": {
        _config set ["audience", "UNITS"];
        _config set ["units", [_recipients] select {!isNull _x && {isPlayer _x}}];
    };
    case "ARRAY": {
        _config set ["audience", "UNITS"];
        _config set ["units", _recipients select {_x isEqualType objNull && {!isNull _x} && {isPlayer _x}}];
    };
};

if (_config isEqualTo createHashMap) exitWith {0};
[_config] call Waldo_fnc_NotificationBroadcast
