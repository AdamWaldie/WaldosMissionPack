/*
Purpose: Simple AI Convoy script for mission makers
Called From: sqf file, trigger, init field or whatever you fancy
Scope: Groups of units referanced
Execution time: from handle call.
Author: Tova, modifed by Adam Waldie
License: unlimited distribution and editing as per Tova's original.

Call it with:

convoyScript = [convoyGroup] spawn Waldo_fnc_SimpleAiConvoy;


Optional parameters are also available :

convoyScript = [convoyGroup, convoySpeed, convoySeparation, pushThrough] spawn Waldo_fnc_SimpleAiConvoy;

if there are multiple, simply change the "handle":


convoyScript_2 = [convoyGroup, convoySpeed, convoySeparation, pushThrough] spawn Waldo_fnc_SimpleAiConvoy;


With :

convoyGroup : the group you want to move as a convoy
convoySpeed : Maximum speed of the convoy in km/h (default 50 km/h)
convoySeparation : distance between each vehicle of the convoy (default 50m)
pushThrough : true/false, force the AI to push through contact, only returning fire on the move (default true)



To end the script, in its final waypoint place the below in on activation:

terminate convoyScript;
{(vehicle _x) limitSpeed 5000;(vehicle _x) setUnloadInCombat [true, false]} forEach (units convoyGroup);
convoyGroup enableAttack true;

*/
params ["_convoyGroup",["_convoySpeed",30],["_convoySeparation",15],["_pushThrough", true]];
if (_pushThrough) then {
	_convoyGroup enableAttack !(_pushThrough);
	{(vehicle _x) setUnloadInCombat [false, false];} forEach (units _convoyGroup);
};
_convoyGroup setFormation "COLUMN";
{
	(vehicle _x) limitSpeed _convoySpeed*1.15;
	(vehicle _x) setConvoySeparation _convoySeparation;
} forEach (units _convoyGroup);
(vehicle leader _convoyGroup) limitSpeed _convoySpeed;
while {sleep 5; !isNull _convoyGroup} do {
	{
		if ((speed vehicle _x < 5) && (_pushThrough || (behaviour _x != "COMBAT"))) then {
			(vehicle _x) doFollow (leader _convoyGroup);
		};	
	} forEach (units _convoyGroup)-(crew (vehicle (leader _convoyGroup)))-allPlayers;
	{(vehicle _x) setConvoySeparation _convoySeparation;} forEach (units _convoyGroup);
}; 