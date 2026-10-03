/*
 * Author: WaldoTheWarfighter
 * Normalizes feature diagnostics into the public WMP diagnostic report form.
 * Checks use [area, feature, state, detail]. This helper is unscheduled,
 * side-effect-free and safe on server, client or hosted authority.
 * Locality and authority: Pure report construction on the caller, with no server mutation.
 * Repeated calls create a new report from supplied checks; no JIP replay is needed.
 * Arguments: 0: feature key <STRING> ("unknown");
 *   1: check rows <ARRAY of [area, feature, state, detail]> ([]).
 * Return Value: <HASHMAP> with schema, feature, state, checks, errorCount, generatedAt,
 *   locality and clientOwner keys.
 * Current callers: feature-specific diagnostics and WMP's combined diagnostic runners.
 * Example: ["base_services", [["base", "teleport", "ACTIVE", "Two destinations"]]]
 *   call Waldo_fnc_DiagnosticFeatureReport;
 * Result: Returns a normalised report with the supplied checks and an ACTIVE state.
 */
params [
    ["_feature", "unknown", [""]],
    ["_checks", [], [[]]]
];

private _errorCount = {_x param [2, "ERROR"] == "ERROR"} count _checks;
private _state = if (_checks isEqualTo []) then {"UNCONFIGURED"} else {
    if (_errorCount > 0) then {"ERROR"} else {
        if ((_checks findIf {(_x param [2, ""]) == "ACTIVE"}) >= 0) then {"ACTIVE"} else {
            if ((_checks findIf {(_x param [2, ""]) == "LOADED"}) >= 0) then {"LOADED"} else {
                _checks select 0 param [2, "UNCONFIGURED"]
            }
        }
    }
};

createHashMapFromArray [
    ["schema", 1],
    ["feature", _feature],
    ["state", _state],
    ["checks", _checks],
    ["errorCount", _errorCount],
    ["generatedAt", diag_tickTime],
    ["locality", if (isServer) then {if (hasInterface) then {"HOST"} else {"SERVER"}} else {"CLIENT"}],
    ["clientOwner", clientOwner]
]
