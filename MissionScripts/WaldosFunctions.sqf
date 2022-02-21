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
                file =  "MissionScripts\Logistics\teleport.sqf";
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
        class ZenModules {
            class ZenInit {
                file = "MissionScripts\ZenModules\Zen_initModules.sqf";
            };
            class CreateSupplyCrate {
                file = "MissionScripts\ZenModules\Zen_supplyCrateModule.sqf";
            };
            class CreateCCPCrate {
                file = "MissionScripts\ZenModules\Zen_medicalCrateModule.sqf";
            };
        };
        class Logistics {
            class MedicalCratePopulate {
                file = "MissionScripts\Logistics\doMedicalCrate.sqf";
            };
            class SupplyCratePopulate {
                file = "MissionScripts\Logistics\doSupplyCrate.sqf";
            };
            class SaveLoadout {
                file = "MissionScripts\Logistics\saveRespawnLoadout.sqf";
            };
            class SpawnLogisticsBox {
                file = "MissionScripts\Logistics\LogiBoxes.sqf";
            };
            class SetupQuarterMaster {
                file = "MissionScripts\Logistics\initQuartermaster.sqf";
            };
            class UnFlipping {
                file = "MissionScripts\Logistics\flipAction.sqf";
            };
        };
	};
};