/*
 * Mission-maker debug helper - logs every CfgPatches addon class name to the RPT to help identify
 * which addon a class belongs to. Not used by the pack; safe to delete. Run with execVM.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] execVM "MissionScripts\MissionMakerResourceScripts\DEBUG_GetNameOfModConfigPatch.sqf";
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