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
		class missionSetup 
        {
            class ACRE2Init {
                file = "MissionScripts\MissionFlow\ACRE2Init.sqf";
            };
            class AITweak {
                file = "MissionScripts\AiScripting\AISkillAdjustmentSystem.sqf";
            };
        };
        class convoy 
        {
            class SimpleAiConvoy {
                file =  "MissionScripts\AiScripting\simpleAiConvoy.sqf";
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
                file = "MissionScripts\MissionFlow\ENDEX.sqf";
            };
        };
        class TitleScreeen 
        {
            class InfoText {
                file = "MissionScripts\MissionFlow\infoText.sqf";
            };
        };
        class DebugToolKit {
            class ToolkitAceLimitedArsenal {
                file = "MissionScripts\MissionMakerResourceScripts\ToolkitAceLimitedArsenal.sqf";
            };
        }
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
        };
        class MHQ {
            class ServerSetupMHQ {
                file = "MissionScripts\Logistics\MHQ\ServerSetupMHQ.sqf";
            };
            class SetupMHQActions {
                file = "MissionScripts\Logistics\MHQ\SetupMHQActions.sqf";
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
	};
};