waitUntil {!isNull player && {!isNil "Waldo_QA_fnc_assert"}};
[] execVM "runClientAudit.sqf";
if ((missionNamespace getVariable ["Waldo_QA_BootSuite", "all"]) in ["all", "party"]) then {
    [] execVM "partyPreview.sqf";
};
