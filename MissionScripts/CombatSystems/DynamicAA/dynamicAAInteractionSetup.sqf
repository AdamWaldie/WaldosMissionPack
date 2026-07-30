/*
 * Author: WaldoTheWarfighter
 * Attaches an optional shared shutdown procedure to a Dynamic AA system's central radar. The
 * procedure is installed on every current/JIP machine so clients receive the action while the
 * server retains its callback. Successful completion calls the authoritative AA teardown API with
 * asset deletion disabled, leaving a visibly intact but inactive installation.
 *
 * Arguments:
 * 0: central radar <OBJECT>
 * 1: settings <ARRAY> - [systemId, challengeId, difficulty]
 *
 * Return Value:
 * Boolean - true when a valid setup was submitted
 *
 * Called by:
 * Waldo_fnc_DynamicAACreate through an object-keyed JIP remote execution.
 *
 * Example:
 * [radar, ["AA_NORTH", "circuit", "standard"]] call Waldo_fnc_DynamicAAInteractionSetup;
 */

params [["_radar", objNull, [objNull]], ["_settings", [], [[]]]];
if (isNull _radar || {count _settings < 3}) exitWith {false};
_settings params ["_systemId", "_challengeId", "_difficulty"];
_radar setVariable ["Waldo_DynamicAA_SystemId", _systemId];

[
    _radar,
    _challengeId,
    createHashMapFromArray [
        ["actionTitle", "Bypass and Disable AA Radar"],
        ["difficulty", _difficulty],
        ["retryOnFailure", true],
        ["repeatable", false],
        ["condition", {
            _this getVariable ["Waldo_DynamicAA_InteractionAvailable", false]
        }],
        ["onSuccess", {
            params ["_target"];
            _target setVariable ["Waldo_DynamicAA_InteractionAvailable", false, true];
            [_target getVariable ["Waldo_DynamicAA_SystemId", ""], false, _target] call Waldo_fnc_DynamicAADestroy;
        }],
        ["preset", "aa-radar-shutdown"],
        ["title", "AIR DEFENCE CONTROL RADAR"],
        ["objective", "Isolate the radar control path and take the air-defence network offline."],
        ["briefing", "RADAR SHUTDOWN PROCEDURE"],
        ["successText", "AIR-DEFENCE NETWORK DISABLED"],
        ["skin", "hazard"]
    ]
] call Waldo_fnc_MiniGameInteractionSetup;
true
