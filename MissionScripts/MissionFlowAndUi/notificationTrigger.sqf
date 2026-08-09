/*
 * Author: WaldoTheWarfighter
 * Turns an ordinary editor object into the centre of a multiplayer-safe notification area. This is
 * the beginner-friendly Eden equivalent of the ZEN Send Notification module. Use an empty helipad
 * or other unobtrusive object as the anchor, place it where players should receive the message, and
 * put the example call in that object's Init field. The anchor remains movable in Eden.
 *
 * Locality and repeat/JIP behaviour:
 * The server creates and owns one local trigger, so entering clients cannot send duplicate cards.
 * Calls made on clients forward to the server. Repeating setup on the same anchor deletes its old
 * trigger before creating the replacement. The notification is transient and is not replayed to
 * JIP players; a JIP player receives it only by entering an active repeatable area normally.
 *
 * Arguments:
 * 0: anchor <OBJECT> - object marking the centre of the trigger area.
 * 1: radius <NUMBER> - circular radius in metres, clamped to 1-5000 (default 25).
 * 2: title <STRING> - short card heading (default "MESSAGE FROM COMMAND").
 * 3: message <STRING> - card body; must not be empty.
 * 4: type <STRING> - INFO, SUCCESS, WARNING or ERROR (default "INFO").
 * 5: recipients <STRING|SIDE|GROUP|OBJECT|ARRAY> - same audience forms as
 *    Waldo_fnc_SendNotification (default "ALL").
 * 6: duration <NUMBER> - seconds; 0 is persistent, otherwise clamped by the notification UI
 *    (default 8).
 * 7: repeatable <BOOL> - true sends again after players leave and re-enter (default false).
 * 8: placement <STRING> - TOP, TOP_RIGHT, CENTER, BOTTOM_LEFT, BOTTOM_CENTER or BOTTOM_RIGHT
 *    (default "TOP_RIGHT").
 * 9: channel <STRING> - coalescing key for related updates (default "MISSION_TRIGGER").
 * 10: source <STRING> - small source label shown by the theme (default "MISSION").
 *
 * Return Value:
 * Boolean - true when setup was accepted/forwarded; false for an invalid anchor or empty message.
 *
 * Current callers:
 * The [WMP] Notification Trigger composition and mission-maker scripts.
 *
 * Example:
 * [this, 25, "MESSAGE FROM COMMAND", "Move to the marked assembly area.", "INFO"]
 *     call Waldo_fnc_NotificationTrigger;
 */
params [
    ["_anchor", objNull, [objNull]],
    ["_radius", 25, [0]],
    ["_title", "MESSAGE FROM COMMAND", [""]],
    ["_message", "", [""]],
    ["_state", "INFO", [""]],
    ["_recipients", "ALL", ["", west, grpNull, objNull, []]],
    ["_duration", 8, [0]],
    ["_repeatable", false, [false]],
    ["_placement", "TOP_RIGHT", [""]],
    ["_channel", "MISSION_TRIGGER", [""]],
    ["_source", "MISSION", [""]]
];

if (isNull _anchor || {_message isEqualTo ""}) exitWith {false};
if (!isServer) exitWith {
    [_anchor, _radius, _title, _message, _state, _recipients, _duration, _repeatable, _placement, _channel, _source]
        remoteExecCall ["Waldo_fnc_NotificationTrigger", 2];
    true
};

private _oldTrigger = _anchor getVariable ["Waldo_NotificationTrigger", objNull];
if (!isNull _oldTrigger) then {deleteVehicle _oldTrigger};

private _trigger = createTrigger ["EmptyDetector", getPosATL _anchor, false];
_trigger setTriggerArea [(_radius max 1) min 5000, (_radius max 1) min 5000, 0, false, -1];
_trigger setTriggerActivation ["ANYPLAYER", "PRESENT", _repeatable];
_trigger setVariable [
    "Waldo_NotificationTrigger_Arguments",
    [_title, _message, _state, _recipients, _duration, _placement, _channel, _source]
];
_trigger setTriggerStatements [
    "this",
    "[thisTrigger] call Waldo_fnc_NotificationTriggerActivate;",
    ""
];
_anchor setVariable ["Waldo_NotificationTrigger", _trigger];
true
