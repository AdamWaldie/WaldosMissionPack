/*
 * Author: WaldoTheWarfighter
 * Installs repeat-safe local addActions on the full-pack audit mission's physical feature stations.
 * Controls exercise production entry points and send authoritative mutations to the server.
 *
 * Arguments: None.
 * Return Value: Nothing; installs actions once on each interface client, including JIP.
 *
 * Example: [] execVM "extendedFeatureStationsClient.sqf";
 * Current caller: the audit mission's initPlayerLocal.sqf.
 */
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

// Server-authorised QA orientation endpoint. Vehicle transforms must execute
// where the occupied vehicle is local or the engine silently ignores them.
Waldo_QA_fnc_setDismountOrientationLocal = {
    params [["_vehicle", objNull, [objNull]], ["_mode", "OVERTURN", [""]]];
    if (remoteExecutedOwner != 2 || {isNull _vehicle} || {!local _vehicle}) exitWith {false};
    _vehicle setVelocity [0, 0, 0];
    if (toUpperANSI _mode isEqualTo "OVERTURN") then {
        private _position = getPosATL _vehicle;
        _vehicle setVectorDirAndUp [[1, 0, 0], [0, 0, -1]];
        _vehicle setPosATL [_position select 0, _position select 1, 1.8];
    };
    true
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
[_treatment, "Waldo_QA_TreatmentRolePreview", "PREVIEW GIVER + RECEIVER FEEDBACK", {
    ["RECEIVER FEEDBACK", "Patient view: treatment, medic identity and body region are delivered to the receiver's owning client.", "SUCCESS", 8, "BOTTOM_CENTER", "TREATMENT_QA_RECEIVER", "MEDICAL // RECEIVER", "REPLACE"] call Waldo_fnc_ShowUiNotification;
    ["GIVER FEEDBACK", "Medic view: optional confirmation is rendered independently on the giver's owning client.", "INFO", 8, "BOTTOM_CENTER", "TREATMENT_QA_GIVER", "MEDICAL // GIVER", "REPLACE"] call Waldo_fnc_ShowUiNotification;
}] call _add;
[_treatment, "Waldo_QA_EnableTreatmentGiver", "ENABLE ACTUAL GIVER FEEDBACK", {
    missionNamespace setVariable ["Waldo_TreatmentFeedback_NotifyMedic", true];
    ["TREATMENT QA", "Actual ACE treatment events performed by this client will now show giver feedback. Production remains patient-only by default.", "SUCCESS", "TREATMENT_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_treatment, "Waldo_QA_InjureSelf", "INJURE ME FOR RECEIVER / SELF TEST", {
    if (isClass (configFile >> "CfgPatches" >> "ace_medical")) then {
        [player] call ace_medical_treatment_fnc_fullHealLocal;
        [player, 0.35, "LeftArm", "bullet"] call ace_medical_fnc_addDamageToUnit;
        ["TREATMENT QA", "Treat your own left arm through ACE. Receiver and giver roles must de-duplicate to one bottom-centre card.", "WARNING", "TREATMENT_QA"] call Waldo_fnc_FeatureNotifyLocal;
    };
}] call _add;

private _hazard = "qa_sign_hazards" call _get;
[_hazard, "Waldo_QA_EnterHazard", "ENTER EXPOSURE LANE", {
    params ["_target", "_actor"];
    [] call Waldo_fnc_HazardInit;
    private _emitter = missionNamespace getVariable ["qa_hazard_emitter", objNull];
    if (!isNull _emitter) then {
        _actor setPosATL ((getPosATL _emitter) vectorAdd [0, -2, 0]);
        ["HAZARD QA", "Entered the object-emitter radius. Unprotected exposure must rise on the next evaluator tick.", "WARNING", "HAZARD_QA"] call Waldo_fnc_FeatureNotifyLocal;
    };
}] call _add;
[_hazard, "Waldo_QA_HazardStatus", "SHOW HAZARD RUNTIME STATUS", {
    private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
    private _exposure = (missionNamespace getVariable ["Waldo_Hazard_LocalExposure", createHashMap]) getOrDefault ["qa_hazard", 0];
    private _inside = (missionNamespace getVariable ["Waldo_Hazard_LocalInside", createHashMap]) getOrDefault ["qa_hazard", false];
    private _started = missionNamespace getVariable ["Waldo_Hazard_ClientStarted", false];
    ["HAZARD QA STATUS", format ["Evaluator: %1<br/>Registered zones: %2<br/>Inside QA emitter: %3<br/>Exposure: %4", _started, count _zones, _inside, _exposure toFixed 2], if (_started && {count _zones > 0}) then {"SUCCESS"} else {"ERROR"}, "HAZARD_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_hazard, "Waldo_QA_HazardProtect", "EQUIP QA PROTECTIVE HELMET", {
    player addHeadgear "H_PilotHelmetFighter_B";
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

private _dismount = missionNamespace getVariable ["Waldo_QA_DismountVehicle", objNull];
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
} forEach [["MILITIA", "WMP MILITIA"], ["LINE", "WMP LINE"], ["VETERAN", "WMP VETERAN"], ["ELITE", "WMP ELITE"]];
[_ai, "Waldo_QA_AI_LineNight", "APPLY WMP LINE LOW-LIGHT PROFILE", {
    ["LINE", "NIGHT"] remoteExecCall ["Waldo_QA_fnc_setAIProfileServer", 2];
}] call _add;
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
[_tactical, "Waldo_QA_ExplainTactical", "WHAT IS THE TACTICAL DISPLAY?", {
    ["TACTICAL DISPLAY", "Complete Authenticate Tactical Display on the dedicated white map board, then use Access Tactical Display. The live map shows nearby friendlies and only hostile units your group already knows about. Reveal the QA hostile to verify contact filtering.", "INFO", "TACTICAL_DISPLAY_QA"] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;
[_tactical, "Waldo_QA_ResetTactical", "RESET DISPLAY AUTHENTICATION", {
    [] remoteExecCall ["Waldo_QA_fnc_resetTacticalDisplayServer", 2];
}] call _add;
[_tactical, "Waldo_QA_RevealTactical", "REVEAL QA HOSTILE TO MY GROUP", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_revealTacticalHostileServer", 2];
}] call _add;

private _aa = "qa_sign_dynamic_aa" call _get;
[_aa, "Waldo_QA_CreateAA", "CREATE QA DYNAMIC AA SYSTEM", {
    [player] remoteExecCall ["Waldo_QA_fnc_createDynamicAAServer", 2];
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
    [player] remoteExecCall ["Waldo_QA_fnc_serviceGunshipServer", 2];
}] call _add;
[_gunship, "Waldo_QA_ReportGunship", "REPORT QA GUNSHIP STATE", {
    [player] remoteExecCall ["Waldo_QA_fnc_reportGunshipServer", 2];
}] call _add;
[_gunship, "Waldo_QA_DestroyGunship", "REMOVE QA GUNSHIP", {
    [] remoteExecCall ["Waldo_QA_fnc_destroyGunshipServer", 2];
}] call _add;

private _dynamicParadrop = "qa_sign_dynamic_paradrop" call _get;
[_dynamicParadrop, "Waldo_QA_CreateParadrop", "CREATE QA DYNAMIC PARADROP", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_createParadropServer", 2];
}] call _add;
[_dynamicParadrop, "Waldo_QA_BoardParadrop", "BOARD ME INTO QA PARADROP", {
    params ["_target", "_actor"];
    [_actor, false] remoteExecCall ["Waldo_QA_fnc_embarkParadropServer", 2];
}] call _add;
[_dynamicParadrop, "Waldo_QA_CreateParadropBoarding", "CREATE QA BOARDING POINT", {
    params ["_target", "_actor"];
    [_actor, true] remoteExecCall ["Waldo_QA_fnc_embarkParadropServer", 2];
}] call _add;
[_dynamicParadrop, "Waldo_QA_ReportParadrop", "REPORT QA PARADROP STATE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_reportParadropServer", 2];
}] call _add;
[_dynamicParadrop, "Waldo_QA_RemoveParadrop", "REMOVE QA DYNAMIC PARADROP", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_removeParadropServer", 2];
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
[_rally, "Waldo_QA_TestRallyRespawn", "TEST RALLY RESPAWN SELECTION", {
    if !((group player) getVariable ["Waldo_Rally_Active", false]) exitWith {
        ["SQUAD RALLY QA", "Deploy a squad rally first. This test will then kill the tester and open the real respawn-position menu.", "WARNING", "RALLY_QA", 8] call Waldo_fnc_FeatureNotifyLocal;
    };
    ["SQUAD RALLY QA", "Tester will be killed in two seconds. Select either Audit Base Respawn or the deployed squad rally in the respawn menu.", "WARNING", "RALLY_QA", 2] call Waldo_fnc_FeatureNotifyLocal;
    [] spawn {uiSleep 2; player setDamage 1;};
}] call _add;
[_rally, "Waldo_QA_RallyHelp", "SHOW RALLY TEST INSTRUCTIONS", {
    ["SQUAD RALLY QA", "Become squad leader, deploy through the self-action, then run TEST RALLY RESPAWN SELECTION. The menu must offer both Audit Base Respawn and the squad rally.", "INFO", "RALLY_QA", 10] call Waldo_fnc_FeatureNotifyLocal;
}] call _add;

// Realistic concurrent feature traffic verifies independent channels, stack
// compaction and right-side overflow without using the reserved TOP banner.
Waldo_QA_fnc_runNotificationStreamsLocal = {
    [] call Waldo_fnc_ClearUiPanels;
    ["Squad-rally stream opened at bottom-right.", "SUCCESS"] call Waldo_fnc_RallyPointNotifyLocal;
    ["TREATMENT UPDATE", "Medical feedback is isolated in the padded bottom-centre region.", "SUCCESS"] call Waldo_fnc_TreatmentFeedbackShowLocal;
    ["Recovery stream opened; independent logistics cards share and compact within their region.", "SUCCESS"] call Waldo_fnc_RecoveryNotifyLocal;
    ["Field resupply stream opened; it should stack with vehicle recovery at bottom-left.", "INFO", "FIELD_RESUPPLY", 12] call Waldo_fnc_FeatureNotifyLocal;
    ["AIR DEFENCE", "Combat-warning stream opened at bottom-right.", "WARNING", "DYNAMIC_AA", 8] call Waldo_fnc_FeatureNotifyLocal;
    ["TREE FELLING", "A second combat/action channel stacks beneath air defence.", "INFO", "TREE_FELLING", 12] call Waldo_fnc_FeatureNotifyLocal;
    ["Accessibility stream opened at top-right.", "INFO", "ACCESSIBILITY_PID", 8] call Waldo_fnc_FeatureNotifyLocal;
};
private _missionFlow = "qa_sign_mission_flow" call _get;
[_missionFlow, "Waldo_QA_NotificationStreams", "RUN LIVE NOTIFICATION STREAMS", {
    [] call Waldo_QA_fnc_runNotificationStreamsLocal;
}] call _add;

private _loadouts = "qa_sign_nested_loadouts" call _get;
[_loadouts, "Waldo_QA_ReportLoadouts", "REPORT NESTED PLAYABLE LOADOUT POOL", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_reportLoadoutPoolServer", 2];
}] call _add;

private _landing = "qa_sign_ai_helicopter_landing" call _get;
[_landing, "Waldo_QA_ImprovedLandingNormal", "START NORMAL AI LANDING", {
    params ["_target", "_actor"];
    [_actor, false] remoteExecCall ["Waldo_QA_fnc_startImprovedLandingServer", 2];
}] call _add;
[_landing, "Waldo_QA_ImprovedLandingHigh", "START HIGH APPROACH / GO-AROUND", {
    params ["_target", "_actor"];
    [_actor, true] remoteExecCall ["Waldo_QA_fnc_startImprovedLandingServer", 2];
}] call _add;
[_landing, "Waldo_QA_ImprovedLandingReport", "REPORT AI LANDING STATE", {
    params ["_target", "_actor"];
    [_actor] remoteExecCall ["Waldo_QA_fnc_reportImprovedLandingServer", 2];
}] call _add;
[_landing, "Waldo_QA_ImprovedLandingRemove", "REMOVE QA HELICOPTER", {
    [] remoteExecCall ["Waldo_QA_fnc_removeImprovedLandingServer", 2];
}] call _add;

private _themes = "qa_sign_ui_theme_qa" call _get;
{
    _x params ["_theme", "_label"];
    [_themes, format ["Waldo_QA_UiTheme%1", _theme], format ["APPLY %1 UI THEME", _label], {
        params ["_target", "_actor", "_theme"];
        [_actor, _theme] remoteExecCall ["Waldo_QA_fnc_setUiThemeServer", 2];
    }, _theme] call _add;
} forEach [["DEFAULT", "DEFAULT"], ["WW2", "WW2"], ["VIETNAM", "VIETNAM"], ["SCIFI", "SCI-FI"]];
[_themes, "Waldo_QA_UiThemePreview", "PREVIEW CURRENT THEME STACK", {
    [missionNamespace getVariable ["Waldo_UI_Theme", "DEFAULT"], true] call Waldo_fnc_UiThemeApplyLocal;
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
