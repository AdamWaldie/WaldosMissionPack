/*
 * Author: WaldoTheWarfighter
 * Changes Smart AI Pass difficulty and tuning settings during a mission, on every machine.
 *
 * Accepts only the settings in Waldo_fnc_AIPassTuningSpec. Slider values are clamped to their range,
 * combo values must be one of the listed choices, and anything else is ignored with an RPT line. The
 * accepted values are broadcast, so the server and every headless client use them on each squad's
 * next step; nothing restarts. The AI Tuning Zeus module calls this through the curator bridge.
 * Locality and authority: server-authoritative; a call on a client is forwarded to the server.
 *
 * Arguments:
 * 0: settings <HASHMAP> - variable name to new value, for example Waldo_AIPass_Aggression to 1.5
 *
 * Return Value:
 * Number - settings applied (on a client: -1, forwarded)
 *
 * Example:
 * [createHashMapFromArray [["Waldo_AIPass_Aggression", 1.5], ["Waldo_AIPass_Cohesion", 0.8]]] call Waldo_fnc_AIPassTuning;
 * Result: from a trigger, squads become more aggressive and break sooner for the rest of the mission.
 *
 * Current callers: mission triggers and scripts, and Waldo_fnc_FeatureRuntimeApply (AI Tuning).
 */

params [["_settings", createHashMap, [createHashMap]]];
if (!isServer) exitWith {
    [_settings] remoteExecCall ["Waldo_fnc_AIPassTuning", 2];
    -1
};
if (remoteExecutedOwner > 2 && {!(remoteExecutedOwner in ((allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x} apply {owner _x}))}) exitWith {
    diag_log format ["[WMP AI PASS] Tuning from owner %1 refused: only the server or an assigned curator may change it.", remoteExecutedOwner];
    0
};
private _spec = [] call Waldo_fnc_AIPassTuningSpec;
private _updates = [];
{
    private _variable = _x;
    private _value = _y;
    private _index = _spec findIf {(_x select 0) == _variable};
    if (_index < 0) then {
        diag_log format ["[WMP AI PASS] Tuning ignored unknown setting %1.", _variable];
    } else {
        (_spec select _index) params ["", "", "", "_kind", "_options"];
        private _accepted = switch (_kind) do {
            case "SLIDER": {
                if (_value isEqualType 0) then {
                    _options params ["_min", "_max", "_decimals"];
                    _value = (_value max _min) min _max;
                    if (_decimals == 0) then {_value = round _value};
                    true
                } else {false};
            };
            case "CHECKBOX": {_value isEqualType true};
            case "COMBO": {_value isEqualType "" && {toUpperANSI _value in ((_options select 0) apply {toUpperANSI _x})}};
            default {false};
        };
        if (_accepted) then {
            if (_value isEqualType "") then {_value = toUpperANSI _value};
            _updates pushBack [_variable, _value];
        } else {
            diag_log format ["[WMP AI PASS] Tuning ignored %1 = %2 (not a valid %3 value).", _variable, _value, toLowerANSI _kind];
        };
    };
} forEach _settings;
{missionNamespace setVariable [_x select 0, _x select 1, true]} forEach _updates;
if (_updates isNotEqualTo []) then {
    // One ordered payload, as the runtime-control bridge does, so a headless client never mixes old and new values.
    [_updates, false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
};
diag_log format ["[WMP AI PASS] Tuning applied: %1", _updates];
count _updates
