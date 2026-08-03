/*
 * Author: WaldoTheWarfighter
 * Declares the WMP CfgFunctions catalogue and maps public Waldo_fnc_* names to their source files.
 *
 * Arguments: None; this is a configuration include rather than a runtime function.
 * Return Value: CfgFunctions declarations consumed by Arma during mission configuration loading.
 *
 * Example: #include "MissionScripts\WaldosFunctions.sqf"
 * Current caller: description.ext includes this file before mission scripts execute.
 */
class CfgFunctions
{
    class Waldo
    {
        class InitilisationAndSetup 
        {
            class LoadFeatureConfigs {
                file = "MissionScripts\MissionInit\Configuration\loadFeatureConfigs.sqf";
            };
            class CreateRuntimeId {
                file = "MissionScripts\MissionInit\Configuration\createRuntimeId.sqf";
            };
            class GetPlayerGroup {
                file = "MissionScripts\MissionInit\InitHelpers\GetPlayerGroup.sqf";
            };
            class GetPlayerRole {
                file = "MissionScripts\MissionInit\InitHelpers\GetPlayerRole.sqf";
            };
            class SetTeamColour {
                file = "MissionScripts\MissionInit\InitHelpers\SetTeamColour.sqf";
            };
        };
        class BriefDocs 
        {
            class AddDocs {
                file = "MissionScripts\MissionInit\BriefingDocuments\AddDocs.sqf";
            };
            class SPOTREP {
                file = "MissionScripts\MissionInit\BriefingDocuments\SPOTREPDoc.sqf";
            };
            class SITREP {
                file = "MissionScripts\MissionInit\BriefingDocuments\SITREPDoc.sqf";
            };
            class ACEREP {
                file = "MissionScripts\MissionInit\BriefingDocuments\LACEACEDoc.sqf";
            };
            class CALLFORFIRE {
                file = "MissionScripts\MissionInit\BriefingDocuments\CALLFORFIREDoc.sqf";
            };
            class ROTARYPICKUPREQUEST {
                file = "MissionScripts\MissionInit\BriefingDocuments\ROTARYPICKUPREQdoc.sqf";
            };
            class LZSPECS {
                file = "MissionScripts\MissionInit\BriefingDocuments\LZSPECSDoc.sqf";
            };
            class LZINSERT {
                file = "MissionScripts\MissionInit\BriefingDocuments\LZINSERTDoc.sqf";
            };
            class LZEXTRACT {
                file = "MissionScripts\MissionInit\BriefingDocuments\LZEXTRACTDoc.sqf";
            };
            class JUMPMASTER {
                file = "MissionScripts\MissionInit\BriefingDocuments\JUMPMASTERDoc.sqf";
            };
            class GENINFO {
                file = "MissionScripts\MissionInit\BriefingDocuments\GeneralInfo.sqf";
            };
            class FIVELINEGUNSHIP {
                file = "MissionScripts\MissionInit\BriefingDocuments\5LINEGUNSHIPDoc.sqf";
            };
            class LZBRIEF {
                file = "MissionScripts\MissionInit\BriefingDocuments\LZBRIEFDOC.sqf";
            };
            class CASCHECKIN {
                file = "MissionScripts\MissionInit\BriefingDocuments\CASCHECKINDOC.sqf";
            };
            class NINELINE {
                file = "MissionScripts\MissionInit\BriefingDocuments\NINELINEDoc.sqf";
            };
            class FIRECOMMANDS {
                file = "MissionScripts\MissionInit\BriefingDocuments\FireCommandsDoc.sqf";
            };
            class FIRETEAMPREPDOC {
                file = "MissionScripts\MissionInit\BriefingDocuments\FireteamPrepDoc.sqf";
            };
            class SQUADPREDOC {
                file = "MissionScripts\MissionInit\BriefingDocuments\SquadPrepDoc.sqf";
            };
        };
        class ACRE2Setup {
            class ACRE2PreInit {
                file = "MissionScripts\MissionInit\ACRE2\acre2PreInit.sqf";
                preInit = 1;
            };
            class ACRE2Init {
                file = "MissionScripts\MissionInit\ACRE2\acre2InitNew.sqf";
            };
            class ACRE2Init_Legacy {
                file = "MissionScripts\MissionInit\ACRE2\ACRE2Init.sqf";
            };
            class ACRE2SquadLevelRadios_Legacy {
                file = "MissionScripts\MissionInit\ACRE2\ACRE2SquadLevelRadios.sqf";
            };
            class GetSRChannelName_Legacy {
                file = "MissionScripts\MissionInit\ACRE2\GetSRChannelName.sqf";
            };
            class CreateACRECEOI_Legacy {
                file = "MissionScripts\MissionInit\ACRE2\CreateACRECEOI.sqf";
            };
            class BabelActivation_Legacy {
                file = "MissionScripts\MissionInit\ACRE2\BabelActivation.sqf";
            };
            class ACRE2ValidateConfig {file = "MissionScripts\MissionInit\ACRE2\acre2ValidateConfig.sqf";};
            class ACRE2GetRadioProfiles {file = "MissionScripts\MissionInit\ACRE2\acre2GetRadioProfiles.sqf";};
            class ACRE2GetOrderedRadios {file = "MissionScripts\MissionInit\ACRE2\acre2GetOrderedRadios.sqf";};
            class ACRE2ApplyPresetNames {file = "MissionScripts\MissionInit\ACRE2\acre2ApplyPresetNames.sqf";};
            class ACRE2CompilePlan {file = "MissionScripts\MissionInit\ACRE2\acre2CompilePlan.sqf";};
            class ACRE2ApplyPlayerPlan {file = "MissionScripts\MissionInit\ACRE2\acre2ApplyPlayerPlan.sqf";};
            class ACRE2BuildCEOI {file = "MissionScripts\MissionInit\ACRE2\acre2BuildCEOI.sqf";};
            class ACRE2ApplyBabel {file = "MissionScripts\MissionInit\ACRE2\acre2ApplyBabel.sqf";};
            class BabelActivation {file = "MissionScripts\MissionInit\ACRE2\acre2ApplyBabel.sqf";};
            class ACRE2FilterLoadout {file = "MissionScripts\MissionInit\ACRE2\acre2FilterLoadout.sqf";};
            class ACRE2CaptureRadioState {file = "MissionScripts\MissionInit\ACRE2\acre2CaptureRadioState.sqf";};
            class ACRE2ApplyRadioState {file = "MissionScripts\MissionInit\ACRE2\acre2ApplyRadioState.sqf";};
            class ACRE2SchedulePlayerRefresh {file = "MissionScripts\MissionInit\ACRE2\acre2SchedulePlayerRefresh.sqf";};
        };
        class AI 
        {
            class SimpleAiConvoy {
                file =  "MissionScripts\AiScripting\simpleAiConvoy.sqf";
            };
            class AITweak {
                file = "MissionScripts\AiScripting\AISkillAdjustmentSystem.sqf";
            };
            class AIRebalanceInit {
                file = "MissionScripts\AiScripting\aiRebalanceInit.sqf";
            };
            class AIApplyProfile {
                file = "MissionScripts\AiScripting\aiApplyProfile.sqf";
            };
            class AIRebalanceStop {
                file = "MissionScripts\AiScripting\aiRebalanceStop.sqf";
            };
            class ImprovedHelicopterLandingInit {file = "MissionScripts\AiScripting\improvedHelicopterLandingInit.sqf";};
            class ImprovedHelicopterLandingTrackLocal {file = "MissionScripts\AiScripting\improvedHelicopterLandingTrackLocal.sqf";};
            class ImprovedHelicopterLandingExecuteLocal {file = "MissionScripts\AiScripting\improvedHelicopterLandingExecuteLocal.sqf";};
            class ImprovedHelicopterLandingAnchorLocal {file = "MissionScripts\AiScripting\improvedHelicopterLandingAnchorLocal.sqf";};
            class ImprovedHelicopterLandingRestoreLocal {file = "MissionScripts\AiScripting\improvedHelicopterLandingRestoreLocal.sqf";};
            class ImprovedHelicopterLandingSetting {file = "MissionScripts\AiScripting\improvedHelicopterLandingSetting.sqf";};
            class ImprovedHelicopterLandingConfigureServer {file = "MissionScripts\AiScripting\improvedHelicopterLandingConfigureServer.sqf";};
        };
        class teleport
        {
            class Teleport {
                file =  "MissionScripts\Logistics\LogiHelpers\teleport.sqf";
            };
        };
        class MissionEnding
        {
            class ENDEX {
                file = "MissionScripts\MissionFlowAndUi\ENDEX.sqf";
            };
            class ENDEXReset {
                file = "MissionScripts\MissionFlowAndUi\ENDEXReset.sqf";
            };
            class AARTrack {
                file = "MissionScripts\MissionFlowAndUi\aarTrack.sqf";
            };
            class AARWound {
                file = "MissionScripts\MissionFlowAndUi\aarWound.sqf";
            };
            class SafeStart {
                file = "MissionScripts\MissionFlowAndUi\safeStart.sqf";
            };
            class SafeStartApply {
                file = "MissionScripts\MissionFlowAndUi\safeStartApply.sqf";
            };
            class SafeStartHud {
                file = "MissionScripts\MissionFlowAndUi\safeStartHud.sqf";
            };
            class SafeStartNotice {
                file = "MissionScripts\MissionFlowAndUi\safeStartNotice.sqf";
            };
            class SafeStartTimer {
                file = "MissionScripts\MissionFlowAndUi\safeStartTimer.sqf";
            };
            class SafeStartGetDiagnostics {
                file = "MissionScripts\MissionFlowAndUi\safeStartGetDiagnostics.sqf";
            };
            class ENDEXGetDiagnostics {
                file = "MissionScripts\MissionFlowAndUi\endexGetDiagnostics.sqf";
            };
            class ProtectionAcquireSafety {
                file = "MissionScripts\MissionFlowAndUi\protectionAcquireSafety.sqf";
            };
            class ProtectionReleaseSafety {
                file = "MissionScripts\MissionFlowAndUi\protectionReleaseSafety.sqf";
            };
              class CleanupTransientUi {
                  file = "MissionScripts\MissionFlowAndUi\cleanupTransientUi.sqf";
              };
              class ShowUiNotification {
                  file = "MissionScripts\MissionFlowAndUi\showUiNotification.sqf";
              };
              class UiTheme {file = "MissionScripts\MissionFlowAndUi\uiTheme.sqf";};
              class UiThemeApplyLocal {file = "MissionScripts\MissionFlowAndUi\uiThemeApplyLocal.sqf";};
              class RestyleUiNotificationsLocal {file = "MissionScripts\MissionFlowAndUi\restyleUiNotificationsLocal.sqf";};
              class UiThemeApplyDisplayLocal {file = "MissionScripts\MissionFlowAndUi\uiThemeApplyDisplayLocal.sqf";};
              class UiThemeSetServer {file = "MissionScripts\MissionFlowAndUi\uiThemeSetServer.sqf";};
              class UiThemeZen {file = "MissionScripts\MissionFlowAndUi\uiThemeZen.sqf";};
              class UiColourVisionProfile {file = "MissionScripts\MissionFlowAndUi\Accessibility\uiColourVisionProfile.sqf";};
              class UiColourVisionApplyLocal {file = "MissionScripts\MissionFlowAndUi\Accessibility\uiColourVisionApplyLocal.sqf";};
              class UiColourVisionOpenLocal {file = "MissionScripts\MissionFlowAndUi\Accessibility\uiColourVisionOpenLocal.sqf";};
              class FeatureNotifyLocal {
                  file = "MissionScripts\MissionFlowAndUi\featureNotifyLocal.sqf";
              };
              class SetUiPanelPlacement {
                  file = "MissionScripts\MissionFlowAndUi\setUiPanelPlacement.sqf";
              };
              class SetLocalUiPanelPlacement {
                  file = "MissionScripts\MissionFlowAndUi\setLocalUiPanelPlacement.sqf";
              };
              class ResolveUiPanelPlacement {
                  file = "MissionScripts\MissionFlowAndUi\resolveUiPanelPlacement.sqf";
              };
              class ReflowUiPanels {
                  file = "MissionScripts\MissionFlowAndUi\reflowUiPanels.sqf";
              };
              class RegisterUiReservationLocal {
                  file = "MissionScripts\MissionFlowAndUi\registerUiReservationLocal.sqf";
              };
              class UnregisterUiReservationLocal {
                  file = "MissionScripts\MissionFlowAndUi\unregisterUiReservationLocal.sqf";
              };
              class DrainUiNotificationQueue {
                  file = "MissionScripts\MissionFlowAndUi\drainUiNotificationQueue.sqf";
              };
              class ClearUiPanels {
                  file = "MissionScripts\MissionFlowAndUi\clearUiPanels.sqf";
              };
              class DismissUiNotification {
                  file = "MissionScripts\MissionFlowAndUi\dismissUiNotification.sqf";
              };
              class SetupUiCleanupAction {
                  file = "MissionScripts\MissionFlowAndUi\setupUiCleanupAction.sqf";
              };
              class SetUiPanelsSuppressed {
                  file = "MissionScripts\MissionFlowAndUi\setUiPanelsSuppressed.sqf";
              };
              class SetupUiAcePriority {
                  file = "MissionScripts\MissionFlowAndUi\setupUiAcePriority.sqf";
              };
            class Create3DMarker {
                file = "MissionScripts\MissionFlowAndUi\create3DMarker.sqf";
            };
            class Remove3DMarker {
                file = "MissionScripts\MissionFlowAndUi\remove3DMarker.sqf";
            };
            class Init3DMarkers {
                file = "MissionScripts\MissionFlowAndUi\init3DMarkers.sqf";
            };
        };
        class Diagnostics
        {
            class DiagnosticLog {
                file = "MissionScripts\MissionFlowAndUi\diagnosticLog.sqf";
            };
            class DiagnosticFeatureReport {
                file = "MissionScripts\MissionFlowAndUi\diagnosticFeatureReport.sqf";
            };
            class RunDiagnostics {
                file = "MissionScripts\MissionFlowAndUi\runDiagnostics.sqf";
            };
            class RunDiagnosticsClient {
                file = "MissionScripts\MissionFlowAndUi\runDiagnosticsClient.sqf";
            };
            class DiagnosticsReceiveClient {
                file = "MissionScripts\MissionFlowAndUi\diagnosticsReceiveClient.sqf";
            };
        };
        class Jamming
        {
            class JammingInit {
                file = "MissionScripts\MissionInit\Jamming\jammingInit.sqf";
            };
            class Jammer {
                file = "MissionScripts\MissionInit\Jamming\jammerCreate.sqf";
            };
            class JammerToggle {
                file = "MissionScripts\MissionInit\Jamming\jammerToggle.sqf";
            };
            class JammerRemove {
                file = "MissionScripts\MissionInit\Jamming\jammerRemove.sqf";
            };
            class JammingFactor {
                file = "MissionScripts\MissionInit\Jamming\jammingFactor.sqf";
            };
            class JammingAcreSignal {
                file = "MissionScripts\MissionInit\Jamming\jammingAcreSignal.sqf";
            };
            class JammingTfarLoop {
                file = "MissionScripts\MissionInit\Jamming\jammingTfarLoop.sqf";
            };
            class JammerInteraction {
                file = "MissionScripts\MissionInit\Jamming\jammerInteraction.sqf";
            };
            class JammerDisableServer {
                file = "MissionScripts\MissionInit\Jamming\jammerDisableServer.sqf";
            };
            class JammerScan {
                file = "MissionScripts\MissionInit\Jamming\jammerScan.sqf";
            };
            class JammerMapDraw {
                file = "MissionScripts\MissionInit\Jamming\jammerMapDraw.sqf";
            };
            class JammingHud {
                file = "MissionScripts\MissionInit\Jamming\jammingHud.sqf";
            };
            class JammingNotice {
                file = "MissionScripts\MissionInit\Jamming\jammingNotice.sqf";
            };
            class JammingUavServer {
                file = "MissionScripts\MissionInit\Jamming\jammingUavServer.sqf";
            };
            class JammingUavClient {
                file = "MissionScripts\MissionInit\Jamming\jammingUavClient.sqf";
            };
        };
        class ElectronicWarfare
        {
            class EMP {
                file = "MissionScripts\MissionInit\ElectronicWarfare\emp.sqf";
            };
            class EMPApply {
                file = "MissionScripts\MissionInit\ElectronicWarfare\empApply.sqf";
            };
            class EMPImmune {
                file = "MissionScripts\MissionInit\ElectronicWarfare\empImmune.sqf";
            };
            class Tracker {
                file = "MissionScripts\MissionInit\ElectronicWarfare\tracker.sqf";
            };
            class TrackerRemove {
                file = "MissionScripts\MissionInit\ElectronicWarfare\trackerRemove.sqf";
            };
            class TrackerRender {
                file = "MissionScripts\MissionInit\ElectronicWarfare\trackerRender.sqf";
            };
            class TrackerAttach {
                file = "MissionScripts\MissionInit\ElectronicWarfare\trackerAttach.sqf";
            };
        };
        class Tasks
        {
            class CreateObjective {
                file = "MissionScripts\MissionFlowAndUi\createObjective.sqf";
            };
            class SetObjectiveState {
                file = "MissionScripts\MissionFlowAndUi\setObjectiveState.sqf";
            };
        };
        class TitleScreeen 
        {
            class InfoText {
                file = "MissionScripts\MissionFlowAndUi\infoText.sqf";
            };
            class TimedHint {
                file = "MissionScripts\MissionFlowAndUi\timeBasedhint.sqf";
            };
            class DynamicText {
                file = "MissionScripts\MissionFlowAndUi\dynamicText.sqf";
            };
            class RespawnText {
                file = "MissionScripts\MissionFlowAndUi\respawnText.sqf";
            };
        };
        class Logistics {
            class MedicalCratePopulate {
                file = "MissionScripts\Logistics\Crates\doMedicalCrate.sqf";
            };
            class SupplyCratePopulate {
                file = "MissionScripts\Logistics\Crates\doSupplyCrate.sqf";
            };
            class SaveLoadout {
                file = "MissionScripts\Logistics\LogiHelpers\saveRespawnLoadout.sqf";
            };
            class SetupQuarterMaster {
                file = "MissionScripts\Logistics\Crates\initQuartermaster.sqf";
            };
            class LogisticsSpawner {
                file = "MissionScripts\Logistics\Crates\LogiBoxes.sqf";
            };
            class MissionSQMLookup {
                file = "MissionScripts\Logistics\LogiHelpers\missionFileLookup.sqf";
            };
            class DoStarterCrate {
                file = "MissionScripts\Logistics\Crates\doStarterCrate.sqf";
            };
            class StarterCrateSetupLocal {
                file = "MissionScripts\Logistics\Crates\starterCrateSetupLocal.sqf";
            };
            class CreateLimitedArsenal {
                file = "MissionScripts\Logistics\Crates\createLimitedAceArsenal.sqf";
            };
            class VehicleMountedWeapon {
                file = "MissionScripts\Logistics\LogiHelpers\attachedWeapon.sqf";
            };
            class MassAttachRelative {
                file = "MissionScripts\Logistics\LogiHelpers\massAttachItems.sqf";
            };
            class SideBaseLoadoutSetup {
                file = "MissionScripts\Logistics\LogiHelpers\sideBasedLoadoutSetup.sqf";
            };
            class GetSideLoadoutArray {
                file = "MissionScripts\Logistics\LogiHelpers\getSideLoadoutArray.sqf";
            };
            class UniqueLoadoutArray {
                file = "MissionScripts\Logistics\LogiHelpers\uniqueLoadoutArray.sqf";
            };
        };
        class MapStuff {
            class ReplaceMapLocationName {
                file = "MissionScripts\Logistics\LogiHelpers\replaceMapLocationName.sqf";
            };
            class CreateMapLocationName {
                file = "MissionScripts\Logistics\LogiHelpers\createNewMapLocation.sqf";
            };
        };
        class Fortify {
            class AutoFortifySetup {
                file = "MissionScripts\Logistics\Fortify\AutoFortify.sqf";
            };
        };
        class MHQ {
            class MHQSetup {
                file = "MissionScripts\Logistics\MHQ\MHQSetup.sqf";
            };
            class MHQRequestServer {
                file = "MissionScripts\Logistics\MHQ\MHQRequestServer.sqf";
            };
            class MHQSetupLocal {
                file = "MissionScripts\Logistics\MHQ\MHQSetupLocal.sqf";
            };
            class MHQPlayAudioLocal {
                file = "MissionScripts\Logistics\MHQ\MHQPlayAudioLocal.sqf";
            };
        };
        class VehicleRecovery {
            class RecoveryNotifyLocal {file = "MissionScripts\Logistics\VehicleRecovery\recoveryNotifyLocal.sqf";};
            class RecoveryRegisterWorkshop {file = "MissionScripts\Logistics\VehicleRecovery\recoveryRegisterWorkshop.sqf";};
            class RecoveryRegisterVehicle {file = "MissionScripts\Logistics\VehicleRecovery\recoveryRegisterVehicle.sqf";};
            class RecoveryRegisterCarrier {file = "MissionScripts\Logistics\VehicleRecovery\recoveryRegisterCarrier.sqf";};
            class RecoverySetupVehicleLocal {file = "MissionScripts\Logistics\VehicleRecovery\recoverySetupVehicleLocal.sqf";};
            class RecoveryInteractionSetup {file = "MissionScripts\Logistics\VehicleRecovery\recoveryInteractionSetup.sqf";};
            class RecoverySetupCarrierLocal {file = "MissionScripts\Logistics\VehicleRecovery\recoverySetupCarrierLocal.sqf";};
            class RecoverySetCargoLocal {file = "MissionScripts\Logistics\VehicleRecovery\recoverySetCargoLocal.sqf";};
            class RecoveryRequestServer {file = "MissionScripts\Logistics\VehicleRecovery\recoveryRequestServer.sqf";};
            class RecoveryResolveUnloadPosition {file = "MissionScripts\Logistics\VehicleRecovery\recoveryResolveUnloadPosition.sqf";};
            class RecoveryResolveRestorePosition {file = "MissionScripts\Logistics\VehicleRecovery\recoveryResolveRestorePosition.sqf";};
            class RecoveryRestoreServer {file = "MissionScripts\Logistics\VehicleRecovery\recoveryRestoreServer.sqf";};
            class RecoveryMonitorServer {file = "MissionScripts\Logistics\VehicleRecovery\recoveryMonitorServer.sqf";};
            class RecoverySpillVirtualPackageServer {file = "MissionScripts\Logistics\VehicleRecovery\recoverySpillVirtualPackageServer.sqf";};
        };
        class VehicleCamo {
            class VehicleCamoSetup {
                file = "MissionScripts\Logistics\VehicleCamoScript\vehicleCamo.sqf";
            };
        };
        class FieldConstruction {
            class ConstructionObjects {
                file = "MissionScripts\Logistics\Construction\ConstructionObjects.sqf";
            };
        };
        class Zen {
            class ZenInitModules {
                file = "MissionScripts\ZenModules\Zen_initModules.sqf";
            };
            class ZenMedicalSpawner {
                file = "MissionScripts\ZenModules\Zen_medicalCrateModule.sqf";
            };
            class ZenSupplySpawner {
                file = "MissionScripts\ZenModules\Zen_supplyCrateModule.sqf";
            };
            class ZenSpawnCrateServer {
                file = "MissionScripts\ZenModules\ZenSpawnCrateServer.sqf";
            };
            class FortifyBudgetModule {
                file = "MissionScripts\ZenModules\Zen_fortifyBudgetModule.sqf";
            };
            class ZenFortifyBudgetServer {
                file = "MissionScripts\ZenModules\zenFortifyBudgetServer.sqf";
            };
            class ZenConvoyModule {
                file = "MissionScripts\ZenModules\Zen_convoyModule.sqf";
            };
            class ZenLoadoutSaveModule {
                file = "MissionScripts\ZenModules\Zen_loadoutSaveModule.sqf";
            };
            class ZenAssignObjectOwnerServer {
                file = "MissionScripts\ZenModules\zenAssignObjectOwnerServer.sqf";
            };
            class ZenAddLoadoutSaveAction {
                file = "MissionScripts\ZenModules\Zen_loadoutSaveSetup.sqf";
            };
            class ZenSafeStartTimer {
                file = "MissionScripts\ZenModules\Zen_safeStartTimer.sqf";
            };
            class ZenJammerPlace {
                file = "MissionScripts\ZenModules\Zen_jammerPlaceModule.sqf";
            };
            class ZenCreateJammerServer {
                file = "MissionScripts\ZenModules\ZenCreateJammerServer.sqf";
            };
            class ZenJammerToggle {
                file = "MissionScripts\ZenModules\Zen_jammerToggleModule.sqf";
            };
            class ZenJammerRemove {
                file = "MissionScripts\ZenModules\Zen_jammerRemoveModule.sqf";
            };
            class ZenEMP {
                file = "MissionScripts\ZenModules\Zen_empModule.sqf";
            };
            class ZenEMPServer {
                file = "MissionScripts\ZenModules\zenEMPServer.sqf";
            };
            class ZenTracker {
                file = "MissionScripts\ZenModules\Zen_trackerModule.sqf";
            };
            class ZenTrackerServer {
                file = "MissionScripts\ZenModules\zenTrackerServer.sqf";
            };
        };
        class Paradrop {
            class AddHaloJump {
                file = "MissionScripts\Paradrop\addHaloJump.sqf";
            };
            class AddStaticJump {
                file = "MissionScripts\Paradrop\addStaticJump.sqf";
            };
            class ParaBackpack {
                file = "MissionScripts\Paradrop\paraBackpack.sqf";
            };
            class ParadropRestoreBackpackLocal {
                file = "MissionScripts\Paradrop\paradropRestoreBackpackLocal.sqf";
            };
            class HaloJumpFunc {
                file = "MissionScripts\Paradrop\paradropHaloJump.sqf";
            };
            class StaticJumpFunc {
                file = "MissionScripts\Paradrop\paradropStaticJump.sqf";
            };
            class paraEquipmentSim {
                file = "MissionScripts\Paradrop\paraEquipmentSim.sqf";
            };
            class VehicleJumpSetup {
                file = "MissionScripts\Paradrop\vehicleJumpSetup.sqf";
            };
            class MoveInCargoPlane {
                file = "MissionScripts\Paradrop\moveInCargoPlane.sqf";
            };
            class JumpSettingsCheck {
                file = "MissionScripts\Paradrop\checkForJumpSettings.sqf";
            };
            class ParadropCreateDropZone {
                file = "MissionScripts\Paradrop\paradropCreateDropZone.sqf";
            };
            class ParadropConfigureAircraftLocal {
                file = "MissionScripts\Paradrop\paradropConfigureAircraftLocal.sqf";
            };
            class ParadropEmbark {
                file = "MissionScripts\Paradrop\paradropEmbark.sqf";
            };
            class ParadropEmbarkLocal {
                file = "MissionScripts\Paradrop\paradropEmbarkLocal.sqf";
            };
            class ParadropRemoveDropZone {
                file = "MissionScripts\Paradrop\paradropRemoveDropZone.sqf";
            };
            class ParadropDropZoneZen {
                file = "MissionScripts\Paradrop\paradropDropZoneZen.sqf";
            };
        };
        class VehicleSetup {
            class SetupVehicleUprightLocal {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\setupVehicleUprightLocal.sqf";
            };
            class VehicleUpright {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\vehicleUpright.sqf";
            };
            class AddVehicleFunctions {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\AddVehicleFunctions.sqf";
            };
            class AddExitActions {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\AddExitAction.sqf";
            };
            class DoExitOnSide {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\DoExitOnSide.sqf";
            };
            class SetCargoAttributes {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\SetCargoAttributes.sqf";
            };
            class InitVehicles {
                file = "MissionScripts\MissionInit\VehicleActionsSetup\VehicleInit.sqf";
            };           
        };
        class VirtualVehicleDepot {
            class VVDInit {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDInit.sqf";
            };
            class VVDOpen {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDOpen.sqf";
            };
            class VVDRequestOpenServer {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDRequestOpenServer.sqf";
            };
            class VVDReleaseOpenServer {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDReleaseOpenServer.sqf";
            };
            class VVDNotifyLocal {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDNotifyLocal.sqf";
            };
            class VVDVehicleDamage {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDVehicleDamage.sqf";
            };
            class VVDPurgeVehicle {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDPurgeVehicle.sqf";
            };
        };
        class FeatureRuntimeControl
        {
            class FeatureRuntimeApply {file = "MissionScripts\ZenModules\RuntimeControl\featureRuntimeApply.sqf";};
            class FeatureRuntimeZen {file = "MissionScripts\ZenModules\RuntimeControl\featureRuntimeZen.sqf";};
            class FeatureRuntimeRequestState {file = "MissionScripts\ZenModules\RuntimeControl\featureRuntimeRequestState.sqf";};
            class FeatureRuntimeSendStateRequest {file = "MissionScripts\ZenModules\RuntimeControl\featureRuntimeSendStateRequest.sqf";};
            class FeatureRuntimeReceiveState {file = "MissionScripts\ZenModules\RuntimeControl\featureRuntimeReceiveState.sqf";};
        };
        class TreatmentFeedback
        {
            class TreatmentFeedbackInit {file = "MissionScripts\MedicalSystems\TreatmentFeedback\treatmentFeedbackInit.sqf";};
            class TreatmentFeedbackNotify {file = "MissionScripts\MedicalSystems\TreatmentFeedback\treatmentFeedbackNotify.sqf";};
            class TreatmentFeedbackShowLocal {file = "MissionScripts\MedicalSystems\TreatmentFeedback\treatmentFeedbackShowLocal.sqf";};
            class TreatmentFeedbackStop {file = "MissionScripts\MedicalSystems\TreatmentFeedback\treatmentFeedbackStop.sqf";};
        };
        class FieldResupply
        {
            class FieldResupplyInit {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyInit.sqf";};
            class FieldResupplySetupHubLocal {file = "MissionScripts\Logistics\FieldResupply\fieldResupplySetupHubLocal.sqf";};
            class FieldResupplySetupCrateLocal {file = "MissionScripts\Logistics\FieldResupply\fieldResupplySetupCrateLocal.sqf";};
            class FieldResupplyReceiveAmmo {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyReceiveAmmo.sqf";};
            class FieldResupplyRegisterHub {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyRegisterHub.sqf";};
            class FieldResupplyAssignCarrier {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyAssignCarrier.sqf";};
            class FieldResupplyGrantCrates {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyGrantCrates.sqf";};
            class FieldResupplyNotifyGrantLocal {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyNotifyGrantLocal.sqf";};
            class FieldResupplyServerHandle {file = "MissionScripts\Logistics\FieldResupply\fieldResupplyServerHandle.sqf";};
        };
        class RallyPoint
        {
            class RallyPointNotifyLocal {file = "MissionScripts\Respawn\RallyPoint\rallyPointNotifyLocal.sqf";};
            class RallyPointInit {file = "MissionScripts\Respawn\RallyPoint\rallyPointInit.sqf";};
            class RallyPointStop {file = "MissionScripts\Respawn\RallyPoint\rallyPointStop.sqf";};
            class RallyPointSetupLocal {file = "MissionScripts\Respawn\RallyPoint\rallyPointSetupLocal.sqf";};
            class RallyPointRequestServer {file = "MissionScripts\Respawn\RallyPoint\rallyPointRequestServer.sqf";};
            class RallyPointRemoveServer {file = "MissionScripts\Respawn\RallyPoint\rallyPointRemoveServer.sqf";};
            class RallyPointRemoveAllServer {file = "MissionScripts\Respawn\RallyPoint\rallyPointRemoveAllServer.sqf";};
            class RallyPointResolveSafePosition {file = "MissionScripts\Respawn\RallyPoint\rallyPointResolveSafePosition.sqf";};
            class RallyPointMoveLocal {file = "MissionScripts\Respawn\RallyPoint\rallyPointMoveLocal.sqf";};
            class RallyPointMarkerLocal {file = "MissionScripts\Respawn\RallyPoint\rallyPointMarkerLocal.sqf";};
        };
        class TacticalDisplay
        {
            class TacticalDisplayRegister {file = "MissionScripts\MissionFlowAndUi\TacticalDisplay\tacticalDisplayRegister.sqf";};
            class TacticalDisplaySetupLocal {file = "MissionScripts\MissionFlowAndUi\TacticalDisplay\tacticalDisplaySetupLocal.sqf";};
            class TacticalDisplayInteractionSetup {file = "MissionScripts\MissionFlowAndUi\TacticalDisplay\tacticalDisplayInteractionSetup.sqf";};
            class TacticalDisplayOpenLocal {file = "MissionScripts\MissionFlowAndUi\TacticalDisplay\tacticalDisplayOpenLocal.sqf";};
        };
        class AirborneGunship
        {
            class GunshipRegister {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipRegister.sqf";};
            class GunshipPublishState {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipPublishState.sqf";};
            class GunshipSetState {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipSetState.sqf";};
            class GunshipNotifyLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipNotifyLocal.sqf";};
            class GunshipSetOrbit {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipSetOrbit.sqf";};
            class GunshipApplyOrbitLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipApplyOrbitLocal.sqf";};
            class GunshipMonitor {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipMonitor.sqf";};
            class GunshipServiceAircraft {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipServiceAircraft.sqf";};
            class GunshipServerHandle {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipServerHandle.sqf";};
            class GunshipDestroy {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipDestroy.sqf";};
            class GunshipStop {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipStop.sqf";};
            class GunshipSelectOrbitLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipSelectOrbitLocal.sqf";};
            class GunshipGrantControlLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipGrantControlLocal.sqf";};
            class GunshipReleaseControlLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipReleaseControlLocal.sqf";};
            class GunshipSetupLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipSetupLocal.sqf";};
            class GunshipUpdateMarkersLocal {file = "MissionScripts\CombatSystems\AirborneGunship\gunshipUpdateMarkersLocal.sqf";};
        };
        class Persistence
        {
            class PersistenceDependencyAvailable {file = "MissionScripts\Persistence\persistenceDependencyAvailable.sqf";};
            class PersistenceInit {file = "MissionScripts\Persistence\persistenceInit.sqf";};
            class PersistenceClientCapture {file = "MissionScripts\Persistence\persistenceClientCapture.sqf";};
            class PersistenceClientApply {file = "MissionScripts\Persistence\persistenceClientApply.sqf";};
            class PersistenceServerHandle {file = "MissionScripts\Persistence\persistenceServerHandle.sqf";};
            class PersistenceRegisterObject {file = "MissionScripts\Persistence\persistenceRegisterObject.sqf";};
            class PersistenceSaveObject {file = "MissionScripts\Persistence\persistenceSaveObject.sqf";};
            class PersistenceLoadObject {file = "MissionScripts\Persistence\persistenceLoadObject.sqf";};
            class PersistenceSavePlayerLocal {file = "MissionScripts\Persistence\persistenceSavePlayerLocal.sqf";};
            class PersistenceSaveNow {file = "MissionScripts\Persistence\persistenceSaveNow.sqf";};
            class PersistenceStop {file = "MissionScripts\Persistence\persistenceStop.sqf";};
        };
        class HazardousEnvironments
        {
            class HazardRegisterZone {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardRegisterZone.sqf";};
            class HazardRegisterPresetZone {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardRegisterPresetZone.sqf";};
            class HazardRegisterEmitter {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardRegisterEmitter.sqf";};
            class HazardUnregisterZone {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardUnregisterZone.sqf";};
            class HazardProtectionFactor {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardProtectionFactor.sqf";};
            class HazardTick {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardTick.sqf";};
            class HazardInit {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardInit.sqf";};
            class HazardStop {file = "MissionScripts\EnvironmentalSystems\HazardousEnvironments\hazardStop.sqf";};
        };
        class TreeFelling
        {
            class TreeFellingInit {file = "MissionScripts\EnvironmentalSystems\TreeFelling\treeFellingInit.sqf";};
            class TreeFellingSwing {file = "MissionScripts\EnvironmentalSystems\TreeFelling\treeFellingSwing.sqf";};
            class TreeFellingProcess {file = "MissionScripts\EnvironmentalSystems\TreeFelling\treeFellingProcess.sqf";};
            class TreeFellingStop {file = "MissionScripts\EnvironmentalSystems\TreeFelling\treeFellingStop.sqf";};
        };
        class EmergencyDismount
        {
            class EmergencyDismountInit {file = "MissionScripts\MissionInit\VehicleActionsSetup\EmergencyDismount\emergencyDismountInit.sqf";};
            class EmergencyDismountExecute {file = "MissionScripts\MissionInit\VehicleActionsSetup\EmergencyDismount\emergencyDismountExecute.sqf";};
            class EmergencyDismountStop {file = "MissionScripts\MissionInit\VehicleActionsSetup\EmergencyDismount\emergencyDismountStop.sqf";};
        };
        class Accessibility
        {
            class AccessibilitySelfInteractionInit {file = "MissionScripts\MissionFlowAndUi\Accessibility\accessibilitySelfInteractionInit.sqf";};
            class AccessibilityPIDInit {file = "MissionScripts\MissionFlowAndUi\Accessibility\accessibilityPIDInit.sqf";};
            class AccessibilityPIDToggle {file = "MissionScripts\MissionFlowAndUi\Accessibility\accessibilityPIDToggle.sqf";};
            class AccessibilityPIDStop {file = "MissionScripts\MissionFlowAndUi\Accessibility\accessibilityPIDStop.sqf";};
        };
        class Breaching
        {
            class BreachingInit {file = "MissionScripts\CombatSystems\Breaching\breachingInit.sqf";};
            class BreachingSpawnRelative {file = "MissionScripts\CombatSystems\Breaching\breachingSpawnRelative.sqf";};
            class BreachingServerHandle {file = "MissionScripts\CombatSystems\Breaching\breachingServerHandle.sqf";};
            class BreachingReset {file = "MissionScripts\CombatSystems\Breaching\breachingReset.sqf";};
            class BreachingStop {file = "MissionScripts\CombatSystems\Breaching\breachingStop.sqf";};
        };
        class ObjectScaling
        {
            class ObjectScale {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScale.sqf";};
            class ObjectScaleTagged {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScaleTagged.sqf";};
            class ObjectScaleReset {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScaleReset.sqf";};
            class ObjectScaleMultiply {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScaleMultiply.sqf";};
            class ObjectScaleCopy {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScaleCopy.sqf";};
            class ObjectScaleArea {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScaleArea.sqf";};
            class ObjectTransformSet {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectTransformSet.sqf";};
            class ObjectTransformSpawn {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectTransformSpawn.sqf";};
            class ObjectScaleZen {file = "MissionScripts\MissionMakerResourceScripts\ObjectTransforms\objectScaleZen.sqf";};
        };
        class DynamicAA
        {
            class DynamicAAResolveAssetPool {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAAResolveAssetPool.sqf";};
            class DynamicAASetGroupState {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAASetGroupState.sqf";};
            class DynamicAASetVehicleAmmo {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAASetVehicleAmmo.sqf";};
            class DynamicAAPublishState {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAAPublishState.sqf";};
            class DynamicAACreate {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAACreate.sqf";};
            class DynamicAADetectorLoop {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAADetectorLoop.sqf";};
            class DynamicAANotifyState {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAANotifyState.sqf";};
            class DynamicAASpawnFighters {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAASpawnFighters.sqf";};
            class DynamicAADestroy {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAADestroy.sqf";};
            class DynamicAAZen {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAAZen.sqf";};
            class DynamicAAZenPlacement {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAAZenPlacement.sqf";};
            class DynamicAAInteractionSetup {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAAInteractionSetup.sqf";};
            class DynamicAARemoveZen {file = "MissionScripts\CombatSystems\DynamicAA\dynamicAARemoveZen.sqf";};
        };
        class DynamicAO
        {
            class DynamicAOGetFactions {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAOGetFactions.sqf";};
            class DynamicAOResolvePools {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAOResolvePools.sqf";};
            class DynamicAOAddPatrolWaypoints {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAOAddPatrolWaypoints.sqf";};
            class DynamicAOPublishState {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAOPublishState.sqf";};
            class DynamicAOCreate {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAOCreate.sqf";};
            class DynamicAODestroyMinefield {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAODestroyMinefield.sqf";};
            class DynamicAODestroy {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAODestroy.sqf";};
            class DynamicAOZen {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAOZen.sqf";};
            class DynamicAORemoveZen {file = "MissionScripts\CombatSystems\DynamicAO\dynamicAORemoveZen.sqf";};
        };
        class EcoCore
        {
            class EcoInit {
                file = "MissionScripts\EconomySystems\economyInit.sqf";
            };
            class EcoCore_applyMakerConfig {
                file = "MissionScripts\EconomySystems\Core\applyMakerConfig.sqf";
            };
            class EcoCore_registerZenModules {
                file = "MissionScripts\EconomySystems\Core\registerZenModules.sqf";
            };
            class EcoCore_zenServerRequest {
                file = "MissionScripts\EconomySystems\Core\zenServerRequest.sqf";
            };
            class EcoCore_logZenModule {
                file = "MissionScripts\EconomySystems\Core\logZenModule.sqf";
            };
            class EcoCore_zenModuleGuard {
                file = "MissionScripts\EconomySystems\Core\zenModuleGuard.sqf";
            };
            class EcoCore_zenPlacementPos {
                file = "MissionScripts\EconomySystems\Core\zenPlacementPos.sqf";
            };
            class EcoCore_isActive {
                file = "MissionScripts\EconomySystems\Core\isActive.sqf";
            };
            class EcoCore_getDiagnostics {
                file = "MissionScripts\EconomySystems\Core\getDiagnostics.sqf";
            };
            class EcoCore_notifyActor {
                file = "MissionScripts\EconomySystems\Core\notifyActor.sqf";
            };
            class EcoCore_notifyActorLocal {
                file = "MissionScripts\EconomySystems\Core\notifyActorLocal.sqf";
            };
            class EcoMakerSetup {
                file = "MissionConfig\economyConfig.sqf";
            };
            class EcoCore_canRunAuthority {
                file = "MissionScripts\EconomySystems\Core\canRunAuthority.sqf";
            };
            class EcoCore_getActivePlayerUnit {
                file = "MissionScripts\EconomySystems\Core\getActivePlayerUnit.sqf";
            };
            class EcoCore_canRunBackgroundAuthority {
                file = "MissionScripts\EconomySystems\Core\canRunBackgroundAuthority.sqf";
            };
            class EcoCore_isModuleActive {
                file = "MissionScripts\EconomySystems\Core\isModuleActive.sqf";
            };
            class EcoCore_isCommitmentModeEnabled {
                file = "MissionScripts\EconomySystems\Core\isCommitmentModeEnabled.sqf";
            };
            class EcoCore_isTestingNoticeEnabled {
                file = "MissionScripts\EconomySystems\Core\isTestingNoticeEnabled.sqf";
            };
            class EcoCore_setCommitmentModeEnabled {
                file = "MissionScripts\EconomySystems\Core\setCommitmentModeEnabled.sqf";
            };
            class EcoCore_toggleCommitmentMode {
                file = "MissionScripts\EconomySystems\Core\toggleCommitmentMode.sqf";
            };
            class EcoCore_setTestingNoticeEnabled {
                file = "MissionScripts\EconomySystems\Core\setTestingNoticeEnabled.sqf";
            };
            class EcoCore_toggleTestingNotice {
                file = "MissionScripts\EconomySystems\Core\toggleTestingNotice.sqf";
            };
            class EcoCore_getTestingNoticeActionArgs {
                file = "MissionScripts\EconomySystems\Core\getTestingNoticeActionArgs.sqf";
            };
            class EcoCore_startTestingNoticePlayerBridge {
                file = "MissionScripts\EconomySystems\Core\startTestingNoticePlayerBridge.sqf";
            };
            class EcoCore_trimString {
                file = "MissionScripts\EconomySystems\Core\trimString.sqf";
            };
            class EcoCore_registerCuratorEditableObjects {
                file = "MissionScripts\EconomySystems\Core\registerCuratorEditableObjects.sqf";
            };
            class EcoCore_registerRuntimeObject {
                file = "MissionScripts\EconomySystems\Core\registerRuntimeObject.sqf";
            };
            class EcoCore_unregisterRuntimeObject {
                file = "MissionScripts\EconomySystems\Core\unregisterRuntimeObject.sqf";
            };
            class EcoCore_getRuntimeObjects {
                file = "MissionScripts\EconomySystems\Core\getRuntimeObjects.sqf";
            };
            class EcoCore_refreshRuntimeRegistries {
                file = "MissionScripts\EconomySystems\Core\refreshRuntimeRegistries.sqf";
            };
            class EcoCore_startRequestScheduler {
                file = "MissionScripts\EconomySystems\Core\startRequestScheduler.sqf";
            };
            class EcoCore_ensureLocalObjectAction {
                file = "MissionScripts\EconomySystems\Core\ensureLocalObjectAction.sqf";
            };
            class EcoCore_getPubZeusActionJipId {
                file = "MissionScripts\EconomySystems\Core\getPubZeusActionJipId.sqf";
            };
            class EcoCore_clearPubZeusObjectAction {
                file = "MissionScripts\EconomySystems\Core\clearPubZeusObjectAction.sqf";
            };
            class EcoCore_publishPubZeusObjectAction {
                file = "MissionScripts\EconomySystems\Core\publishPubZeusObjectAction.sqf";
            };
            class EcoCore_normalizeNameValueRows {
                file = "MissionScripts\EconomySystems\Core\normalizeNameValueRows.sqf";
            };
            class EcoCore_normalizeNameList {
                file = "MissionScripts\EconomySystems\Core\normalizeNameList.sqf";
            };
            class EcoCore_parseNameValueText {
                file = "MissionScripts\EconomySystems\Core\parseNameValueText.sqf";
            };
            class EcoCore_parseNameListText {
                file = "MissionScripts\EconomySystems\Core\parseNameListText.sqf";
            };
            class EcoCore_formatNameValueText {
                file = "MissionScripts\EconomySystems\Core\formatNameValueText.sqf";
            };
            class EcoCore_formatNameListText {
                file = "MissionScripts\EconomySystems\Core\formatNameListText.sqf";
            };
            class EcoCore_getDisplayById {
                file = "MissionScripts\EconomySystems\Core\getDisplayById.sqf";
            };
            class EcoCore_getZeusDisplay {
                file = "MissionScripts\EconomySystems\Core\getZeusDisplay.sqf";
            };
            class EcoCore_getMainDisplay {
                file = "MissionScripts\EconomySystems\Core\getMainDisplay.sqf";
            };
            class EcoCore_closePromptDisplayIfDedicated {
                file = "MissionScripts\EconomySystems\Core\closePromptDisplayIfDedicated.sqf";
            };
            class EcoCore_createZeusPromptDisplay {
                file = "MissionScripts\EconomySystems\Core\createZeusPromptDisplay.sqf";
            };
            class EcoCore_fitPromptDisplay {
                file = "MissionScripts\EconomySystems\Core\fitPromptDisplay.sqf";
            };
            class EcoCore_findTreeRootIndex {
                file = "MissionScripts\EconomySystems\Core\findTreeRootIndex.sqf";
            };
            class EcoCore_findTreeChildIndex {
                file = "MissionScripts\EconomySystems\Core\findTreeChildIndex.sqf";
            };
            class EcoCore_stopZeusPlacementSession {
                file = "MissionScripts\EconomySystems\Core\stopZeusPlacementSession.sqf";
            };
            class EcoCore_findMarkerIconIndex {
                file = "MissionScripts\EconomySystems\Core\findMarkerIconIndex.sqf";
            };
            class EcoCore_refreshMarkerIconSelector {
                file = "MissionScripts\EconomySystems\Core\refreshMarkerIconSelector.sqf";
            };
            class EcoCore_cycleMarkerIconSelector {
                file = "MissionScripts\EconomySystems\Core\cycleMarkerIconSelector.sqf";
            };
            class EcoCore_setPromptInputTargets {
                file = "MissionScripts\EconomySystems\Core\setPromptInputTargets.sqf";
            };
            class EcoCore_resetPromptInputTargets {
                file = "MissionScripts\EconomySystems\Core\resetPromptInputTargets.sqf";
            };
            class EcoCore_deleteDisplayControlsByVars {
                file = "MissionScripts\EconomySystems\Core\deleteDisplayControlsByVars.sqf";
            };
            class EcoCore_clearDisplayVariables {
                file = "MissionScripts\EconomySystems\Core\clearDisplayVariables.sqf";
            };
            class EcoCore_installPromptInputGuard {
                file = "MissionScripts\EconomySystems\Core\installPromptInputGuard.sqf";
            };
            class EcoCore_cleanupUnifiedSaveContext {
                file = "MissionScripts\EconomySystems\Core\cleanupUnifiedSaveContext.sqf";
            };
            class EcoCore_cleanupUnifiedSavePrompt {
                file = "MissionScripts\EconomySystems\Core\cleanupUnifiedSavePrompt.sqf";
            };
            class EcoCore_cleanupUnifiedPurgePrompt {
                file = "MissionScripts\EconomySystems\Core\cleanupUnifiedPurgePrompt.sqf";
            };
            class EcoCore_cleanupUnifiedPresetPrompt {
                file = "MissionScripts\EconomySystems\Core\cleanupUnifiedPresetPrompt.sqf";
            };
            class EcoCore_getPresetComplexityChoices {
                file = "MissionScripts\EconomySystems\Core\getPresetComplexityChoices.sqf";
            };
            class EcoCore_getPresetCatalogChoices {
                file = "MissionScripts\EconomySystems\Core\getPresetCatalogChoices.sqf";
            };
            class EcoCore_getPresetLibrary {
                file = "MissionScripts\EconomySystems\Core\getPresetLibrary.sqf";
            };
            class EcoCore_getPresetAssignmentVar {
                file = "MissionScripts\EconomySystems\Core\getPresetAssignmentVar.sqf";
            };
            class EcoCore_getPresetAssignment {
                file = "MissionScripts\EconomySystems\Core\getPresetAssignment.sqf";
            };
            class EcoCore_getPresetGenericComplexity {
                file = "MissionScripts\EconomySystems\Core\getPresetGenericComplexity.sqf";
            };
            class EcoCore_setPresetAssignment {
                file = "MissionScripts\EconomySystems\Core\setPresetAssignment.sqf";
            };
            class EcoCore_setPresetGenericComplexity {
                file = "MissionScripts\EconomySystems\Core\setPresetGenericComplexity.sqf";
            };
            class EcoCore_clearPresetAssignments {
                file = "MissionScripts\EconomySystems\Core\clearPresetAssignments.sqf";
            };
            class EcoCore_getPresetLibraryEntry {
                file = "MissionScripts\EconomySystems\Core\getPresetLibraryEntry.sqf";
            };
            class EcoCore_populatePresetCombo {
                file = "MissionScripts\EconomySystems\Core\populatePresetCombo.sqf";
            };
            class EcoCore_getPresetComboSelection {
                file = "MissionScripts\EconomySystems\Core\getPresetComboSelection.sqf";
            };
            class EcoCore_getPresetPurchaseSideName {
                file = "MissionScripts\EconomySystems\Core\getPresetPurchaseSideName.sqf";
            };
            class EcoCore_mergeNamedEntryCatalogs {
                file = "MissionScripts\EconomySystems\Core\mergeNamedEntryCatalogs.sqf";
            };
            class EcoCore_importUnifiedResourcesAdditive {
                file = "MissionScripts\EconomySystems\Core\importUnifiedResourcesAdditive.sqf";
            };
            class EcoCore_importUnifiedResearchAdditive {
                file = "MissionScripts\EconomySystems\Core\importUnifiedResearchAdditive.sqf";
            };
            class EcoCore_importUnifiedBuildingsAdditive {
                file = "MissionScripts\EconomySystems\Core\importUnifiedBuildingsAdditive.sqf";
            };
            class EcoCore_importUnifiedPurchasesAdditive {
                file = "MissionScripts\EconomySystems\Core\importUnifiedPurchasesAdditive.sqf";
            };
            class EcoCore_preparePresetPayloadForSide {
                file = "MissionScripts\EconomySystems\Core\preparePresetPayloadForSide.sqf";
            };
            class EcoCore_applyPresetSelections {
                file = "MissionScripts\EconomySystems\Core\applyPresetSelections.sqf";
            };
            class EcoCore_setUnifiedPurgeSectionChecked {
                file = "MissionScripts\EconomySystems\Core\setUnifiedPurgeSectionChecked.sqf";
            };
            class EcoCore_hasUnifiedPurgeSelection {
                file = "MissionScripts\EconomySystems\Core\hasUnifiedPurgeSelection.sqf";
            };
            class EcoCore_refreshUnifiedPurgePrompt {
                file = "MissionScripts\EconomySystems\Core\refreshUnifiedPurgePrompt.sqf";
            };
            class EcoCore_collectKnownModuleImportPayloads {
                file = "MissionScripts\EconomySystems\Core\collectKnownModuleImportPayloads.sqf";
            };
            class EcoCore_buildUnifiedSaveExportPayload {
                file = "MissionScripts\EconomySystems\Core\buildUnifiedSaveExportPayload.sqf";
            };
            class EcoCore_buildMissionSetupScript {
                file = "MissionScripts\EconomySystems\Core\buildMissionSetupScript.sqf";
            };
            class EcoCore_importUnifiedSavePayload {
                file = "MissionScripts\EconomySystems\Core\importUnifiedSavePayload.sqf";
            };
            class EcoCore_deleteAllTrackedMarkers {
                file = "MissionScripts\EconomySystems\Core\deleteAllTrackedMarkers.sqf";
            };
            class EcoCore_purgeResourceConfiguration {
                file = "MissionScripts\EconomySystems\Core\purgeResourceConfiguration.sqf";
            };
            class EcoCore_purgeResearchConfiguration {
                file = "MissionScripts\EconomySystems\Core\purgeResearchConfiguration.sqf";
            };
            class EcoCore_purgeBuildConfiguration {
                file = "MissionScripts\EconomySystems\Core\purgeBuildConfiguration.sqf";
            };
            class EcoCore_purgePurchaseConfiguration {
                file = "MissionScripts\EconomySystems\Core\purgePurchaseConfiguration.sqf";
            };
            class EcoCore_purgeSideResourceValues {
                file = "MissionScripts\EconomySystems\Core\purgeSideResourceValues.sqf";
            };
            class EcoCore_purgeGroundCommandValues {
                file = "MissionScripts\EconomySystems\Core\purgeGroundCommandValues.sqf";
            };
            class EcoCore_purgeResearchRuntimeValues {
                file = "MissionScripts\EconomySystems\Core\purgeResearchRuntimeValues.sqf";
            };
            class EcoCore_purgeResourceContainers {
                file = "MissionScripts\EconomySystems\Core\purgeResourceContainers.sqf";
            };
            class EcoCore_purgeResourceZones {
                file = "MissionScripts\EconomySystems\Core\purgeResourceZones.sqf";
            };
            class EcoCore_purgeBuildingValues {
                file = "MissionScripts\EconomySystems\Core\purgeBuildingValues.sqf";
            };
            class EcoCore_removeUnifiedPlayerActionsLocal {
                file = "MissionScripts\EconomySystems\Core\removeUnifiedPlayerActionsLocal.sqf";
            };
            class EcoCore_cleanupUnifiedClientLocal {
                file = "MissionScripts\EconomySystems\Core\cleanupUnifiedClientLocal.sqf";
            };
            class EcoCore_broadcastUnifiedClientCleanup {
                file = "MissionScripts\EconomySystems\Core\broadcastUnifiedClientCleanup.sqf";
            };
            class EcoCore_executeUnifiedPurge {
                file = "MissionScripts\EconomySystems\Core\executeUnifiedPurge.sqf";
            };
            class EcoCore_purgeEconomySystems {
                file = "MissionScripts\EconomySystems\Core\purgeEconomySystems.sqf";
            };
            class EcoCore_promptUnifiedSaveSystem {
                file = "MissionScripts\EconomySystems\Core\promptUnifiedSaveSystem.sqf";
            };
            class EcoCore_promptUnifiedPresetSystem {
                file = "MissionScripts\EconomySystems\Core\promptUnifiedPresetSystem.sqf";
            };
            class EcoCore_promptUnifiedPurgeSystem {
                file = "MissionScripts\EconomySystems\Core\promptUnifiedPurgeSystem.sqf";
            };
        };
        class EcoResource
        {
            class EcoResource_getSideStorageVar {
                file = "MissionScripts\EconomySystems\Resource\getSideStorageVar.sqf";
            };
            class EcoResource_getSideKeyFromSide {
                file = "MissionScripts\EconomySystems\Resource\getSideKeyFromSide.sqf";
            };
            class EcoResource_getDefaultResourceColor {
                file = "MissionScripts\EconomySystems\Resource\getDefaultResourceColor.sqf";
            };
            class EcoResource_getFallbackResourceMarkerClass {
                file = "MissionScripts\EconomySystems\Resource\getFallbackResourceMarkerClass.sqf";
            };
            class EcoResource_getFallbackResourceIcon {
                file = "MissionScripts\EconomySystems\Resource\getFallbackResourceIcon.sqf";
            };
            class EcoResource_getDefaultResourceIcon {
                file = "MissionScripts\EconomySystems\Resource\getDefaultResourceIcon.sqf";
            };
            class EcoResource_getMarkerClassForIconPath {
                file = "MissionScripts\EconomySystems\Resource\getMarkerClassForIconPath.sqf";
            };
            class EcoResource_getRenderableResourceIcon {
                file = "MissionScripts\EconomySystems\Resource\getRenderableResourceIcon.sqf";
            };
            class EcoResource_getResourceCatalog {
                file = "MissionScripts\EconomySystems\Resource\getResourceCatalog.sqf";
            };
            class EcoResource_getResourceTypes {
                file = "MissionScripts\EconomySystems\Resource\getResourceTypes.sqf";
            };
            class EcoResource_getMarkerIconChoices {
                file = "MissionScripts\EconomySystems\Resource\getMarkerIconChoices.sqf";
            };
            class EcoResource_getResourceDefinition {
                file = "MissionScripts\EconomySystems\Resource\getResourceDefinition.sqf";
            };
            class EcoResource_getResourceBaseStorage {
                file = "MissionScripts\EconomySystems\Resource\getResourceBaseStorage.sqf";
            };
            class EcoResource_getResourceMarkerClass {
                file = "MissionScripts\EconomySystems\Resource\getResourceMarkerClass.sqf";
            };
            class EcoResource_getNearestMarkerColor {
                file = "MissionScripts\EconomySystems\Resource\getNearestMarkerColor.sqf";
            };
            class EcoResource_getZoneOwnerLabel {
                file = "MissionScripts\EconomySystems\Resource\getZoneOwnerLabel.sqf";
            };
            class EcoResource_getResourceZones {
                file = "MissionScripts\EconomySystems\Resource\getResourceZones.sqf";
            };
            class EcoResource_setResourceZones {
                file = "MissionScripts\EconomySystems\Resource\setResourceZones.sqf";
            };
            class EcoResource_findResourceZoneIndex {
                file = "MissionScripts\EconomySystems\Resource\findResourceZoneIndex.sqf";
            };
            class EcoResource_getZoneAtPos {
                file = "MissionScripts\EconomySystems\Resource\getZoneAtPos.sqf";
            };
            class EcoResource_getCurrentZoneForUnit {
                file = "MissionScripts\EconomySystems\Resource\getCurrentZoneForUnit.sqf";
            };
            class EcoResource_canUnitCaptureCurrentZone {
                file = "MissionScripts\EconomySystems\Resource\canUnitCaptureCurrentZone.sqf";
            };
            class EcoResource_captureCurrentZoneForUnit {
                file = "MissionScripts\EconomySystems\Resource\captureCurrentZoneForUnit.sqf";
            };
            class EcoResource_canUnitViewCurrentZone {
                file = "MissionScripts\EconomySystems\Resource\canUnitViewCurrentZone.sqf";
            };
            class EcoResource_showCurrentZoneInfoForUnit {
                file = "MissionScripts\EconomySystems\Resource\showCurrentZoneInfoForUnit.sqf";
            };
            class EcoResource_getZoneInfoText {
                file = "MissionScripts\EconomySystems\Resource\getZoneInfoText.sqf";
            };
            class EcoResource_ensureStableZonePlayerActionsLocal {
                file = "MissionScripts\EconomySystems\Resource\ensureStableZonePlayerActionsLocal.sqf";
            };
            class EcoResource_getAllSideResourceRows {
                file = "MissionScripts\EconomySystems\Resource\getAllSideResourceRows.sqf";
            };
            class EcoResource_getSideStorageBonus {
                file = "MissionScripts\EconomySystems\Resource\getSideStorageBonus.sqf";
            };
            class EcoResource_getSideResourceStorageCapacity {
                file = "MissionScripts\EconomySystems\Resource\getSideResourceStorageCapacity.sqf";
            };
            class EcoResource_getAllowedResourceGain {
                file = "MissionScripts\EconomySystems\Resource\getAllowedResourceGain.sqf";
            };
            class EcoResource_applyResourceRowsToSide {
                file = "MissionScripts\EconomySystems\Resource\applyResourceRowsToSide.sqf";
            };
            class EcoResource_getSideResourceNetRatePerMinute {
                file = "MissionScripts\EconomySystems\Resource\getSideResourceNetRatePerMinute.sqf";
            };
            class EcoResource_formatResourceIncomeTag {
                file = "MissionScripts\EconomySystems\Resource\formatResourceIncomeTag.sqf";
            };
            class EcoResource_registerCuratorEditableObject {
                file = "MissionScripts\EconomySystems\Resource\registerCuratorEditableObject.sqf";
            };
            class EcoResource_startAuthorityLoops {
                file = "MissionScripts\EconomySystems\Resource\startAuthorityLoops.sqf";
            };
            class EcoResource_getActiveResourceMarkers {
                file = "MissionScripts\EconomySystems\Resource\getActiveResourceMarkers.sqf";
            };
            class EcoResource_normalizeResourceName {
                file = "MissionScripts\EconomySystems\Resource\normalizeResourceName.sqf";
            };
            class EcoResource_normalizeResourceColor {
                file = "MissionScripts\EconomySystems\Resource\normalizeResourceColor.sqf";
            };
            class EcoResource_colorHexToRGBA {
                file = "MissionScripts\EconomySystems\Resource\colorHexToRGBA.sqf";
            };
            class EcoResource_normalizeResourceBaseStorage {
                file = "MissionScripts\EconomySystems\Resource\normalizeResourceBaseStorage.sqf";
            };
            class EcoResource_normalizeResourceCatalog {
                file = "MissionScripts\EconomySystems\Resource\normalizeResourceCatalog.sqf";
            };
            class EcoResource_normalizeSideResourceRows {
                file = "MissionScripts\EconomySystems\Resource\normalizeSideResourceRows.sqf";
            };
            class EcoResource_normalizeResourceRows {
                file = "MissionScripts\EconomySystems\Resource\normalizeResourceRows.sqf";
            };
            class EcoResource_normalizeZoneResourceRows {
                file = "MissionScripts\EconomySystems\Resource\normalizeZoneResourceRows.sqf";
            };
            class EcoResource_parseResourceRowsText {
                file = "MissionScripts\EconomySystems\Resource\parseResourceRowsText.sqf";
            };
            class EcoResource_parseZoneResourceRowsText {
                file = "MissionScripts\EconomySystems\Resource\parseZoneResourceRowsText.sqf";
            };
            class EcoResource_formatResourceRowsText {
                file = "MissionScripts\EconomySystems\Resource\formatResourceRowsText.sqf";
            };
            class EcoResource_formatZoneResourceRowsText {
                file = "MissionScripts\EconomySystems\Resource\formatZoneResourceRowsText.sqf";
            };
            class EcoResource_getPrimaryResourceType {
                file = "MissionScripts\EconomySystems\Resource\getPrimaryResourceType.sqf";
            };
            class EcoResource_getResourceRowsSummaryText {
                file = "MissionScripts\EconomySystems\Resource\getResourceRowsSummaryText.sqf";
            };
            class EcoResource_getZoneResourceRowsSummaryText {
                file = "MissionScripts\EconomySystems\Resource\getZoneResourceRowsSummaryText.sqf";
            };
            class EcoResource_getZoneResourceMarkerText {
                file = "MissionScripts\EconomySystems\Resource\getZoneResourceMarkerText.sqf";
            };
            class EcoResource_getCrateResourceRows {
                file = "MissionScripts\EconomySystems\Resource\getCrateResourceRows.sqf";
            };
            class EcoResource_getZoneResourceRows {
                file = "MissionScripts\EconomySystems\Resource\getZoneResourceRows.sqf";
            };
            class EcoResource_initializeResourceData {
                file = "MissionScripts\EconomySystems\Resource\initializeResourceData.sqf";
            };
            class EcoResource_getSideResourceAmount {
                file = "MissionScripts\EconomySystems\Resource\getSideResourceAmount.sqf";
            };
            class EcoResource_setSideResourceAmount {
                file = "MissionScripts\EconomySystems\Resource\setSideResourceAmount.sqf";
            };
            class EcoResource_addSideResourceAmount {
                file = "MissionScripts\EconomySystems\Resource\addSideResourceAmount.sqf";
            };
            class EcoResource_addResourceType {
                file = "MissionScripts\EconomySystems\Resource\addResourceType.sqf";
            };
            class EcoResource_removeResourceType {
                file = "MissionScripts\EconomySystems\Resource\removeResourceType.sqf";
            };
            class EcoResource_validateImportPayload {
                file = "MissionScripts\EconomySystems\Resource\validateImportPayload.sqf";
            };
            class EcoResource_buildExportPayload {
                file = "MissionScripts\EconomySystems\Resource\buildExportPayload.sqf";
            };
            class EcoResource_buildSetupCalls {
                file = "MissionScripts\EconomySystems\Resource\buildSetupCalls.sqf";
            };
            class EcoResource_importResourceConfiguration {
                file = "MissionScripts\EconomySystems\Resource\importResourceConfiguration.sqf";
            };
            class EcoResource_setResourceMarkerVisibility {
                file = "MissionScripts\EconomySystems\Resource\setResourceMarkerVisibility.sqf";
            };
            class EcoResource_toggleResourceMarkerVisibility {
                file = "MissionScripts\EconomySystems\Resource\toggleResourceMarkerVisibility.sqf";
            };
            class EcoResource_getResourceMarkerVisibilityAlpha {
                file = "MissionScripts\EconomySystems\Resource\getResourceMarkerVisibilityAlpha.sqf";
            };
            class EcoResource_applyResourceMarkerVisibilityGlobal {
                file = "MissionScripts\EconomySystems\Resource\applyResourceMarkerVisibilityGlobal.sqf";
            };
            class EcoResource_deleteCrateMarker {
                file = "MissionScripts\EconomySystems\Resource\deleteCrateMarker.sqf";
            };
            class EcoResource_trackCrateMarker {
                file = "MissionScripts\EconomySystems\Resource\trackCrateMarker.sqf";
            };
            class EcoResource_refreshCrateMarker {
                file = "MissionScripts\EconomySystems\Resource\refreshCrateMarker.sqf";
            };
            class EcoResource_getZoneOwnerFlagMarkerClass {
                file = "MissionScripts\EconomySystems\Resource\getZoneOwnerFlagMarkerClass.sqf";
            };
            class EcoResource_deleteZoneFlagMarker {
                file = "MissionScripts\EconomySystems\Resource\deleteZoneFlagMarker.sqf";
            };
            class EcoResource_refreshZoneFlagMarker {
                file = "MissionScripts\EconomySystems\Resource\refreshZoneFlagMarker.sqf";
            };
            class EcoResource_deleteZoneDetailMarkers {
                file = "MissionScripts\EconomySystems\Resource\deleteZoneDetailMarkers.sqf";
            };
            class EcoResource_deleteZoneMarker {
                file = "MissionScripts\EconomySystems\Resource\deleteZoneMarker.sqf";
            };
            class EcoResource_deleteResourceZone {
                file = "MissionScripts\EconomySystems\Resource\deleteResourceZone.sqf";
            };
            class EcoResource_createZoneAnchor {
                file = "MissionScripts\EconomySystems\Resource\createZoneAnchor.sqf";
            };
            class EcoResource_refreshZoneDetailMarkers {
                file = "MissionScripts\EconomySystems\Resource\refreshZoneDetailMarkers.sqf";
            };
            class EcoResource_refreshZoneMarker {
                file = "MissionScripts\EconomySystems\Resource\refreshZoneMarker.sqf";
            };
            class EcoResource_createZoneMarker {
                file = "MissionScripts\EconomySystems\Resource\createZoneMarker.sqf";
            };
            class EcoResource_createResourceZone {
                file = "MissionScripts\EconomySystems\Resource\createResourceZone.sqf";
            };
            class EcoResource_captureResourceZoneForSideKey {
                file = "MissionScripts\EconomySystems\Resource\captureResourceZoneForSideKey.sqf";
            };
            class EcoResource_captureResourceZone {
                file = "MissionScripts\EconomySystems\Resource\captureResourceZone.sqf";
            };
            class EcoResource_processZoneCaptureRequest {
                file = "MissionScripts\EconomySystems\Resource\processZoneCaptureRequest.sqf";
            };
            class EcoResource_startZoneCaptureRequestLoop {
                file = "MissionScripts\EconomySystems\Resource\startZoneCaptureRequestLoop.sqf";
            };
            class EcoResource_startPubZeusZoneActionBridge {
                file = "MissionScripts\EconomySystems\Resource\startPubZeusZoneActionBridge.sqf";
            };
            class EcoResource_generateZoneResources {
                file = "MissionScripts\EconomySystems\Resource\generateZoneResources.sqf";
            };
            class EcoResource_collectCrate {
                file = "MissionScripts\EconomySystems\Resource\collectCrate.sqf";
            };
            class EcoResource_spawnResourceCrate {
                file = "MissionScripts\EconomySystems\Resource\spawnResourceCrate.sqf";
            };
            class EcoResource_ensureCrateActionLocal {
                file = "MissionScripts\EconomySystems\Resource\ensureCrateActionLocal.sqf";
            };
            class EcoResource_processCrateCollectRequest {
                file = "MissionScripts\EconomySystems\Resource\processCrateCollectRequest.sqf";
            };
            class EcoResource_startCrateCollectRequestLoop {
                file = "MissionScripts\EconomySystems\Resource\startCrateCollectRequestLoop.sqf";
            };
            class EcoResource_cleanupResourceCratePrompt {
                file = "MissionScripts\EconomySystems\Resource\cleanupResourceCratePrompt.sqf";
            };
            class EcoResource_cleanupResourceSettingsPrompt {
                file = "MissionScripts\EconomySystems\Resource\cleanupResourceSettingsPrompt.sqf";
            };
            class EcoResource_cleanupResourceConfigPrompt {
                file = "MissionScripts\EconomySystems\Resource\cleanupResourceConfigPrompt.sqf";
            };
            class EcoResource_cleanupResourceZonePrompt {
                file = "MissionScripts\EconomySystems\Resource\cleanupResourceZonePrompt.sqf";
            };
            class EcoResource_setPromptInputTargets {
                file = "MissionScripts\EconomySystems\Resource\setPromptInputTargets.sqf";
            };
            class EcoResource_stopResourceCratePlacement {
                file = "MissionScripts\EconomySystems\Resource\stopResourceCratePlacement.sqf";
            };
            class EcoResource_populateResourceConfigList {
                file = "MissionScripts\EconomySystems\Resource\populateResourceConfigList.sqf";
            };
            class EcoResource_getResourceStructuredLabel {
                file = "MissionScripts\EconomySystems\Resource\getResourceStructuredLabel.sqf";
            };
            class EcoResource_refreshResourceSettings {
                file = "MissionScripts\EconomySystems\Resource\refreshResourceSettings.sqf";
            };
            class EcoResource_cycleResourceSettingsType {
                file = "MissionScripts\EconomySystems\Resource\cycleResourceSettingsType.sqf";
            };
            class EcoResource_selectResourceSettingsSide {
                file = "MissionScripts\EconomySystems\Resource\selectResourceSettingsSide.sqf";
            };
            class EcoResource_refreshResourceConfigIcon {
                file = "MissionScripts\EconomySystems\Resource\refreshResourceConfigIcon.sqf";
            };
            class EcoResource_cycleResourceConfigIcon {
                file = "MissionScripts\EconomySystems\Resource\cycleResourceConfigIcon.sqf";
            };
            class EcoResource_collectResourceConfigFormData {
                file = "MissionScripts\EconomySystems\Resource\collectResourceConfigFormData.sqf";
            };
            class EcoResource_saveResourceConfigSelection {
                file = "MissionScripts\EconomySystems\Resource\saveResourceConfigSelection.sqf";
            };
            class EcoResource_loadResourceIntoPrompt {
                file = "MissionScripts\EconomySystems\Resource\loadResourceIntoPrompt.sqf";
            };
            class EcoResource_applyResourceMarkerVisibilityLocal {
                file = "MissionScripts\EconomySystems\Resource\applyResourceMarkerVisibilityLocal.sqf";
            };
            class EcoResource_refreshResourceZonePrompt {
                file = "MissionScripts\EconomySystems\Resource\refreshResourceZonePrompt.sqf";
            };
            class EcoResource_cycleResourceZoneOwner {
                file = "MissionScripts\EconomySystems\Resource\cycleResourceZoneOwner.sqf";
            };
            class EcoResource_showZoneInfo {
                file = "MissionScripts\EconomySystems\Resource\showZoneInfo.sqf";
            };
            class EcoResource_promptResourceCrateValue {
                file = "MissionScripts\EconomySystems\Resource\promptResourceCrateValue.sqf";
            };
            class EcoResource_promptResourceSettings {
                file = "MissionScripts\EconomySystems\Resource\promptResourceSettings.sqf";
            };
            class EcoResource_promptResourceConfig {
                file = "MissionScripts\EconomySystems\Resource\promptResourceConfig.sqf";
            };
            class EcoResource_promptResourceZone {
                file = "MissionScripts\EconomySystems\Resource\promptResourceZone.sqf";
            };
            class EcoResource_startClientRuntime {
                file = "MissionScripts\EconomySystems\Resource\startClientRuntime.sqf";
            };
        };
        class EcoResearch
        {
            class EcoResearch_registerCenter {
                file = "MissionScripts\EconomySystems\Research\registerCenter.sqf";
            };
            class EcoResearch_getResearchCatalog {
                file = "MissionScripts\EconomySystems\Research\getResearchCatalog.sqf";
            };
            class EcoResearch_getResearchStateVar {
                file = "MissionScripts\EconomySystems\Research\getResearchStateVar.sqf";
            };
            class EcoResearch_getResearchActiveVar {
                file = "MissionScripts\EconomySystems\Research\getResearchActiveVar.sqf";
            };
            class EcoResearch_getSideResearched {
                file = "MissionScripts\EconomySystems\Research\getSideResearched.sqf";
            };
            class EcoResearch_setSideResearched {
                file = "MissionScripts\EconomySystems\Research\setSideResearched.sqf";
            };
            class EcoResearch_isResearchCompletedForSide {
                file = "MissionScripts\EconomySystems\Research\isResearchCompletedForSide.sqf";
            };
            class EcoResearch_setResearchCompletedForSide {
                file = "MissionScripts\EconomySystems\Research\setResearchCompletedForSide.sqf";
            };
            class EcoResearch_getSideActiveResearch {
                file = "MissionScripts\EconomySystems\Research\getSideActiveResearch.sqf";
            };
            class EcoResearch_setSideActiveResearch {
                file = "MissionScripts\EconomySystems\Research\setSideActiveResearch.sqf";
            };
            class EcoResearch_getActiveResearchRemainingSeconds {
                file = "MissionScripts\EconomySystems\Research\getActiveResearchRemainingSeconds.sqf";
            };
            class EcoResearch_normalizeResearchExclusives {
                file = "MissionScripts\EconomySystems\Research\normalizeResearchExclusives.sqf";
            };
            class EcoResearch_normalizeResearchEntry {
                file = "MissionScripts\EconomySystems\Research\normalizeResearchEntry.sqf";
            };
            class EcoResearch_normalizeResearchCatalog {
                file = "MissionScripts\EconomySystems\Research\normalizeResearchCatalog.sqf";
            };
            class EcoResearch_setResearchCatalogLocal {
                file = "MissionScripts\EconomySystems\Research\setResearchCatalogLocal.sqf";
            };
            class EcoResearch_setResearchCatalog {
                file = "MissionScripts\EconomySystems\Research\setResearchCatalog.sqf";
            };
            class EcoResearch_hasResearchEntryError {
                file = "MissionScripts\EconomySystems\Research\hasResearchEntryError.sqf";
            };
            class EcoResearch_getValidResearchCatalog {
                file = "MissionScripts\EconomySystems\Research\getValidResearchCatalog.sqf";
            };
            class EcoResearch_getResearchEntryByName {
                file = "MissionScripts\EconomySystems\Research\getResearchEntryByName.sqf";
            };
            class EcoResearch_areResearchRequirementsMet {
                file = "MissionScripts\EconomySystems\Research\areResearchRequirementsMet.sqf";
            };
            class EcoResearch_canAffordResearch {
                file = "MissionScripts\EconomySystems\Research\canAffordResearch.sqf";
            };
            class EcoResearch_isResearchExclusiveBlocked {
                file = "MissionScripts\EconomySystems\Research\isResearchExclusiveBlocked.sqf";
            };
            class EcoResearch_getResearchStatus {
                file = "MissionScripts\EconomySystems\Research\getResearchStatus.sqf";
            };
            class EcoResearch_spendResearchCosts {
                file = "MissionScripts\EconomySystems\Research\spendResearchCosts.sqf";
            };
            class EcoResearch_startResearch {
                file = "MissionScripts\EconomySystems\Research\startResearch.sqf";
            };
            class EcoResearch_progressResearchQueue {
                file = "MissionScripts\EconomySystems\Research\progressResearchQueue.sqf";
            };
            class EcoResearch_buildResearchExportPayload {
                file = "MissionScripts\EconomySystems\Research\buildResearchExportPayload.sqf";
            };
            class EcoResearch_buildSetupCalls {
                file = "MissionScripts\EconomySystems\Research\buildSetupCalls.sqf";
            };
            class EcoResearch_validateResearchImportPayload {
                file = "MissionScripts\EconomySystems\Research\validateResearchImportPayload.sqf";
            };
            class EcoResearch_importResearchConfiguration {
                file = "MissionScripts\EconomySystems\Research\importResearchConfiguration.sqf";
            };
            class EcoResearch_parseResearchExclusivesText {
                file = "MissionScripts\EconomySystems\Research\parseResearchExclusivesText.sqf";
            };
            class EcoResearch_cleanupResearchConfigPrompt {
                file = "MissionScripts\EconomySystems\Research\cleanupResearchConfigPrompt.sqf";
            };
            class EcoResearch_setPromptInputTargets {
                file = "MissionScripts\EconomySystems\Research\setPromptInputTargets.sqf";
            };
            class EcoResearch_stopResearchCenterPlacement {
                file = "MissionScripts\EconomySystems\Research\stopResearchCenterPlacement.sqf";
            };
            class EcoResearch_spawnResearchCenter {
                file = "MissionScripts\EconomySystems\Research\spawnResearchCenter.sqf";
            };
            class EcoResearch_processStartResearchRequest {
                file = "MissionScripts\EconomySystems\Research\processStartResearchRequest.sqf";
            };
            class EcoResearch_startResearchRequestLoop {
                file = "MissionScripts\EconomySystems\Research\startResearchRequestLoop.sqf";
            };
            class EcoResearch_getOfficialResourceDisplayActionArgs {
                file = "MissionScripts\EconomySystems\Research\getOfficialResourceDisplayActionArgs.sqf";
            };
            class EcoResearch_ensureResearchCenterActionsLocal {
                file = "MissionScripts\EconomySystems\Research\ensureResearchCenterActionsLocal.sqf";
            };
            class EcoResearch_refreshResearchConfigIcon {
                file = "MissionScripts\EconomySystems\Research\refreshResearchConfigIcon.sqf";
            };
            class EcoResearch_cycleResearchConfigIcon {
                file = "MissionScripts\EconomySystems\Research\cycleResearchConfigIcon.sqf";
            };
            class EcoResearch_populateResearchConfigList {
                file = "MissionScripts\EconomySystems\Research\populateResearchConfigList.sqf";
            };
            class EcoResearch_collectResearchFormData {
                file = "MissionScripts\EconomySystems\Research\collectResearchFormData.sqf";
            };
            class EcoResearch_loadResearchIntoPrompt {
                file = "MissionScripts\EconomySystems\Research\loadResearchIntoPrompt.sqf";
            };
            class EcoResearch_promptResearchConfig {
                file = "MissionScripts\EconomySystems\Research\promptResearchConfig.sqf";
            };
        };
        class EcoBuild
        {
            class EcoBuild_registerConstructionVehicle {
                file = "MissionScripts\EconomySystems\Build\registerConstructionVehicle.sqf";
            };
            class EcoBuild_getBuildCatalog {
                file = "MissionScripts\EconomySystems\Build\getBuildCatalog.sqf";
            };
            class EcoBuild_getSpawnedBuildings {
                file = "MissionScripts\EconomySystems\Build\getSpawnedBuildings.sqf";
            };
            class EcoBuild_setSpawnedBuildings {
                file = "MissionScripts\EconomySystems\Build\setSpawnedBuildings.sqf";
            };
            class EcoBuild_getActiveConstructionJobs {
                file = "MissionScripts\EconomySystems\Build\getActiveConstructionJobs.sqf";
            };
            class EcoBuild_setActiveConstructionJobs {
                file = "MissionScripts\EconomySystems\Build\setActiveConstructionJobs.sqf";
            };
            class EcoBuild_registerConstructionJob {
                file = "MissionScripts\EconomySystems\Build\registerConstructionJob.sqf";
            };
            class EcoBuild_unregisterConstructionJob {
                file = "MissionScripts\EconomySystems\Build\unregisterConstructionJob.sqf";
            };
            class EcoBuild_getConstructionJobRuntime {
                file = "MissionScripts\EconomySystems\Build\getConstructionJobRuntime.sqf";
            };
            class EcoBuild_setConstructionJobRuntime {
                file = "MissionScripts\EconomySystems\Build\setConstructionJobRuntime.sqf";
            };
            class EcoBuild_getUpgradeJobRuntime {
                file = "MissionScripts\EconomySystems\Build\getUpgradeJobRuntime.sqf";
            };
            class EcoBuild_setUpgradeJobRuntime {
                file = "MissionScripts\EconomySystems\Build\setUpgradeJobRuntime.sqf";
            };
            class EcoBuild_normalizeBuildAvailability {
                file = "MissionScripts\EconomySystems\Build\normalizeBuildAvailability.sqf";
            };
            class EcoBuild_normalizeBuildEntry {
                file = "MissionScripts\EconomySystems\Build\normalizeBuildEntry.sqf";
            };
            class EcoBuild_normalizeBuildCatalog {
                file = "MissionScripts\EconomySystems\Build\normalizeBuildCatalog.sqf";
            };
            class EcoBuild_setBuildCatalogLocal {
                file = "MissionScripts\EconomySystems\Build\setBuildCatalogLocal.sqf";
            };
            class EcoBuild_setBuildCatalog {
                file = "MissionScripts\EconomySystems\Build\setBuildCatalog.sqf";
            };
            class EcoBuild_buildBuildExportPayload {
                file = "MissionScripts\EconomySystems\Build\buildBuildExportPayload.sqf";
            };
            class EcoBuild_buildSetupCalls {
                file = "MissionScripts\EconomySystems\Build\buildSetupCalls.sqf";
            };
            class EcoBuild_validateBuildImportPayload {
                file = "MissionScripts\EconomySystems\Build\validateBuildImportPayload.sqf";
            };
            class EcoBuild_importBuildConfiguration {
                file = "MissionScripts\EconomySystems\Build\importBuildConfiguration.sqf";
            };
            class EcoBuild_getBuildStorageRows {
                file = "MissionScripts\EconomySystems\Build\getBuildStorageRows.sqf";
            };
            class EcoBuild_hasBuildEntryError {
                file = "MissionScripts\EconomySystems\Build\hasBuildEntryError.sqf";
            };
            class EcoBuild_getValidBuildCatalog {
                file = "MissionScripts\EconomySystems\Build\getValidBuildCatalog.sqf";
            };
            class EcoBuild_getBuildDefinition {
                file = "MissionScripts\EconomySystems\Build\getBuildDefinition.sqf";
            };
            class EcoBuild_isBuildRequirementSatisfied {
                file = "MissionScripts\EconomySystems\Build\isBuildRequirementSatisfied.sqf";
            };
            class EcoBuild_isBuildRequirementSatisfiedForSide {
                file = "MissionScripts\EconomySystems\Build\isBuildRequirementSatisfiedForSide.sqf";
            };
            class EcoBuild_areBuildRequirementsMetForSide {
                file = "MissionScripts\EconomySystems\Build\areBuildRequirementsMetForSide.sqf";
            };
            class EcoBuild_canAffordBuildForSide {
                file = "MissionScripts\EconomySystems\Build\canAffordBuildForSide.sqf";
            };
            class EcoBuild_getBuildCountForSide {
                file = "MissionScripts\EconomySystems\Build\getBuildCountForSide.sqf";
            };
            class EcoBuild_isBuildLimitReachedForSide {
                file = "MissionScripts\EconomySystems\Build\isBuildLimitReachedForSide.sqf";
            };
            class EcoBuild_isBuildAvailableForSide {
                file = "MissionScripts\EconomySystems\Build\isBuildAvailableForSide.sqf";
            };
            class EcoBuild_getPlayerVisibleBuildCatalog {
                file = "MissionScripts\EconomySystems\Build\getPlayerVisibleBuildCatalog.sqf";
            };
            class EcoBuild_getPlayerVisibleBuildCategories {
                file = "MissionScripts\EconomySystems\Build\getPlayerVisibleBuildCategories.sqf";
            };
            class EcoBuild_getSideResearchSpeedBonusPercent {
                file = "MissionScripts\EconomySystems\Build\getSideResearchSpeedBonusPercent.sqf";
            };
            class EcoBuild_getSideBuildSpeedBonusPercent {
                file = "MissionScripts\EconomySystems\Build\getSideBuildSpeedBonusPercent.sqf";
            };
            class EcoBuild_getEstimatedDurationSeconds {
                file = "MissionScripts\EconomySystems\Build\getEstimatedDurationSeconds.sqf";
            };
            class EcoBuild_getPlayerBuildStatus {
                file = "MissionScripts\EconomySystems\Build\getPlayerBuildStatus.sqf";
            };
            class EcoBuild_getBuildMarkerClass {
                file = "MissionScripts\EconomySystems\Build\getBuildMarkerClass.sqf";
            };
            class EcoBuild_canPlayerManageBuilding {
                file = "MissionScripts\EconomySystems\Build\canPlayerManageBuilding.sqf";
            };
            class EcoBuild_getUpgradeTargetName {
                file = "MissionScripts\EconomySystems\Build\getUpgradeTargetName.sqf";
            };
            class EcoBuild_getUpgradeTargetEntry {
                file = "MissionScripts\EconomySystems\Build\getUpgradeTargetEntry.sqf";
            };
            class EcoBuild_canPlayerViewUpgrade {
                file = "MissionScripts\EconomySystems\Build\canPlayerViewUpgrade.sqf";
            };
            class EcoBuild_getPlayerUpgradeStatus {
                file = "MissionScripts\EconomySystems\Build\getPlayerUpgradeStatus.sqf";
            };
            class EcoBuild_cleanupBuildConfigPrompt {
                file = "MissionScripts\EconomySystems\Build\cleanupBuildConfigPrompt.sqf";
            };
            class EcoBuild_cleanupSpawnBuildingPrompt {
                file = "MissionScripts\EconomySystems\Build\cleanupSpawnBuildingPrompt.sqf";
            };
            class EcoBuild_setPromptInputTargets {
                file = "MissionScripts\EconomySystems\Build\setPromptInputTargets.sqf";
            };
            class EcoBuild_refreshBuildConfigIcon {
                file = "MissionScripts\EconomySystems\Build\refreshBuildConfigIcon.sqf";
            };
            class EcoBuild_cycleBuildConfigIcon {
                file = "MissionScripts\EconomySystems\Build\cycleBuildConfigIcon.sqf";
            };
            class EcoBuild_setBuildConfigTab {
                file = "MissionScripts\EconomySystems\Build\setBuildConfigTab.sqf";
            };
            class EcoBuild_getSpawnBuildingSideChoices {
                file = "MissionScripts\EconomySystems\Build\getSpawnBuildingSideChoices.sqf";
            };
            class EcoBuild_refreshSpawnBuildingSide {
                file = "MissionScripts\EconomySystems\Build\refreshSpawnBuildingSide.sqf";
            };
            class EcoBuild_cycleSpawnBuildingSide {
                file = "MissionScripts\EconomySystems\Build\cycleSpawnBuildingSide.sqf";
            };
            class EcoBuild_populateSpawnBuildingList {
                file = "MissionScripts\EconomySystems\Build\populateSpawnBuildingList.sqf";
            };
            class EcoBuild_populateBuildConfigList {
                file = "MissionScripts\EconomySystems\Build\populateBuildConfigList.sqf";
            };
            class EcoBuild_collectBuildFormData {
                file = "MissionScripts\EconomySystems\Build\collectBuildFormData.sqf";
            };
            class EcoBuild_loadBuildIntoPrompt {
                file = "MissionScripts\EconomySystems\Build\loadBuildIntoPrompt.sqf";
            };
            class EcoBuild_promptBuildConfig {
                file = "MissionScripts\EconomySystems\Build\promptBuildConfig.sqf";
            };
            class EcoBuild_getFallbackBuildAnchorClass {
                file = "MissionScripts\EconomySystems\Build\getFallbackBuildAnchorClass.sqf";
            };
            class EcoBuild_getBuildSpawnClass {
                file = "MissionScripts\EconomySystems\Build\getBuildSpawnClass.sqf";
            };
            class EcoBuild_spawnConfiguredBuilding {
                file = "MissionScripts\EconomySystems\Build\spawnConfiguredBuilding.sqf";
            };
            class EcoBuild_getOfficialBuildingInspectActionArgs {
                file = "MissionScripts\EconomySystems\Build\getOfficialBuildingInspectActionArgs.sqf";
            };
            class EcoBuild_getOfficialBuildingManageActionArgs {
                file = "MissionScripts\EconomySystems\Build\getOfficialBuildingManageActionArgs.sqf";
            };
            class EcoBuild_getOfficialBuildingClaimActionArgs {
                file = "MissionScripts\EconomySystems\Build\getOfficialBuildingClaimActionArgs.sqf";
            };
            class EcoBuild_getOfficialBuildingUpgradeActionArgs {
                file = "MissionScripts\EconomySystems\Build\getOfficialBuildingUpgradeActionArgs.sqf";
            };
            class EcoBuild_attachBuildingActions {
                file = "MissionScripts\EconomySystems\Build\attachBuildingActions.sqf";
            };
            class EcoBuild_promptSpawnBuilding {
                file = "MissionScripts\EconomySystems\Build\promptSpawnBuilding.sqf";
            };
            class EcoBuild_addSharedMarkerName {
                file = "MissionScripts\EconomySystems\Build\addSharedMarkerName.sqf";
            };
            class EcoBuild_removeSharedMarkerName {
                file = "MissionScripts\EconomySystems\Build\removeSharedMarkerName.sqf";
            };
            class EcoBuild_deleteNamedMarker {
                file = "MissionScripts\EconomySystems\Build\deleteNamedMarker.sqf";
            };
            class EcoBuild_getMarkerSidePrefix {
                file = "MissionScripts\EconomySystems\Build\getMarkerSidePrefix.sqf";
            };
            class EcoBuild_getMarkerColorBySide {
                file = "MissionScripts\EconomySystems\Build\getMarkerColorBySide.sqf";
            };
            class EcoBuild_getDetectorMarkerType {
                file = "MissionScripts\EconomySystems\Build\getDetectorMarkerType.sqf";
            };
            class EcoBuild_clusterDetectorContacts {
                file = "MissionScripts\EconomySystems\Build\clusterDetectorContacts.sqf";
            };
            class EcoBuild_cleanupDetectorContactMarkers {
                file = "MissionScripts\EconomySystems\Build\cleanupDetectorContactMarkers.sqf";
            };
            class EcoBuild_cleanupDetectorVisuals {
                file = "MissionScripts\EconomySystems\Build\cleanupDetectorVisuals.sqf";
            };
            class EcoBuild_ensureDetectorAreaMarker {
                file = "MissionScripts\EconomySystems\Build\ensureDetectorAreaMarker.sqf";
            };
            class EcoBuild_scanDetectorBuilding {
                file = "MissionScripts\EconomySystems\Build\scanDetectorBuilding.sqf";
            };
            class EcoBuild_deleteBuildingMarker {
                file = "MissionScripts\EconomySystems\Build\deleteBuildingMarker.sqf";
            };
            class EcoBuild_refreshBuildingMarker {
                file = "MissionScripts\EconomySystems\Build\refreshBuildingMarker.sqf";
            };
            class EcoBuild_trackBuildingMarker {
                file = "MissionScripts\EconomySystems\Build\trackBuildingMarker.sqf";
            };
            class EcoBuild_showBuildingInfo {
                file = "MissionScripts\EconomySystems\Build\showBuildingInfo.sqf";
            };
            class EcoBuild_disableBuilding {
                file = "MissionScripts\EconomySystems\Build\disableBuilding.sqf";
            };
            class EcoBuild_enableBuilding {
                file = "MissionScripts\EconomySystems\Build\enableBuilding.sqf";
            };
            class EcoBuild_processBuildingManageRequest {
                file = "MissionScripts\EconomySystems\Build\processBuildingManageRequest.sqf";
            };
            class EcoBuild_startBuildingManageRequestLoop {
                file = "MissionScripts\EconomySystems\Build\startBuildingManageRequestLoop.sqf";
            };
            class EcoBuild_claimBuilding {
                file = "MissionScripts\EconomySystems\Build\claimBuilding.sqf";
            };
            class EcoBuild_processBuildingProduction {
                file = "MissionScripts\EconomySystems\Build\processBuildingProduction.sqf";
            };
            class EcoBuild_getBuildEffectLines {
                file = "MissionScripts\EconomySystems\Build\getBuildEffectLines.sqf";
            };
            class EcoBuild_getOfficialConstructionModeActionArgs {
                file = "MissionScripts\EconomySystems\Build\getOfficialConstructionModeActionArgs.sqf";
            };
            class EcoBuild_startBuildingUpgrade {
                file = "MissionScripts\EconomySystems\Build\startBuildingUpgrade.sqf";
            };
            class EcoBuild_spawnConstructionSite {
                file = "MissionScripts\EconomySystems\Build\spawnConstructionSite.sqf";
            };
            class EcoBuild_deleteConstructionSite {
                file = "MissionScripts\EconomySystems\Build\deleteConstructionSite.sqf";
            };
            class EcoBuild_progressConstructionJobs {
                file = "MissionScripts\EconomySystems\Build\progressConstructionJobs.sqf";
            };
            class EcoBuild_progressUpgradeJobs {
                file = "MissionScripts\EconomySystems\Build\progressUpgradeJobs.sqf";
            };
            class EcoBuild_getPlayerConstructionAimPos {
                file = "MissionScripts\EconomySystems\Build\getPlayerConstructionAimPos.sqf";
            };
            class EcoBuild_cleanupConstructionPlacementLocal {
                file = "MissionScripts\EconomySystems\Build\cleanupConstructionPlacementLocal.sqf";
            };
            class EcoBuild_startPlacedConstruction {
                file = "MissionScripts\EconomySystems\Build\startPlacedConstruction.sqf";
            };
            class EcoBuild_processStartConstructionRequest {
                file = "MissionScripts\EconomySystems\Build\processStartConstructionRequest.sqf";
            };
            class EcoBuild_startConstructionRequestLoop {
                file = "MissionScripts\EconomySystems\Build\startConstructionRequestLoop.sqf";
            };
            class EcoBuild_beginPlayerConstructionPlacement {
                file = "MissionScripts\EconomySystems\Build\beginPlayerConstructionPlacement.sqf";
            };
            class EcoBuild_startVehicleConstruction {
                file = "MissionScripts\EconomySystems\Build\startVehicleConstruction.sqf";
            };
            class EcoBuild_stopConstructionPlacement {
                file = "MissionScripts\EconomySystems\Build\stopConstructionPlacement.sqf";
            };
            class EcoBuild_spawnConstructionVehicle {
                file = "MissionScripts\EconomySystems\Build\spawnConstructionVehicle.sqf";
            };
            class EcoBuild_ensureConstructionVehicleActionLocal {
                file = "MissionScripts\EconomySystems\Build\ensureConstructionVehicleActionLocal.sqf";
            };
        };
        class EcoBuy
        {
            class EcoBuy_registerTerminal {
                file = "MissionScripts\EconomySystems\Buy\registerTerminal.sqf";
            };
            class EcoBuy_startAuthorityLoops {
                file = "MissionScripts\EconomySystems\Buy\startAuthorityLoops.sqf";
            };
            class EcoBuy_getPurchaseCatalog {
                file = "MissionScripts\EconomySystems\Buy\getPurchaseCatalog.sqf";
            };
            class EcoBuy_getDropPoints {
                file = "MissionScripts\EconomySystems\Buy\getDropPoints.sqf";
            };
            class EcoBuy_setDropPoints {
                file = "MissionScripts\EconomySystems\Buy\setDropPoints.sqf";
            };
            class EcoBuy_getPurchaseTypeChoices {
                file = "MissionScripts\EconomySystems\Buy\getPurchaseTypeChoices.sqf";
            };
            class EcoBuy_getPurchaseSideChoices {
                file = "MissionScripts\EconomySystems\Buy\getPurchaseSideChoices.sqf";
            };
            class EcoBuy_getDropPointTypeChoices {
                file = "MissionScripts\EconomySystems\Buy\getDropPointTypeChoices.sqf";
            };
            class EcoBuy_getDropPointSideChoices {
                file = "MissionScripts\EconomySystems\Buy\getDropPointSideChoices.sqf";
            };
            class EcoBuy_normalizeDropPointSide {
                file = "MissionScripts\EconomySystems\Buy\normalizeDropPointSide.sqf";
            };
            class EcoBuy_getDropPointSideLabel {
                file = "MissionScripts\EconomySystems\Buy\getDropPointSideLabel.sqf";
            };
            class EcoBuy_normalizeDropPointType {
                file = "MissionScripts\EconomySystems\Buy\normalizeDropPointType.sqf";
            };
            class EcoBuy_normalizePurchaseType {
                file = "MissionScripts\EconomySystems\Buy\normalizePurchaseType.sqf";
            };
            class EcoBuy_normalizePurchaseEntry {
                file = "MissionScripts\EconomySystems\Buy\normalizePurchaseEntry.sqf";
            };
            class EcoBuy_normalizePurchaseCatalog {
                file = "MissionScripts\EconomySystems\Buy\normalizePurchaseCatalog.sqf";
            };
            class EcoBuy_setPurchaseCatalogLocal {
                file = "MissionScripts\EconomySystems\Buy\setPurchaseCatalogLocal.sqf";
            };
            class EcoBuy_setPurchaseCatalog {
                file = "MissionScripts\EconomySystems\Buy\setPurchaseCatalog.sqf";
            };
            class EcoBuy_buildPurchaseExportPayload {
                file = "MissionScripts\EconomySystems\Buy\buildPurchaseExportPayload.sqf";
            };
            class EcoBuy_buildSetupCalls {
                file = "MissionScripts\EconomySystems\Buy\buildSetupCalls.sqf";
            };
            class EcoBuy_validatePurchaseImportPayload {
                file = "MissionScripts\EconomySystems\Buy\validatePurchaseImportPayload.sqf";
            };
            class EcoBuy_importPurchaseConfiguration {
                file = "MissionScripts\EconomySystems\Buy\importPurchaseConfiguration.sqf";
            };
            class EcoBuy_hasPurchaseEntryError {
                file = "MissionScripts\EconomySystems\Buy\hasPurchaseEntryError.sqf";
            };
            class EcoBuy_cleanupPurchaseConfigPrompt {
                file = "MissionScripts\EconomySystems\Buy\cleanupPurchaseConfigPrompt.sqf";
            };
            class EcoBuy_cleanupDropPointPrompt {
                file = "MissionScripts\EconomySystems\Buy\cleanupDropPointPrompt.sqf";
            };
            class EcoBuy_setPromptInputTargets {
                file = "MissionScripts\EconomySystems\Buy\setPromptInputTargets.sqf";
            };
            class EcoBuy_refreshPurchaseConfigIcon {
                file = "MissionScripts\EconomySystems\Buy\refreshPurchaseConfigIcon.sqf";
            };
            class EcoBuy_cyclePurchaseConfigIcon {
                file = "MissionScripts\EconomySystems\Buy\cyclePurchaseConfigIcon.sqf";
            };
            class EcoBuy_refreshPurchaseConfigType {
                file = "MissionScripts\EconomySystems\Buy\refreshPurchaseConfigType.sqf";
            };
            class EcoBuy_cyclePurchaseConfigType {
                file = "MissionScripts\EconomySystems\Buy\cyclePurchaseConfigType.sqf";
            };
            class EcoBuy_refreshPurchaseConfigSide {
                file = "MissionScripts\EconomySystems\Buy\refreshPurchaseConfigSide.sqf";
            };
            class EcoBuy_cyclePurchaseConfigSide {
                file = "MissionScripts\EconomySystems\Buy\cyclePurchaseConfigSide.sqf";
            };
            class EcoBuy_findDropPointIndex {
                file = "MissionScripts\EconomySystems\Buy\findDropPointIndex.sqf";
            };
            class EcoBuy_deleteDropPoint {
                file = "MissionScripts\EconomySystems\Buy\deleteDropPoint.sqf";
            };
            class EcoBuy_createDropPoint {
                file = "MissionScripts\EconomySystems\Buy\createDropPoint.sqf";
            };
            class EcoBuy_syncDropPoints {
                file = "MissionScripts\EconomySystems\Buy\syncDropPoints.sqf";
            };
            class EcoBuy_refreshDropPointType {
                file = "MissionScripts\EconomySystems\Buy\refreshDropPointType.sqf";
            };
            class EcoBuy_cycleDropPointType {
                file = "MissionScripts\EconomySystems\Buy\cycleDropPointType.sqf";
            };
            class EcoBuy_refreshDropPointSide {
                file = "MissionScripts\EconomySystems\Buy\refreshDropPointSide.sqf";
            };
            class EcoBuy_cycleDropPointSide {
                file = "MissionScripts\EconomySystems\Buy\cycleDropPointSide.sqf";
            };
            class EcoBuy_populatePurchaseConfigList {
                file = "MissionScripts\EconomySystems\Buy\populatePurchaseConfigList.sqf";
            };
            class EcoBuy_getPlayerPurchaseSideLabel {
                file = "MissionScripts\EconomySystems\Buy\getPlayerPurchaseSideLabel.sqf";
            };
            class EcoBuy_getValidPurchaseCatalog {
                file = "MissionScripts\EconomySystems\Buy\getValidPurchaseCatalog.sqf";
            };
            class EcoBuy_arePurchaseRequirementsMetForSide {
                file = "MissionScripts\EconomySystems\Buy\arePurchaseRequirementsMetForSide.sqf";
            };
            class EcoBuy_canAffordPurchaseForSide {
                file = "MissionScripts\EconomySystems\Buy\canAffordPurchaseForSide.sqf";
            };
            class EcoBuy_canSideUsePurchase {
                file = "MissionScripts\EconomySystems\Buy\canSideUsePurchase.sqf";
            };
            class EcoBuy_getDropPointsForType {
                file = "MissionScripts\EconomySystems\Buy\getDropPointsForType.sqf";
            };
            class EcoBuy_findAvailableDropPoint {
                file = "MissionScripts\EconomySystems\Buy\findAvailableDropPoint.sqf";
            };
            class EcoBuy_getPlayerPurchaseStatus {
                file = "MissionScripts\EconomySystems\Buy\getPlayerPurchaseStatus.sqf";
            };
            class EcoBuy_collectPurchaseFormData {
                file = "MissionScripts\EconomySystems\Buy\collectPurchaseFormData.sqf";
            };
            class EcoBuy_loadPurchaseIntoPrompt {
                file = "MissionScripts\EconomySystems\Buy\loadPurchaseIntoPrompt.sqf";
            };
            class EcoBuy_promptPurchaseConfig {
                file = "MissionScripts\EconomySystems\Buy\promptPurchaseConfig.sqf";
            };
            class EcoBuy_spawnPurchaseLaptop {
                file = "MissionScripts\EconomySystems\Buy\spawnPurchaseLaptop.sqf";
            };
            class EcoBuy_getOfficialPurchaseActionArgs {
                file = "MissionScripts\EconomySystems\Buy\getOfficialPurchaseActionArgs.sqf";
            };
            class EcoBuy_ensurePurchaseTerminalActionLocal {
                file = "MissionScripts\EconomySystems\Buy\ensurePurchaseTerminalActionLocal.sqf";
            };
            class EcoBuy_stopDropPointPlacement {
                file = "MissionScripts\EconomySystems\Buy\stopDropPointPlacement.sqf";
            };
            class EcoBuy_promptDropPoint {
                file = "MissionScripts\EconomySystems\Buy\promptDropPoint.sqf";
            };
            class EcoBuy_executePurchase {
                file = "MissionScripts\EconomySystems\Buy\executePurchase.sqf";
            };
            class EcoBuy_processPurchaseRequest {
                file = "MissionScripts\EconomySystems\Buy\processPurchaseRequest.sqf";
            };
            class EcoBuy_startPurchaseRequestLoop {
                file = "MissionScripts\EconomySystems\Buy\startPurchaseRequestLoop.sqf";
            };
        };
        class EcoCommand
        {
            class EcoCommand_getGroundCommandKey {
                file = "MissionScripts\EconomySystems\Command\getGroundCommandKey.sqf";
            };
            class EcoCommand_isGroundCommandStoredKey {
                file = "MissionScripts\EconomySystems\Command\isGroundCommandStoredKey.sqf";
            };
            class EcoCommand_publishLocalGroundCommandIdentity {
                file = "MissionScripts\EconomySystems\Command\publishLocalGroundCommandIdentity.sqf";
            };
            class EcoCommand_getGroundCommandUIDs {
                file = "MissionScripts\EconomySystems\Command\getGroundCommandUIDs.sqf";
            };
            class EcoCommand_normalizeGroundCommandKey {
                file = "MissionScripts\EconomySystems\Command\normalizeGroundCommandKey.sqf";
            };
            class EcoCommand_setGroundCommandUIDs {
                file = "MissionScripts\EconomySystems\Command\setGroundCommandUIDs.sqf";
            };
            class EcoCommand_hasAnyGroundCommand {
                file = "MissionScripts\EconomySystems\Command\hasAnyGroundCommand.sqf";
            };
            class EcoCommand_isGroundCommandUID {
                file = "MissionScripts\EconomySystems\Command\isGroundCommandUID.sqf";
            };
            class EcoCommand_isGroundCommandUnit {
                file = "MissionScripts\EconomySystems\Command\isGroundCommandUnit.sqf";
            };
            class EcoCommand_hasCommandAuthority {
                file = "MissionScripts\EconomySystems\Command\hasCommandAuthority.sqf";
            };
            class EcoCommand_promoteGroundCommand {
                file = "MissionScripts\EconomySystems\Command\promoteGroundCommand.sqf";
            };
            class EcoCommand_removeGroundCommand {
                file = "MissionScripts\EconomySystems\Command\removeGroundCommand.sqf";
            };
            class EcoCommand_pruneGroundCommandUIDs {
                file = "MissionScripts\EconomySystems\Command\pruneGroundCommandUIDs.sqf";
            };
            class EcoCommand_refreshGroundCommandPrompt {
                file = "MissionScripts\EconomySystems\Command\refreshGroundCommandPrompt.sqf";
            };
            class EcoCommand_promptGroundCommand {
                file = "MissionScripts\EconomySystems\Command\promptGroundCommand.sqf";
            };
            class EcoCommand_cleanupGroundCommandPrompt {
                file = "MissionScripts\EconomySystems\Command\cleanupGroundCommandPrompt.sqf";
            };
        };
        class MiniGames
        {
            // Table games engine (multiplayer, seated party games). The engine defines its
            // internal Waldo_MG_fnc_* runtime functions itself; only this installer is a
            // CfgFunctions entry.
            class MiniGamesInit {
                file = "MissionScripts\MiniGames\miniGamesInit.sqf";
            };
        };
        class InteractionMiniGames
        {
            // Diegetic field-equipment procedures. Public Waldo_fnc_MiniGame* names remain
            // unchanged so existing mission integrations continue to work.
            class MiniGameRegisterChallenge {
                file = "MissionScripts\InteractionsMinigames\Core\registerChallenge.sqf";
            };
            class MiniGameChallenge {
                file = "MissionScripts\InteractionsMinigames\Core\miniGameChallenge.sqf";
            };
            class MiniGameChallengeResolve {
                file = "MissionScripts\InteractionsMinigames\Core\miniGameChallengeResolve.sqf";
            };
            class MiniGameChallengeUI {
                file = "MissionScripts\InteractionsMinigames\Core\challengeUi.sqf";
            };
            class MiniGameEquipmentRect {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentRect.sqf";
            };
            class MiniGameEquipmentCreateControl {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentCreateControl.sqf";
            };
            class MiniGameEquipmentSetPosition {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentSetPosition.sqf";
            };
            class MiniGameEquipmentPolyline {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentPolyline.sqf";
            };
            class MiniGameEquipmentFitText {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentFitText.sqf";
            };
            class MiniGameEquipmentFitStructuredText {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentFitStructuredText.sqf";
            };
            class MiniGameEquipmentBindDrag {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentBindDrag.sqf";
            };
            class MiniGameEquipmentAddDisplayHandler {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentAddDisplayHandler.sqf";
            };
            class MiniGameEquipmentCleanup {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentCleanup.sqf";
            };
            class MiniGameEquipmentValidateDisplay {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentValidateDisplay.sqf";
            };
            class MiniGameEquipmentPreviewState {
                file = "MissionScripts\InteractionsMinigames\Core\equipmentPreviewState.sqf";
            };
            class MiniGameChallengeHelp {
                file = "MissionScripts\InteractionsMinigames\Core\challengeHelp.sqf";
            };
            class MiniGameAccessibility {
                file = "MissionScripts\InteractionsMinigames\Core\accessibility.sqf";
            };
            class MiniGameApplyAccessibility {
                file = "MissionScripts\InteractionsMinigames\Core\applyAccessibility.sqf";
            };
            class MiniGameEquipmentProfile {
                file = "MissionScripts\InteractionsMinigames\Themes\equipmentProfile.sqf";
            };
            class MiniGameEquipmentDifficultyConfig {
                file = "MissionScripts\InteractionsMinigames\Themes\equipmentDifficultyConfig.sqf";
            };
            class MiniGameEquipmentDecorate {
                file = "MissionScripts\InteractionsMinigames\Equipment\equipmentDecorate.sqf";
            };
            class MiniGameEquipmentBriefing {
                file = "MissionScripts\InteractionsMinigames\Equipment\equipmentBriefing.sqf";
            };
            class MiniGameInteraction {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteraction.sqf";
            };
            class MiniGameInteractionActivate {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionActivate.sqf";
            };
            class MiniGameInteractionRange {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionRange.sqf";
            };
            class MiniGameInteractionNotifyClient {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionNotifyClient.sqf";
            };
            class MiniGameInteractionAcquireServer {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionAcquireServer.sqf";
            };
            class MiniGameInteractionStartClient {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionStartClient.sqf";
            };
            class MiniGameInteractionResolveServer {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionResolveServer.sqf";
            };
            class MiniGameInteractionGetState {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionGetState.sqf";
            };
            class MiniGameInteractionStateIs {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionStateIs.sqf";
            };
            class MiniGameInteractionGetResult {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionGetResult.sqf";
            };
            class MiniGameInteractionGetDiagnostics {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionGetDiagnostics.sqf";
            };
            class MiniGameInteractionReset {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionReset.sqf";
            };
            class MiniGameInteractionSetup {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionSetup.sqf";
            };
            class MiniGameInteractionTableSetup {
                file = "MissionScripts\InteractionsMinigames\Integration\miniGameInteractionTableSetup.sqf";
            };
            class MiniGameEquipmentPicker {
                file = "MissionScripts\InteractionsMinigames\Integration\equipmentPicker.sqf";
            };
            class MiniGameEquipmentGallery {
                file = "MissionScripts\InteractionsMinigames\Integration\equipmentGallery.sqf";
            };
            class BombDefuseSetup {
                file = "MissionScripts\InteractionsMinigames\Integration\bombDefuseSetup.sqf";
            };
            // Built-in interaction challenges.
            class MiniGameWireCut {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeWireCut.sqf";
            };
            class MiniGameMinesweeper {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeMinesweeper.sqf";
            };
            class MiniGameKeypad {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeKeypad.sqf";
            };
            class MiniGameLockpick {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeLockpick.sqf";
            };
            class MiniGameCircuit {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeCircuit.sqf";
            };
            class MiniGameRepair {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeRepair.sqf";
            };
            class MiniGameRadioTune {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeRadioTune.sqf";
            };
            class MiniGamePressure {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengePressure.sqf";
            };
            class MiniGameSequence {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeSequence.sqf";
            };
            class MiniGameCommandInput {
                file = "MissionScripts\InteractionsMinigames\Challenges\challengeCommandInput.sqf";
            };
        };
        class CorpseTraps
        {
            class CorpseTrapInit {
                file = "MissionScripts\CorpseTraps\corpseTrapInit.sqf";
            };
            class CorpseTrapGetThrowables {
                file = "MissionScripts\CorpseTraps\corpseTrapGetThrowables.sqf";
            };
            class CorpseTrapPlant {
                file = "MissionScripts\CorpseTraps\corpseTrapPlant.sqf";
            };
            class CorpseTrapArmServer {
                file = "MissionScripts\CorpseTraps\corpseTrapArmServer.sqf";
            };
            class CorpseTrapRefund {
                file = "MissionScripts\CorpseTraps\corpseTrapRefund.sqf";
            };
            class CorpseTrapInstallInventoryHandler {
                file = "MissionScripts\CorpseTraps\corpseTrapInstallInventoryHandler.sqf";
            };
            class CorpseTrapTriggerServer {
                file = "MissionScripts\CorpseTraps\corpseTrapTriggerServer.sqf";
            };
        };
    };
};
