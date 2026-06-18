/*
 * Mission-maker example - reveals and enables simulation for the units/vehicles of a named group
 * (the inverse of hiding them at mission start). Mission-specific example; safe to delete.
 *
 * Arguments:
 * None (edit the group references inside to match your mission)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] execVM "MissionScripts\MissionMakerResourceScripts\ExampleUnhidingScript.sqf";
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