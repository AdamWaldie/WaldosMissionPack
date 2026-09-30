/*
 * Author: WaldoTheWarfighter
 * Runs disposable Cortex acceptance cases through real public functions and records RPT results.
 * Locality/authority: interface client only; only staged by the audit launcher's explicit CortexAudit switch.
 * Repeat/JIP: one run per machine; fresh fixtures are cleaned up, no production JIP replay.
 * Arguments: None. Return: Nothing (scheduled script).
 * Current callers: staged audit continuation. Example: [] execVM "cortexQAClient.sqf";
 */
if (!hasInterface || {missionNamespace getVariable ["Waldo_CortexQA_ClientRunning",false]}) exitWith {};
missionNamespace setVariable ["Waldo_CortexQA_ClientRunning",true];
[] execVM "cortexQAGuide.sqf";
waitUntil {uiSleep 0.5; !isNull player && {!isNull getAssignedCuratorLogic player} && {missionNamespace getVariable ["Waldo_CortexQA_ServerDone",false]}};
disableSerialization;
[] spawn {
    uiSleep 120;
    if !(missionNamespace getVariable ["Waldo_CortexQA_ClientDone",false]) then {
        diag_log "WMP CORTEX QA CLIENT INCOMPLETE: completion marker missing after 120 seconds";
        missionNamespace setVariable ["Waldo_CortexQA_Phase",["INCOMPLETE","Client tests did not finish. Do not treat the run as a pass. Check the RPT for the last completed case.",[]]];
    };
};
private _failures = [];
private _check = {params ["_id","_ok"]; diag_log format ["WMP CORTEX QA|%1|%2|",_id,["FAIL","PASS"] select _ok]; if (!_ok) then {_failures pushBack _id}};
player createDiaryRecord ["Diary",["Cortex server results",(missionNamespace getVariable ["Waldo_CortexQA_Results",[]] apply {format ["%1: %2",_x select 0,_x select 1]}) joinString "<br/>"]];
missionNamespace setVariable ["Waldo_CortexQA_Phase",["UI checks","Pages open for three seconds each. Edits should survive a tab change, Cancel should discard them, and Apply should reach the server.",[]]];
uiSleep 8;
private _initial = missionNamespace getVariable ["Waldo_AIPass_Aggression",1];
private _testValue = if (abs (_initial-1.23) < 0.01) then {0.77} else {1.23};
private _display = [] call Waldo_fnc_CortexControlOpenLocal;
["UI-01-open",!isNull _display] call _check;
if (!isNull _display) then {
    private _specKeys=(_display getVariable ["Cortex_Spec",[]]) apply {_x select 0};
    ["UI-01b-canonical-settings",count _specKeys == count (_specKeys arrayIntersect _specKeys)] call _check;
    for "_tab" from 0 to 7 do {
        if (isNull _display) exitWith {["UI-interrupted-display-closed",false] call _check};
        (_display displayCtrl 9601) lbSetCurSel _tab; uiSleep 3;
        private _editors=_display getVariable ["Cortex_Editors",[]];
        private _editorKeys=_editors apply {(_x select 1) select 0};
        [format ["UI-02-page-%1",_tab],count _editors > 0] call _check;
        [format ["UI-02b-unique-page-%1",_tab],count _editorKeys == count (_editorKeys arrayIntersect _editorKeys)] call _check;
    };
    (_display displayCtrl 9601) lbSetCurSel 0; uiSleep 3;
    private _findAggression = {((_display getVariable ["Cortex_Editors",[]]) select {((_x select 1) select 0) == "Waldo_AIPass_Aggression"}) param [0,[]]};
    private _entry = call _findAggression;
    if (_entry isNotEqualTo []) then {
        (_entry select 0) sliderSetPosition _testValue;
        (_display displayCtrl 9601) lbSetCurSel 1;
        (_display displayCtrl 9601) lbSetCurSel 0;
        _entry = call _findAggression;
        ["UI-03-pending-across-tabs",_entry isNotEqualTo [] && {abs (sliderPosition (_entry select 0)-_testValue) < 0.01}] call _check;
    } else {["UI-03-pending-across-tabs",false] call _check};
    (_display displayCtrl 9602) ctrlActivate true; uiSleep 3;
    ["UI-04-cancel",isNull _display && {missionNamespace getVariable ["Waldo_AIPass_Aggression",1] == _initial}] call _check;
    _display = [] call Waldo_fnc_CortexControlOpenLocal;
    _entry = call _findAggression;
    if (_entry isNotEqualTo []) then {(_entry select 0) sliderSetPosition _testValue};
    (_display displayCtrl 9603) ctrlActivate true;
    private _until = diag_tickTime + 15;
    waitUntil {uiSleep 0.2; abs ((missionNamespace getVariable ["Waldo_AIPass_Aggression",1])-_testValue) < 0.01 || {diag_tickTime >= _until}};
    ["UI-05-authoritative-apply",_entry isNotEqualTo [] && {isNull _display} && {abs ((missionNamespace getVariable ["Waldo_AIPass_Aggression",1])-_testValue) < 0.01}] call _check;
    ["AI_TUNING",[["Waldo_AIPass_Aggression",_initial]]] call Waldo_fnc_FeatureRuntimeApply;
    diag_log "WMP CORTEX QA CLIENT: restore requested; checking reservation cleanup";
    uiSleep 2;
    private _reservationIndex = (uiNamespace getVariable ["Waldo_UI_ReservationRegistry",[]]) findIf {(_x select 0) == "CORTEX_CONTROL"};
    ["UI-06-reservation-cleanup",_reservationIndex < 0] call _check;
};
missionNamespace setVariable ["Waldo_CortexQA_ClientDone",true];
missionNamespace setVariable ["Waldo_CortexQA_Phase",["Client checks finished",format ["%1 client finding(s). Original mission settings restored. The UI now shows those settings, not the temporary test configuration. Review the diary and RPT results.",count _failures],[]]];
player createDiaryRecord ["Diary",["Cortex client results",format ["Client checks completed. Findings: %1. Server findings: %2. This does not certify all AI scenarios or UI layouts.",_failures,missionNamespace getVariable ["Waldo_CortexQA_ServerFailures",[]]]]];
diag_log format ["WMP CORTEX QA CLIENT COMPLETE: %1 finding(s) %2",count _failures,_failures];
// Leave the real interface available for visual inspection; no synthetic render is used.
[] call Waldo_fnc_CortexControlOpenLocal;
