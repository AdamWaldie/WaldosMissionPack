/* Audit-only continuation. The generated mission runs the pack's real init.sqf first. */
call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditCommon.sqf";

missionNamespace setVariable ["Waldo_QA_LocalResults", []];
missionNamespace setVariable ["Waldo_QA_Suite", missionNamespace getVariable ["Waldo_QA_BootSuite", "all"]];

private _missingPatches = (missionNamespace getVariable ["Waldo_QA_RequiredPatches", []]) select {
    !isClass (configFile >> "CfgPatches" >> _x)
};
missionNamespace setVariable ["Waldo_QA_MissingPatches", _missingPatches];
if !(_missingPatches isEqualTo []) then {
    diag_log format ["WMP FULL AUDIT FAIL: required mods were not loaded: %1", _missingPatches];
    if (hasInterface) then {
        [parseText format ["<t color='#ff6161' size='1.5'>AUDIT BLOCKED</t><br/>Required mod patches are missing:<br/>%1<br/><br/>Exit and relaunch with the correct audit mod profile.", _missingPatches joinString ", "], 60] spawn Waldo_fnc_TimedHint;
    };
};

["BOOT", missionNamespace getVariable ["Waldo_QA_Suite", "all"], productVersion] call Waldo_QA_fnc_emit;

// The pack deliberately includes a ten-second startup buffer and title presentation. Do not
// let the audit race or conceal it. Tests begin only after the real pack startup has completed.
waitUntil {
    missionNamespace getVariable ["WALDO_INIT_COMPLETE", false]
    && {!isNil "Waldo_fnc_Init3DMarkers"}
};

missionNamespace setVariable ["Waldo_QA_FullPackInitObserved", true, true];
diag_log format ["WMP FULL AUDIT STARTUP: full pack init complete at %1", diag_tickTime];

