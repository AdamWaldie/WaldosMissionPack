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
                file = "MissionScripts\ACRE2Init.sqf";
            };
            class AITweak {
                file = "MissionScripts\AISkillAdjustmentSystem.sqf";
            };
            class UnFlipping {
                file = "MissionScripts\flipAction.sqf";
            };
        };
        class Loadout
		{
            class SaveLoadout {
                file = "MissionScripts\saveRespawnLoadout.sqf";
            };
            class SpawnLogisticsBox {
                file = "MissionScripts\LogiBoxes.sqf";
            };
            class SetupQuarterMaster {
                file = "MissionScripts\initQuartermaster.sqf";
            };
		};
        class convoy 
        {
            class SimpleAiConvoy {
                file =  "MissionScripts\simpleAiConvoy.sqf";
            };
        };
        class teleport
        {
            class Teleport {
                file =  "MissionScripts\teleport.sqf";
            };
        };
        class MissionEnding 
        {
            class ENDEX {
                file = "MissionScripts\ENDEX.sqf";
            };
        };
        class Flourish 
        {
            class InfoText {
                file = "MissionScripts\infoText.sqf";
            };
        };
        class DebugToolKit {
            class ToolkitAceLimitedArsenal {
                file = "MissionScripts\ToolkitAceLimitedArsenal.sqf";
            };
        }
        class ZenModules {
            class ZenInit {
                file = "MissionScripts\ZenModules\Zen_initModules.sqf";
            };
            class CreateSupplyCrate {
                file = "MissionScripts\ZenModules\Zen_supplyCrateModule.sqf";
            };
            class SupplyCratePopulate {
                file = "MissionScripts\ZenModules\Zen_Support_CratePopulate.sqf";
            };
            class CreateCCPCrate {
                file = "MissionScripts\ZenModules\Zen_medicalCrateModule.sqf";
            };
            class MedicalCratePopulate {
                file = "MissionScripts\ZenModules\Zen_Medical_CratePopulate.sqf";
            };
        };
	};
};