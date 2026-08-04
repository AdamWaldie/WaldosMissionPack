/*
 * Author: WaldoTheWarfighter
 * Submits a completed Zeus Dynamic AA configuration to the dedicated-server authority.
 *
 * The module's clicked position is the detection centre. Zeus does not manually place every AA
 * asset: requested counts are sent to the server, which creates a spaced terrain-safe layout.
 * Scripted callers can still supply exact radarPositions/staticPositions/mobilePositions directly
 * to Waldo_fnc_DynamicAACreate when precise authored placement is required.
 *
 * Arguments:
 * 0: centre <ARRAY> - detection centre chosen by module placement
 * 1: id <STRING> - generated runtime system id
 * 2: settings <HASHMAP> - common settings, counts and optional exact assignment arrays
 * 3: catalogue <HASHMAP> - retained for a stable public call signature; not mutated here
 *
 * Return Value: Nothing.
 * Example: [_centre, _id, _settings, _catalogue] spawn Waldo_fnc_DynamicAAZenPlacement;
 * Current caller: Waldo_fnc_DynamicAAZen.
 */

params [
    ["_centre", [], [[]]], ["_id", "", [""]],
    ["_settings", createHashMap, [createHashMap]], ["_catalogue", createHashMap, [createHashMap]]
];
if !(hasInterface) exitWith {};
uiSleep 0;

private _config = createHashMap;
{_config set [_x, _settings get _x]} forEach keys _settings;
_config set ["id", _id];
_config set ["centre", _centre];
diag_log format [
    "[WMP DYNAMIC AA] ZEN submitting '%1' for server layout: mode=%2 radar=%3 static=%4 mobile=%5 fighters=%6.",
    _id, _config getOrDefault ["assetSelectionMode", "PROFILE"],
    _config getOrDefault ["radarCount", 1], _config getOrDefault ["staticCount", 0],
    _config getOrDefault ["mobileCount", 0], _config getOrDefault ["fighterCount", 0]
];
[_config] remoteExecCall ["Waldo_fnc_DynamicAACreate", 2];
["DYNAMIC AA", "System submitted; the server is placing its assets around the selected centre.", "INFO", "DYNAMIC_AA_SUBMIT", 7]
    call Waldo_fnc_FeatureNotifyLocal;
