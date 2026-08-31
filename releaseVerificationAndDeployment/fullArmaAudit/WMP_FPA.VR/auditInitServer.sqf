/*
 * Author: WaldoTheWarfighter
 * Continues the generated full-pack audit after the real server initialization and fixtures.
 *
 * Locality/authority: dedicated or hosted server only. Repeat/JIP behaviour: executed once by the
 * generated mission. Automated cases wait for one fully initialized interface client so focused
 * suites cannot race role assignment, diagnostics, or player-dependent authority checks.
 *
 * Arguments: None.
 * Return Value: Nothing; starts manual stations or the selected automated server audit.
 * Current callers: generated initServer.sqf after the release initServer.sqf completes.
 * Example: call compile preprocessFileLineNumbers "auditInitServer.sqf";
 */
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
    private _clientReadyDeadline = diag_tickTime + 300;
    waitUntil {
        uiSleep 0.2;
        (
            count allPlayers > 0
            && {allPlayers findIf {_x getVariable ["Waldo_QA_FeatureRangeClientReady", false]} >= 0}
        )
        || {diag_tickTime >= _clientReadyDeadline}
    };
    private _clientReady = count allPlayers > 0
        && {allPlayers findIf {_x getVariable ["Waldo_QA_FeatureRangeClientReady", false]} >= 0};
    if (!_clientReady) exitWith {
        ["audit/client-ready", false, "No initialized interface client within 300 seconds"] call Waldo_QA_fnc_assert;
        [] call Waldo_QA_fnc_complete;
    };

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
