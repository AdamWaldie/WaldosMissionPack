/* Function Assignment file - called from description.ext
Creates Arma function based on the files provided. Allowing for a traditional Alias function call.
in this case all of waldos missionscripts can now be called via the following:
Waldos_fnc_LowestClass

e.g. 

Waldo_fnc_ACRE2Init as an Alias for calling the longhand script
Waldo_fnc_AITweak as an Alias for calling the longhand script

*/
class CfgFunctions
{
	class Waldo
	{
		class InitilisationAndSetup 
        {
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
        class ACRE2Setup {
            class ACRE2Init {
                file = "MissionScripts\MissionInit\ACRE2\ACRE2Init.sqf";
            };
            class ACRE2Init_Legacy {
                file = "MissionScripts\MissionInit\ACRE2\ACRE2Init_Legacy.sqf";
            };
            class SquadLevelRadios {
                file = "MissionScripts\MissionInit\ACRE2\ACRE2SquadLevelRadios.sqf";
            };
            class GetSRChannelName {
                file = "MissionScripts\MissionInit\ACRE2\GetSRChannelName.sqf";
            };
            class CreateACRECEOI {
                file = "MissionScripts\MissionInit\ACRE2\CreateACRECEOI.sqf";
            };
            class BabelActivation {
                file = "MissionScripts\MissionInit\ACRE2\BabelActivation.sqf";
            };
        };
        class AI 
        {
            class SimpleAiConvoy {
                file =  "MissionScripts\AiScripting\simpleAiConvoy.sqf";
            };
            class AITweak {
                file = "MissionScripts\AiScripting\AISkillAdjustmentSystem.sqf";
            };
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
            class MedicalCratePopulate_Legacy {
                file = "MissionScripts\Logistics\Crates\doMedicalCrate_Legacy.sqf";
            };
            class SupplyCratePopulate_Legacy {
                file = "MissionScripts\Logistics\Crates\doSupplyCrate_Legacy.sqf";
            };
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
        };
        class MHQ {
            class MHQSetup {
                file = "MissionScripts\Logistics\MHQ\MHQSetup.sqf";
            };
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
        };
        class VehicleSetup {
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
            class VVDVehicleDamage {
                file = "MissionScripts\Logistics\VirtualVehicleDepot\VVDVehicleDamage.sqf";
            };
        };
	};
};