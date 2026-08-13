/*
 * Author: WaldoTheWarfighter
 * Validates and records an AI-profile adoption acknowledgement sent by an ACE headless-client
 * destination. This gives the authoritative server RPT evidence that ordinary migrated AI received
 * the active WMP profile. The newest 100 per-group results are retained for diagnostics.
 *
 * Locality and authority:
 * Server-only remote-execution endpoint. The claimed owner must equal remoteExecutedOwner and own
 * the ACE-reported headless-client entity. Because Arma can update groupOwner just after ACE raises
 * its transfer event, the server waits for that ownership to settle before recording the result.
 * Results are diagnostic state only and are not broadcast/JIP replayed. A repeat report replaces
 * the prior record for the same group.
 *
 * Arguments:
 * 0: group <GROUP> - migrated ordinary AI group.
 * 1: headless-client entity <OBJECT> - ACE destination object used to authenticate the sender.
 * 2: previous owner <NUMBER> - owner before ACE transferred the group.
 * 3: new owner <NUMBER> - HC network owner reported by ACE.
 * 4: applied unit count <NUMBER> - local AI units successfully profiled.
 * 5: profile <STRING> - WMP profile key used by the destination.
 * 6: mode <STRING> - DAY or NIGHT used by the destination.
 *
 * Return Value:
 * Boolean - true when the acknowledgement was authenticated and recorded.
 *
 * Example:
 * [_group, _headlessClient, 2, clientOwner, 8, "LINE", "DAY"]
 *     remoteExecCall ["Waldo_fnc_AIHeadlessAdoptionResultServer", 2];
 * Result: the server logs and stores the verified HC adoption result.
 *
 * Current caller: ACE Headless post-transfer handler installed by Waldo_fnc_AIRebalanceInit.
 */

params [
    ["_group", grpNull, [grpNull]], ["_headlessEntity", objNull, [objNull]],
    ["_previousOwner", 2, [0]], ["_newOwner", -1, [0]],
    ["_applied", 0, [0]], ["_profile", "LINE", [""]], ["_mode", "DAY", [""]]
];
if !(isServer) exitWith {false};
private _sender = remoteExecutedOwner;
if (isNull _group || {isNull _headlessEntity} || {_newOwner <= 2} || {_sender != _newOwner}
    || {owner _headlessEntity != _newOwner}) exitWith {
    diag_log format ["[WMP AI] Rejected HC adoption acknowledgement group=%1 sender=%2 claimedOwner=%3 HCowner=%4 actualOwner=%5.", _group, _sender, _newOwner, owner _headlessEntity, groupOwner _group];
    false
};

[_group, _previousOwner, _newOwner, _applied, _profile, _mode] spawn {
    params ["_group", "_previousOwner", "_newOwner", "_applied", "_profile", "_mode"];
    private _deadline = diag_tickTime + 5;
    waitUntil {groupOwner _group == _newOwner || {isNull _group} || {diag_tickTime >= _deadline}};
    if (isNull _group || {groupOwner _group != _newOwner}) exitWith {
        diag_log format ["[WMP AI] HC adoption ownership did not settle group=%1 claimedOwner=%2 actualOwner=%3.", _group, _newOwner, groupOwner _group];
    };
    private _results = missionNamespace getVariable ["Waldo_AI_HeadlessAdoptionResults", []];
    private _record = [_group, _previousOwner, _newOwner, _applied max 0, toUpperANSI _profile, toUpperANSI _mode, serverTime];
    private _index = _results findIf {(_x param [0, grpNull]) isEqualTo _group};
    if (_index >= 0) then {_results set [_index, _record]} else {_results pushBack _record};
    if (count _results > 100) then {_results deleteRange [0, count _results - 100]};
    missionNamespace setVariable ["Waldo_AI_HeadlessAdoptionResults", _results];
    _group setVariable ["Waldo_AI_LastHeadlessAdoption", [_newOwner, _applied max 0, toUpperANSI _profile, toUpperANSI _mode, serverTime], true];
    diag_log format ["[WMP AI] Verified HC adoption group=%1 previousOwner=%2 owner=%3 applied=%4 profile=%5/%6.", _group, _previousOwner, _newOwner, _applied, toUpperANSI _profile, toUpperANSI _mode];
};
true
