/*
 * Author: WaldoTheWarfighter
 * Shares what a squad in contact can see with nearby friendly squads, by radio or by voice.
 *
 * Up to three recent believed positions are sent through the server to current receiving owners.
 * Receivers store an expiring area report for investigation, never reveal or track a target object.
 * Jamming restricts delivery to voice range. Sender/receiver feature gates are rechecked on delivery.
 * Locality/authority: sender owner reports; server validates and batches eight receivers per job step.
 * Repeat/JIP: sender cooldown and timestamps reject duplicate/stale work; reports expire and are not replayed.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: state <HASHMAP>
 * 2: visible <ARRAY> - enemies from Waldo_fnc_AIPassKnowledge seen in the last 10 s
 *
 * Return Value:
 * Number - reports submitted; delivery is asynchronous
 *
 * Example:
 * [_group, _state, _visible] call Waldo_fnc_AIPassContactReport;
 * Result: eligible neighbouring owners receive an expiring area report.
 *
 * Current caller: Waldo_fnc_AIPassGroupTick.
 */

params [["_group", grpNull, [grpNull]], ["_state", createHashMap, [createHashMap]], ["_visible", [], [[]]]];
_state set ["lastReport", time];
if (_visible isEqualTo []) exitWith {0};
if (!local _group || {!([_group,"Waldo_AIPass_ContactReports_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}) exitWith {0};
private _reports = (_visible select [0,3]) apply {[+(_x select 1),1 min (leader _group knowsAbout (_x select 0)),serverTime - (_x select 2)]};
[_group,_reports,serverTime] remoteExecCall ["Waldo_fnc_AIPassReportServer",2];
count _reports
