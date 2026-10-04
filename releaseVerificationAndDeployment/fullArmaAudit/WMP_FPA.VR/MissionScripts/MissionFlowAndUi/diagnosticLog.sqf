/*
 * Author: WaldoTheWarfighter
 * Writes one consistently framed WMP diagnostic line to the local RPT.
 * This helper does not change feature state or display player notifications.
 *
 * Arguments:
 * 0: Feature area <STRING>
 * 1: Feature name <STRING>
 * 2: Severity <STRING> (INFO, WARN or ERROR)
 * 3: Event <STRING>
 * 4: Message <STRING>
 * 5: Run ID <STRING> (optional, defaults to active run or ADHOC)
 * 6: Node <STRING> (optional, defaults to SERVER or CLIENT:<owner id>)
 *
 * Return Value: complete log line <STRING>.
 * Locality and authority: Writes only the caller's RPT; it does not mutate feature state.
 * Repeating the call logs another line, while JIP has no replayed diagnostic history.
 * Current callers: RunDiagnostics, RunDiagnosticsClient and feature-specific report paths.
 * Example: ["LOGISTICS", "SUPPLY", "INFO", "READY", "Crate registry loaded"]
 *   call Waldo_fnc_DiagnosticLog;
 * Result: The framed line is written to this machine's RPT and returned to the caller.
 */
params [
    ["_area", "CORE", [""]],
    ["_feature", "GENERAL", [""]],
    ["_level", "INFO", [""]],
    ["_event", "CHECK", [""]],
    ["_message", "", [""]],
    ["_runId", missionNamespace getVariable ["Waldo_Diagnostics_ActiveRun", "ADHOC"], [""]],
    ["_node", "", [""]]
];

if (_runId isEqualTo "") then {_runId = "ADHOC";};
if (_node isEqualTo "") then {
    _node = if (isServer) then {"SERVER"} else {format ["CLIENT:%1", clientOwner]};
};
_level = toUpper _level;
if !(_level in ["INFO", "WARN", "ERROR"]) then {_level = "INFO";};

private _line = format [
    "[WMP DIAG][run=%1][node=%2][area=%3][feature=%4][level=%5][event=%6] %7",
    _runId, toUpper _node, toUpper _area, toUpper _feature, _level, toUpper _event, _message
];
diag_log _line;
_line
