/*
 * Author: WaldoTheWarfighter
 * Attaches an optional shared authentication procedure to a registered Tactical Display. The
 * action is installed on interface clients while the success callback is retained by the server.
 * A successful procedure broadcasts the unlocked state; the ordinary display access action then
 * becomes available to current and JIP players.
 *
 * Arguments:
 * 0: tactical-display object <OBJECT>
 * 1: settings <ARRAY> - [challengeId, difficulty]
 *
 * Return Value:
 * Boolean - true when a valid setup was submitted
 *
 * Called by:
 * Waldo_fnc_TacticalDisplayRegister through an object-keyed JIP remote execution.
 *
 * Example:
 * [mapBoard, ["commandinput", "standard"]] call Waldo_fnc_TacticalDisplayInteractionSetup;
 */

params [["_object", objNull, [objNull]], ["_settings", [], [[]]]];
if (isNull _object || {count _settings < 2}) exitWith {false};
_settings params ["_challengeId", "_difficulty"];
[
    _object,
    _challengeId,
    createHashMapFromArray [
        ["actionTitle", "Access Tactical Display"],
        ["directAceAction", true],
        ["difficulty", _difficulty],
        ["retryOnFailure", true],
        ["repeatable", false],
        ["condition", {
            _this getVariable ["Waldo_TacticalDisplay_Registered", false]
            && {!(_this getVariable ["Waldo_TacticalDisplay_Unlocked", false])}
        }],
        ["onSuccess", {params ["_target"]; _target setVariable ["Waldo_TacticalDisplay_Unlocked", true, true]}],
        ["preset", "tactical-display-auth"],
        ["title", "TACTICAL INFORMATION TERMINAL"],
        ["objective", "Authenticate access to the shared tactical picture."],
        ["briefing", "DISPLAY ACCESS PROCEDURE"],
        ["successText", "TACTICAL DISPLAY UNLOCKED"],
        ["skin", "naval"]
    ]
] call Waldo_fnc_MiniGameInteractionSetup;
true
