/* Local controls for the physical optional-feature test stations. */
if (!hasInterface) exitWith {};
waitUntil {
    uiSleep 0.1;
    missionNamespace getVariable ["Waldo_QA_ExtendedFeatureStationsReady", false]
    && {!isNil "Waldo_QA_fnc_addAuditActionLocal"}
};
if (missionNamespace getVariable ["Waldo_QA_ExtendedFeatureStationsClientReady", false]) exitWith {};
missionNamespace setVariable ["Waldo_QA_ExtendedFeatureStationsClientReady", true];

private _get = {missionNamespace getVariable [_this, objNull]};
private _add = {
    params ["_object", "_id", "_title", "_statement", ["_arguments", []]];
    if (!isNull _object) then {[_object, _id, _title, _statement, _arguments] call Waldo_QA_fnc_addAuditActionLocal};
};

private _persistence = "qa_sign_persistence" call _get;
[_persistence, "Waldo_QA_PersistenceProbe", "CHECK INIDBI2 DEPENDENCY", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_persistenceProbeServer", 2];
}] call _add;
[_persistence, "Waldo_QA_PersistenceEnable", "ENABLE + REGISTER QA CRATE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_persistenceEnableServer", 2];
}] call _add;
[_persistence, "Waldo_QA_PersistenceSave", "PERSISTENCE: SAVE NOW", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_persistenceSaveServer", 2];
}] call _add;
[_persistence, "Waldo_QA_PersistenceMutate", "MUTATE QA CRATE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_persistenceMutateServer", 2];
}] call _add;
[_persistence, "Waldo_QA_PersistenceReload", "RELOAD SAVED QA CRATE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_persistenceReloadServer", 2];
}] call _add;

private _treatment = "qa_sign_treatment_feedback" call _get;
[_treatment, "Waldo_QA_TreatmentSupplies", "TAKE QA MEDICAL SUPPLIES", {
    {for "_i" from 1 to 4 do {player addItem _x}} forEach ["ACE_fieldDressing", "ACE_packingBandage", "ACE_tourniquet"];
    ["PATIENT TREATMENT QA", "Medical supplies added. Reset the patient, then treat the wound through ACE.", "SUCCESS", "TREATMENT_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_treatment, "Waldo_QA_InjurePatient", "RESET QA PATIENT WOUND", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_injurePatientServer", 2];
}] call _add;

private _hazard = "qa_sign_hazards" call _get;
[_hazard, "Waldo_QA_EnterHazard", "ENTER EXPOSURE LANE", {
    params ["_target", "_actor"];
    private _emitter = missionNamespace getVariable ["qa_hazard_emitter", objNull];
    if (!isNull _emitter) then {_actor setPosATL ((getPosATL _emitter) vectorAdd [0, -2, 0])};
}] call _add;
[_hazard, "Waldo_QA_HazardProtect", "EQUIP QA PROTECTIVE HELMET", {
    player addHeadgear "H_HelmetB";
    ["HAZARD QA", "QA protection equipped. Exposure multiplier should be zero in this lane.", "SUCCESS", "HAZARD_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_hazard, "Waldo_QA_HazardUnprotect", "REMOVE QA PROTECTION", {
    removeHeadgear player;
    ["HAZARD QA", "QA protection removed. Exposure should now increase inside the lane.", "INFO", "HAZARD_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_hazard, "Waldo_QA_ClearExposure", "CLEAR MY QA EXPOSURE", {
    private _exposure = missionNamespace getVariable ["Waldo_Hazard_LocalExposure", createHashMap];
    _exposure set ["qa_hazard", 0];
    missionNamespace setVariable ["Waldo_Hazard_LocalExposure", _exposure];
    ["HAZARD QA", "Local QA exposure was cleared.", "SUCCESS", "HAZARD_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;

private _tree = "qa_sign_tree_felling" call _get;
[_tree, "Waldo_QA_ResetTree", "RESET QA TREE", {
    [] remoteExecCall ["Waldo_QA_fnc_resetTreeServer", 2];
}] call _add;

private _dismount = "qa_sign_emergency_dismount" call _get;
[_dismount, "Waldo_QA_EnterDismount", "BOARD DISMOUNT TEST VEHICLE", {
    params ["_target", "_actor"];
    private _vehicle = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
    if (!isNull _vehicle) then {_actor moveInDriver _vehicle};
}] call _add;
[_dismount, "Waldo_QA_OverturnDismount", "OVERTURN VEHICLE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_overturnDismountServer", 2];
}] call _add;
[_dismount, "Waldo_QA_ResetDismount", "RESET VEHICLE UPRIGHT", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_resetDismountServer", 2];
}] call _add;

private _access = "qa_sign_accessibility" call _get;
[_access, "Waldo_QA_EnablePID", "ENABLE PID FOR THIS TESTER", {
    private _uid = getPlayerUID player;
    missionNamespace setVariable ["Waldo_AccessibilityPID_Enable", true];
    missionNamespace setVariable ["Waldo_AccessibilityPID_AllowedUIDs", if (_uid == "") then {[]} else {[_uid]}];
    missionNamespace setVariable ["Waldo_AccessibilityPID_IncludeAI", true];
    [] call Waldo_fnc_AccessibilityPIDStop;
    private _ok = [] call Waldo_fnc_AccessibilityPIDInit;
    ["ACCESSIBILITY PID", ["PID did not start for this tester.", "PID started for this tester; friendly AI markers should be visible."] select _ok, ["ERROR", "SUCCESS"] select _ok, "PID_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_access, "Waldo_QA_DenyPID", "VERIFY UID GATE DENIES", {
    [] call Waldo_fnc_AccessibilityPIDStop;
    missionNamespace setVariable ["Waldo_AccessibilityPID_AllowedUIDs", ["WMP_QA_NON_MATCHING_UID"]];
    private _started = [] call Waldo_fnc_AccessibilityPIDInit;
    ["ACCESSIBILITY UID GATE", ["Expected denial confirmed. PID remained stopped.", "UID gate failed: PID started for an ineligible tester."] select _started, ["SUCCESS", "ERROR"] select _started, "PID_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_access, "Waldo_QA_TogglePID", "TOGGLE FRIENDLY PID VISIBILITY", {
    [] call Waldo_fnc_AccessibilityPIDToggle;
}] call _add;

private _breach = "qa_sign_breaching" call _get;
[_breach, "Waldo_QA_TestBreach", "SIMULATE CONFIGURED DEMO CHARGE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_testBreachServer", 2];
}] call _add;
[_breach, "Waldo_QA_ResetBreach", "RESET BREACH WALL", {
    [] remoteExecCall ["Waldo_QA_fnc_resetBreachServer", 2];
}] call _add;

private _scale = "qa_sign_object_transforms" call _get;
{
    _x params ["_id", "_title", "_name", "_value"];
    [_scale, _id, _title, {
        params ["_target", "_actor", "_args"];
        _args remoteExecCall ["Waldo_QA_fnc_scaleFixtureServer", 2];
    }, [_name, _value]] call _add;
} forEach [
    ["Waldo_QA_ScaleHalf", "SCALE LEFT PROP TO 0.5", "qa_scale_small", 0.5],
    ["Waldo_QA_ScaleDouble", "SCALE CENTRE PROP TO 2.0", "qa_scale_source", 2]
];
[_scale, "Waldo_QA_ResetScale", "RESET ALL SCALE PROPS", {
    [] remoteExecCall ["Waldo_QA_fnc_resetScaleFixturesServer", 2];
}] call _add;
[_scale, "Waldo_QA_CopyScale", "COPY CENTRE SCALE TO RIGHT", {
    [] remoteExecCall ["Waldo_QA_fnc_copyScaleFixtureServer", 2];
}] call _add;
[_scale, "Waldo_QA_MultiplyScale", "MULTIPLY RIGHT SCALE BY 1.5", {
    [] remoteExecCall ["Waldo_QA_fnc_multiplyScaleFixtureServer", 2];
}] call _add;
[_scale, "Waldo_QA_Transform", "TRANSFORM RIGHT PROP", {
    [] remoteExecCall ["Waldo_QA_fnc_transformFixtureServer", 2];
}] call _add;
[_scale, "Waldo_QA_ReportTransforms", "REPORT TRANSFORM STATE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_reportScaleFixturesServer", 2];
}] call _add;

private _ai = "qa_sign_ai_rebalance" call _get;
{
    _x params ["_profile", "_label"];
    [_ai, format ["Waldo_QA_AI_%1", _profile], format ["APPLY %1 PROFILE", _label], {
        params ["_target", "_actor", "_profile"];
        [_profile] remoteExecCall ["Waldo_QA_fnc_setAIProfileServer", 2];
    }, _profile] call _add;
} forEach [["PUBLIC", "PUBLIC"], ["STANDARD", "STANDARD"], ["VETERAN", "VETERAN"]];
[_ai, "Waldo_QA_AI_Stop", "RESTORE ORIGINAL AI SKILLS", {
    [] remoteExecCall ["Waldo_QA_fnc_stopAIRebalanceServer", 2];
}] call _add;
[_ai, "Waldo_QA_AI_Report", "REPORT LIVE AI SKILLS", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_reportAIProfileServer", 2];
}] call _add;

private _resupply = "qa_sign_field_resupply" call _get;
[_resupply, "Waldo_QA_AssignResupply", "ASSIGN ME 2 FIELD CRATES", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_assignResupplyCarrierServer", 2];
}] call _add;

private _tactical = "qa_sign_tactical_display" call _get;
[_tactical, "Waldo_QA_RevealTactical", "REVEAL QA HOSTILE TO MY GROUP", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_revealTacticalHostileServer", 2];
}] call _add;

private _aa = "qa_sign_dynamic_aa" call _get;
[_aa, "Waldo_QA_CreateAA", "CREATE QA DYNAMIC AA SYSTEM", {
    [] remoteExecCall ["Waldo_QA_fnc_createDynamicAAServer", 2];
}] call _add;
[_aa, "Waldo_QA_SpawnAATarget", "SPAWN ABOVE-ALTITUDE WEST UAV", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_spawnDynamicAATargetServer", 2];
}] call _add;
[_aa, "Waldo_QA_RemoveAATarget", "REMOVE QA UAV", {
    [] remoteExecCall ["Waldo_QA_fnc_removeDynamicAATargetServer", 2];
}] call _add;
[_aa, "Waldo_QA_DestroyAA", "DESTROY QA DYNAMIC AA SYSTEM", {
    [] remoteExecCall ["Waldo_QA_fnc_destroyDynamicAAServer", 2];
}] call _add;

private _gunship = "qa_sign_gunship" call _get;
[_gunship, "Waldo_QA_CreateGunship", "SPAWN QA GUNSHIP", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_createGunshipServer", 2];
}] call _add;
[_gunship, "Waldo_QA_AssignGunship", "ASSIGN QA GUNSHIP TO ME", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_assignGunshipServer", 2];
}] call _add;
[_gunship, "Waldo_QA_RefreshGunship", "REFRESH MY GUNSHIP CONTROLS", {
    [] call Waldo_fnc_GunshipSetupLocal;
}] call _add;
[_gunship, "Waldo_QA_ServiceGunship", "SEND QA GUNSHIP TO SERVICE", {
    ["QA_GUNSHIP", "SERVICE", [], player] remoteExecCall ["Waldo_fnc_GunshipServerHandle", 2];
}] call _add;
[_gunship, "Waldo_QA_DestroyGunship", "REMOVE QA GUNSHIP", {
    [] remoteExecCall ["Waldo_QA_fnc_destroyGunshipServer", 2];
}] call _add;

private _workshop = "qa_sign_vehicle_recovery" call _get;
[_workshop, "Waldo_QA_ResetRecovery", "RESET RECOVERY LANE", {
    [] remoteExecCall ["Waldo_QA_fnc_resetRecoveryServer", 2];
}] call _add;

private _rally = "qa_sign_rally" call _get;
[_rally, "Waldo_QA_PrepareRally", "MAKE ME QA SQUAD LEADER", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_prepareRallyTesterServer", 2];
}] call _add;
[_rally, "Waldo_QA_ResetRally", "REMOVE ALL QA RALLY POINTS", {
    [] remoteExecCall ["Waldo_QA_fnc_resetRalliesServer", 2];
}] call _add;
[_rally, "Waldo_QA_RallyHelp", "SHOW RALLY TEST INSTRUCTIONS", {
    ["SQUAD RALLY QA", "The commander slot is squad leader. Use the self-action to deploy, regroup, pack, then repeat after the five-second cooldown.", "INFO", "RALLY_QA", 10] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;

private _loadouts = "qa_sign_nested_loadouts" call _get;
[_loadouts, "Waldo_QA_ReportLoadouts", "REPORT NESTED PLAYABLE LOADOUT POOL", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_reportLoadoutPoolServer", 2];
}] call _add;

// Add the new station destinations to the already-installed central control console.
private _control = "qa_control_console" call _get;
if (!isNull _control) then {
    {
        _x params ["_id", "_title", "_position"];
        if (_position select 0 >= 140) then {
            [_control, format ["Waldo_QA_GoToExtended_%1", _id], format ["GO TO: %1", _title], {
                params ["_target", "_actor", "_position"];
                _actor setPosATL (_position vectorAdd [0, -3, 0]);
            }, _position] call _add;
        };
    } forEach (missionNamespace getVariable ["Waldo_QA_FeatureStations", []]);
};

systemChat "WMP extended feature stations ready. New systems occupy the east test range.";
