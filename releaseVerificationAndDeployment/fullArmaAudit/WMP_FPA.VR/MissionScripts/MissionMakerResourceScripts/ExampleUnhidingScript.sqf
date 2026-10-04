/*
 * Author: WaldoTheWarfighter
 * Purpose: Mission-maker example that reveals and enables simulation for named groups
 * (the inverse of hiding them at mission start). Mission-specific example; safe to delete.
 *
 * Locality and authority: Run from a server-owned trigger or script because hideObjectGlobal
 * and enableSimulationGlobal change shared world state.
 * Repeat/JIP: No explicit replay or guard. Repeating the reveal is unnecessary; adapt the
 * mission's trigger and late-join state before using this template in live play.
 * Arguments: None. Replace the shipped Attack1... Group variables in this file.
 * Return Value: Nothing; execVM returns an Arma Script handle immediately.
 * Current callers: Mission-maker trigger or server script after adapting the group references.
 * Example: [] execVM "MissionScripts\MissionMakerResourceScripts\ExampleUnhidingScript.sqf";
 * Result: Existing members and vehicles of the named groups become visible and simulated.
 */

//Wave1 - specific to this mission file so you can safely ignore and delete this

//This just iterates through each unit in the group name e.g. Attack1HunterVehicleAlphaCrew and enables their simulaton and model for the vehicle & units.
{
    private _vehicle = vehicle _x;
    _x hideObjectGlobal false;
    _x enableSimulationGlobal true;
    _vehicle hideObjectGlobal false;
    _vehicle enableSimulationGlobal true;
} forEach (units Attack1HunterVehicleAlphaCrew);

{
    private _vehicle = vehicle _x;
    _x hideObjectGlobal false;
    _x enableSimulationGlobal true;
    _vehicle hideObjectGlobal false;
    _vehicle enableSimulationGlobal true;
} forEach (units Attack1HunterAlpha);

{
    private _vehicle = vehicle _x;
    _x hideObjectGlobal false;
    _x enableSimulationGlobal true;
    _vehicle hideObjectGlobal false;
    _vehicle enableSimulationGlobal true;
} forEach (units Attack1HunterBravo);

{
    private _vehicle = vehicle _x;
    _x hideObjectGlobal false;
    _x enableSimulationGlobal true;
    _vehicle hideObjectGlobal false;
    _vehicle enableSimulationGlobal true;
} forEach (units Attack1CreeperAlpha);

{
    private _vehicle = vehicle _x;
    _x hideObjectGlobal false;
    _x enableSimulationGlobal true;
    _vehicle hideObjectGlobal false;
    _vehicle enableSimulationGlobal true;
} forEach (units Attack1CreeperBravo);
