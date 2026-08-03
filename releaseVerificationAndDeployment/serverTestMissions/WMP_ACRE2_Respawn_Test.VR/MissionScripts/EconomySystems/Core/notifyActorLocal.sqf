/*
 * Local presentation endpoint for server-authoritative Economy feedback.
 * Economy owns this padded WMP panel; it never writes to Arma's shared hint
 * channel and therefore cannot erase SafeStart, EW, or mission-flow feedback.
 */
params [["_message", "", [""]], ["_duration", 12, [0]]];
if (!hasInterface || {_message isEqualTo ""}) exitWith {};
["OPERATIONS UPDATE", _message, "INFO", _duration, "BOTTOM_LEFT", "ECONOMY", "WMP OPERATIONS // ECONOMY"]
    call Waldo_fnc_ShowUiNotification;
