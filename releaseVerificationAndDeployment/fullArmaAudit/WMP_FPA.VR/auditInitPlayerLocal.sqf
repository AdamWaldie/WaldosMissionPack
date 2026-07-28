/* Audit-only client continuation. The generated mission runs the pack's real initPlayerLocal.sqf first. */
waitUntil {
    !isNull player
    && {missionNamespace getVariable ["Waldo_QA_FullPackInitObserved", false]}
    && {!isNil "Waldo_QA_fnc_assert"}
};

[] call Waldo_fnc_Init3DMarkers;
private _range = [] execVM "featureRangeClient.sqf";
waitUntil {scriptDone _range};
[] execVM "extendedFeatureStationsClient.sqf";
if (missionNamespace getVariable ["Waldo_QA_RunAutomation", false]) then {
    private _diagnosticDeadline = diag_tickTime + 45;
    waitUntil {
        uiSleep 0.2;
        !((missionNamespace getVariable ["Waldo_Diagnostics_LastReport", []]) isEqualTo [])
        || {diag_tickTime >= _diagnosticDeadline}
    };
    [] execVM "runClientAudit.sqf";
} else {
    diag_log "WMP FULL AUDIT MANUAL READY: automated client cases are disabled";
};
