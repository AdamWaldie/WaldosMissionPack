/*
 * Author: Waldo
 * Requests an ordered snapshot of network-safe runtime feature settings from the server.
 * Public variables remain useful for live updates; this handshake prevents a JIP machine from
 * activating against local defaults before the server's latest settings have arrived.
 *
 * Arguments: None
 * Return Value: Boolean - true when requested/queued
 */

if !(isServer) exitWith {
    [] remoteExecCall ["Waldo_fnc_FeatureRuntimeRequestState", 2];
    true
};

private _targetOwner = remoteExecutedOwner;
if (_targetOwner <= 2) exitWith {false};

[_targetOwner] spawn {
    params ["_targetOwner"];
    waitUntil {missionNamespace getVariable ["Waldo_FeatureRuntimeStateReady", false]};

    // Keep this list to values that Arma can reliably serialise. Mission callbacks and other Code
    // values remain mission-file configuration and are not transported in the runtime snapshot.
    private _names = [
        "Waldo_Persistence_Enable", "Waldo_Persistence_Active",
        "Waldo_Persistence_PlayerSaveInterval", "Waldo_Persistence_ObjectSaveInterval",
        "Waldo_Persistence_SaveLoadout", "Waldo_Persistence_SaveMedical",
        "Waldo_Persistence_SaveFoodWater", "Waldo_Persistence_SavePosition",
        "Waldo_Persistence_SaveRadios", "Waldo_Persistence_DatabaseName",
        "Waldo_TreatmentFeedback_Enable", "Waldo_TreatmentFeedback_ShowStart",
        "Waldo_TreatmentFeedback_ShowSuccess", "Waldo_TreatmentFeedback_ShowFailure",
        "Waldo_TreatmentFeedback_NotifyPatient", "Waldo_TreatmentFeedback_NotifyMedic",
        "Waldo_TreatmentFeedback_ShowMedicName", "Waldo_TreatmentFeedback_ShowBodyPart",
        "Waldo_TreeFelling_Enable", "Waldo_TreeFelling_Range", "Waldo_TreeFelling_BaseHits",
        "Waldo_TreeFelling_HeightFactor", "Waldo_TreeFelling_HitCooldown",
        "Waldo_TreeFelling_ClearBushes", "Waldo_TreeFelling_BushRadius",
        "Waldo_EmergencyDismount_Enable", "Waldo_EmergencyDismount_OnOverturn",
        "Waldo_EmergencyDismount_OnDestroyed", "Waldo_EmergencyDismount_PreserveVelocity",
        "Waldo_EmergencyDismount_ProtectDuringExit", "Waldo_EmergencyDismount_ProtectionSeconds",
        "Waldo_EmergencyDismount_ClearPositionRadius", "Waldo_EmergencyDismount_RequireClearExit",
        "Waldo_EmergencyDismount_UseEject", "Waldo_EmergencyDismount_RecoverUnconscious",
        "Waldo_AccessibilityPID_Enable", "Waldo_AccessibilityPID_IconRange",
        "Waldo_AccessibilityPID_NameRange", "Waldo_AccessibilityPID_RequireLOS",
        "Waldo_AccessibilityPID_IncludeAI", "Waldo_AccessibilityPID_AllowToggle",
        "Waldo_AccessibilityPID_DefaultVisible",
        "Waldo_AIRebalance_Enable", "Waldo_AIRebalance_Mode", "Waldo_AIRebalance_Profile",
        "Waldo_Hazard_Enable", "Waldo_Breaching_Enable", "Waldo_FieldResupply_Enable",
        "Waldo_Gunship_Enable", "Waldo_Gunship_PublicSystems",
        "Waldo_DynamicAA_PublicSystems"
    ];
    private _snapshot = [];
    {
        private _value = missionNamespace getVariable [_x, nil];
        if !(isNil "_value") then {_snapshot pushBack [_x, _value]};
    } forEach _names;

    [_snapshot, true] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", _targetOwner];
};
true
