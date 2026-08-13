/*
 * Author: WaldoTheWarfighter
 * Requests an ordered snapshot of network-safe runtime feature settings from the server.
 * Public variables remain useful for live updates; this handshake prevents a JIP machine from
 * activating against local defaults before the server's latest settings have arrived.
 *
 * Arguments: None
 * Return Value: Boolean - true when requested/queued
 *
 * Example: [] call Waldo_fnc_FeatureRuntimeRequestState;
 * Current callers: init.sqf startup handshake on clients and headless clients.
 */

if !(isServer) exitWith {
    if (missionNamespace getVariable ["Waldo_FeatureRuntimeRequestInFlight", false]) exitWith {true};
    missionNamespace setVariable ["Waldo_FeatureRuntimeRequestInFlight", true];
    missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", false];
    [] spawn {
        private _attempts = 0;
        while {
            !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false])
            && {_attempts < 15}
        } do {
            _attempts = _attempts + 1;
            [] call Waldo_fnc_FeatureRuntimeSendStateRequest;
            private _retryAt = diag_tickTime + 2;
            waitUntil {
                sleep 0.1;
                missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
                || {diag_tickTime >= _retryAt}
            };
        };
        missionNamespace setVariable ["Waldo_FeatureRuntimeRequestInFlight", false];
        if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {
            private _finalResponseDeadline = diag_tickTime + 5;
            waitUntil {
                sleep 0.1;
                missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]
                || {diag_tickTime >= _finalResponseDeadline}
            };
        };
        if !(missionNamespace getVariable ["Waldo_FeatureRuntimeSnapshotReceived", false]) then {
            missionNamespace setVariable ["Waldo_FeatureRuntimeSnapshotFailed", true];
            diag_log format ["[WMP RUNTIME] Authoritative feature snapshot failed after %1 request attempts; optional runtime features remain inactive on this machine.", _attempts];
        };
    };
    true
};

private _targetOwner = remoteExecutedOwner;
if (_targetOwner <= 2) exitWith {false};
if !(missionNamespace getVariable ["Waldo_FeatureRuntimeStateReady", false]) exitWith {false};

private _requesterIndex = allPlayers findIf {owner _x == _targetOwner};
private _requester = if (_requesterIndex >= 0) then {allPlayers select _requesterIndex} else {objNull};
if (isNull _requester) then {
    private _headlessClients = entities "HeadlessClient_F";
    private _headlessIndex = _headlessClients findIf {owner _x == _targetOwner};
    if (_headlessIndex >= 0) then {_requester = _headlessClients select _headlessIndex};
};
if (isNull _requester || {owner _requester != _targetOwner}) exitWith {false};

// Keep this list to values that Arma can reliably serialise. Mission callbacks and other Code
// values remain mission-file configuration and are not transported in the runtime snapshot.
private _names = [
        "Waldo_UI_Theme", "Waldo_UI_ThemeRevision",
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
        "Waldo_AIRebalance_Enable", "Waldo_AIRebalance_Mode", "Waldo_AIRebalance_Profile",
        "Waldo_ImprovedHelicopterLanding_Enable", "Waldo_ImprovedHelicopterLanding_MinimumActivationDistance", "Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds",
        "Waldo_ImprovedHelicopterLanding_TriggerDistance", "Waldo_ImprovedHelicopterLanding_TriggerSpeedFactor",
        "Waldo_ImprovedHelicopterLanding_TransitAltitude", "Waldo_ImprovedHelicopterLanding_GlideSlopeRatio",
        "Waldo_ImprovedHelicopterLanding_TreeScanRadius", "Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer",
        "Waldo_ImprovedHelicopterLanding_MaximumTreeHoverHeight", "Waldo_ImprovedHelicopterLanding_GoAroundTriggerDistance",
        "Waldo_ImprovedHelicopterLanding_GoAroundHeight", "Waldo_ImprovedHelicopterLanding_GoAroundExitDistance",
        "Waldo_ImprovedHelicopterLanding_GoAroundSpeed", "Waldo_ImprovedHelicopterLanding_MaximumGoArounds",
        "Waldo_ImprovedHelicopterLanding_MaximumClimbRate", "Waldo_ImprovedHelicopterLanding_MaximumDescentRate",
        "Waldo_ImprovedHelicopterLanding_TouchdownRadius", "Waldo_ImprovedHelicopterLanding_FinalCommitDistance",
        "Waldo_ImprovedHelicopterLanding_ControlInterval",
        "Waldo_Hazard_Enable", "Waldo_Breaching_Enable", "Waldo_FieldResupply_Enable",
        "Waldo_Gunship_Enable", "Waldo_Gunship_PublicSystems",
        "Waldo_DynamicAA_PublicSystems",
        "Waldo_Rally_Enable", "Waldo_Rally_ObjectClass", "Waldo_Rally_Duration", "Waldo_Rally_DeploymentTime",
        "Waldo_Rally_Cooldown", "Waldo_Rally_EnemyExclusionRadius",
        "Waldo_Rally_MinimumGroupMembers", "Waldo_Rally_PlacementDistance",
        "Waldo_Rally_MaximumSlope", "Waldo_Rally_AllowRegroup",
        "Waldo_Recovery_ScanInterval", "Waldo_Recovery_NotificationRadius", "Waldo_Recovery_CreateWorkshopMarkers",
        "Waldo_Recovery_PackageClasses"
];
private _snapshot = [];
{
    private _value = missionNamespace getVariable [_x, nil];
    if !(isNil "_value") then {_snapshot pushBack [_x, _value]};
} forEach _names;

// Revalidate immediately before dispatch so a disconnected requester's owner id cannot be reused.
if (isNull _requester || {owner _requester != _targetOwner}) exitWith {false};
[_snapshot, true] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", _targetOwner];
true
