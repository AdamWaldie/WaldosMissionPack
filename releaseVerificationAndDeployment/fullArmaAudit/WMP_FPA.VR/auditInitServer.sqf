/* Audit-only server continuation. The generated mission runs the pack's real initServer.sqf first. */
waitUntil {
    !isNil "Waldo_QA_fnc_assert"
    && {missionNamespace getVariable ["Waldo_QA_FullPackInitObserved", false]}
};

if (
    missionNamespace getVariable ["Waldo_QA_RunAutomation", false]
    && {(missionNamespace getVariable ["Waldo_QA_BootSuite", "all"]) in ["all", "party"]}
) then {
    private _fixture = [] execVM "partyFixtureServer.sqf";
    waitUntil {scriptDone _fixture};
};

private _range = [] execVM "featureRangeServer.sqf";
waitUntil {scriptDone _range};
private _extendedRange = [] execVM "extendedFeatureStationsServer.sqf";
waitUntil {scriptDone _extendedRange};
if (missionNamespace getVariable ["Waldo_QA_RunAutomation", false]) then {
    [] call Waldo_fnc_RunDiagnostics;
    private _diagnosticDeadline = diag_tickTime + 45;
    waitUntil {
        uiSleep 0.2;
        !((missionNamespace getVariable ["Waldo_Diagnostics_LastReport", []]) isEqualTo [])
        || {diag_tickTime >= _diagnosticDeadline}
    };
    [] execVM "runServerAudit.sqf";
} else {
    diag_log "WMP FULL AUDIT MANUAL READY: automated server cases are disabled";
};
