/*
 * Author: WaldoTheWarfighter
 * Purpose: Mission-maker debug helper that logs every CfgPatches addon class name to the RPT to help identify
 * which addon a class belongs to. Not used by the pack; safe to delete. Run with execVM.
 *
 * Locality and authority: Runs on the executing machine and writes its local RPT.
 * Repeat/JIP: Each call logs the catalogue again. No public state or JIP replay.
 * Arguments: None. Reads configFile >> "CfgPatches" on the executing machine.
 * Return Value: Nothing; execVM returns an Arma Script handle immediately.
 * Current callers: Manual mission-maker debug console only.
 * Example: [] execVM "MissionScripts\MissionMakerResourceScripts\DEBUG_GetNameOfModConfigPatch.sqf";
 * Result: Each loaded CfgPatches class is written to the executing machine's RPT.
 */

//If you dont know what this is, you can safely delete it. It will bloat your mission file otherwise

for "_i" from 0 to (count (configFile / "CfgPatches") - 1) do 
{
_cfg_entry = (configFile / "CfgPatches") select _i;

if (isClass _cfg_entry) then
{
    diag_log format ["%1", _cfg_entry];
};
};
