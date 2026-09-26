/*
 * Author: WaldoTheWarfighter
 * Stores an expiring area report without revealing or tracking a target object.
 * Locality/authority: server validates shared assignments; commands run only on the current AI owner.
 * Repeat/JIP: tokens and server-time deadlines reject stale work; no historical JIP commands are replayed.
 * Arguments: 0: receiver <GROUP>, grpNull; 1: sender <GROUP>, grpNull; 2: reports <ARRAY>, []; 3: sent time <NUMBER>, -1.
 * Return Value: Nothing.
 * Current callers: ReportServer.
 * Example: [_receiver, _sender, _reports, serverTime] remoteExecCall ["Waldo_fnc_AIPassReportLocal", groupOwner _receiver];
 */
params [["_receiver",grpNull,[grpNull]],["_sender",grpNull,[grpNull]],["_reports",[],[[]]],["_sent",-1,[0]]];
if (remoteExecutedOwner != 2 || {!local _receiver} || {isNull _sender} || {!alive leader _sender}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active",false])} || {[] call Waldo_fnc_AIPassIsPaused}
    || {serverTime - _sent > 15} || {!([_receiver] call Waldo_fnc_AIPassIsEligible)}
    || {!([_receiver,"Waldo_AIPass_ContactReports_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}
    || {!([_sender,"Waldo_AIPass_ContactReports_Enable",true] call Waldo_fnc_AIPassFeatureEnabled)}) exitWith {};
if ((missionNamespace getVariable ["Waldo_AIPass_LambsDangerLoaded",false]) && {missionNamespace getVariable ["Waldo_AIPass_LambsMode","SPLIT"] == "SPLIT"}
    && {!(_receiver getVariable ["lambs_danger_disableGroupAI",false])}) exitWith {};
private _range = if ([leader _sender] call Waldo_fnc_AIPassCanTransmit) then {missionNamespace getVariable ["Waldo_AIPass_ContactReports_Radius",500]} else {missionNamespace getVariable ["Waldo_AIPass_ContactReports_VoiceRange",35]};
if (side _receiver != side _sender || {leader _receiver distance2D leader _sender > _range}) exitWith {};
private _best = _reports param [0,[]];
if (_best isEqualTo []) exitWith {};
private _previous = _receiver getVariable ["Waldo_AIPass_AreaReport",[]];
if (_previous isNotEqualTo [] && {(_previous select 1) >= _sent}) exitWith {};
_receiver setVariable ["Waldo_AIPass_AreaReport",[+(_best select 0),_sent,_sent+30,"REPORT"],true];
