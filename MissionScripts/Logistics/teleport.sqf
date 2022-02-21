/*
Usage:

Put the following in the object you use to teleport from.

Ensure variable name has been assigned to both the interactable object, and the destination object.

this addAction ['Teleport To (ReplaceMe)',Waldo_fnc_Teleport,[DestinationName]];

*/
// Get the destination.

private ["_dest"];

_dest = (_this select 3) select 0;

if (alive _dest && !(isNull _dest)) then
{
    3 fadeSound 0;
    cutText["A few minutes later...","BLACK OUT",3];
    sleep 3;
    player  setPos [(getPos _dest  select 0) + 3 , (getPos _dest select 1) + 3, getPos _dest select 2];
    cutText["A few minutes later...","BLACK IN",5];
    2 fadeSound 1;
}
else
{
    hint "Respawn is currently not available.";
};