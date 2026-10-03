/*
 * Author: WaldoTheWarfighter
 * Changes Cortex difficulty and tuning settings during a mission, on every machine.
 *
 * Accepts only the settings in Waldo_fnc_CortexTuningSpec. Slider values are clamped to their range,
 * combo values must be one of the listed choices, and anything else is ignored with an RPT line. The
 * accepted values are broadcast, so the server and every headless client use them on each squad's
 * next step. Master/skill changes also update local workers after the complete revision is applied.
 * AI Control and Tuning calls this through the curator bridge.
 * Locality and authority: server-authoritative; a call on a client is forwarded to the server.
 *
 * Repeat/JIP: monotonically ordered local application; joining owners use the full settings snapshot.
 * Arguments:
 * 0: settings <HASHMAP> - variable name to new value, for example Waldo_AIPass_Aggression to 1.5
 *
 * Return Value:
 * Number - settings applied (on a client: -1, forwarded)
 *
 * Example:
 * [createHashMapFromArray [["Waldo_AIPass_Aggression", 1.5], ["Waldo_AIPass_Cohesion", 0.8]]] call Waldo_fnc_CortexTuning;
 * Result: from a trigger, squads become more aggressive and break sooner for the rest of the mission.
 *
 * Current callers: mission triggers and scripts, and Waldo_fnc_FeatureRuntimeApply (AI Tuning).
 */

params [["_settings", createHashMap, [createHashMap]]];
if (!isServer) exitWith {
    [_settings] remoteExecCall ["Waldo_fnc_CortexTuning", 2];
    -1
};
if (remoteExecutedOwner > 2 && {!(remoteExecutedOwner in ((allCurators apply {getAssignedCuratorUnit _x}) select {!isNull _x} apply {owner _x}))}) exitWith {
    diag_log format ["[WMP CORTEX] Tuning from owner %1 refused: only the server or an assigned curator may change it.", remoteExecutedOwner];
    0
};
private _spec = [] call Waldo_fnc_CortexTuningSpec;
private _updates = [];
{
    private _variable = _x;
    private _value = _y;
    private _index = _spec findIf {(_x select 0) == _variable};
    if (_index < 0) then {
        diag_log format ["[WMP CORTEX] Tuning ignored unknown setting %1.", _variable];
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
            diag_log format ["[WMP CORTEX] Tuning ignored %1 = %2 (not a valid %3 value).", _variable, _value, toLowerANSI _kind];
        };
    };
} forEach _settings;
{missionNamespace setVariable [_x select 0, _x select 1, true]} forEach _updates;
if (_updates isNotEqualTo []) then {
    private _revision = (missionNamespace getVariable ["Waldo_AIPass_SettingsRevision",0])+1;
    missionNamespace setVariable ["Waldo_AIPass_SettingsRevision",_revision,true];
    // Retire old positional JIP initializers; joining owners use the authoritative full snapshot.
    if (_updates findIf {(_x select 0) find "Waldo_AIRebalance_" == 0} >= 0) then {[] remoteExecCall ["","Waldo_AIRebalance_RuntimeInit"]};
    if (_updates findIf {(_x select 0) == "Waldo_AIPass_Enable"} >= 0) then {[] remoteExecCall ["","Waldo_AIPass_RuntimeInit"]};
    private _snapshot = _spec apply {[_x select 0,missionNamespace getVariable [_x select 0,_x select 5]]};
    [_revision,_snapshot] remoteExecCall ["Waldo_fnc_CortexSettingsLocal",0];
};
diag_log format ["[WMP CORTEX] Tuning applied: %1", _updates];
count _updates
