call compile preprocessFileLineNumbers "auditBootstrap.sqf";
call compile preprocessFileLineNumbers "auditCommon.sqf";
missionNamespace setVariable ["Waldo_QA_LocalResults", []];
missionNamespace setVariable ["Waldo_QA_Suite", missionNamespace getVariable ["Waldo_QA_BootSuite", "all"]];
["BOOT", missionNamespace getVariable ["Waldo_QA_Suite", "all"], productVersion] call Waldo_QA_fnc_emit;
