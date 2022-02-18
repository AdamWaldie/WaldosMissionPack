//Lighting Setup Engine
"LightShafts" ppEffectAdjust [0.9, 0.8, 0.9, 0.8];

//Include & Execute mission parameter file
#include "missionParameters.sqf";

//=============================================================================================

////    VEHICLE FLIPPING SCRIPT    ////========================================================
// Works fine as is, does not need any editing so I advise not touching.
// Calls "FlipAction.sqf" if vehicle tips over. Adds action on init, and an event handler to handle on player respawn.

if (!isDedicated) then {
 waitUntil {!isNull player && {time > 0}};

player addAction [
	"Flip Vehicle", 
	"MissionScripts\flipAction.sqf", 
	[], 
	0, 
	false, 
	true, 
	"", 
	"_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
];
Player AddEventHandler ["Respawn", {
	(_this select 0) addAction [
		"Flip Vehicle", 
		"MissionScripts\flipAction.sqf", 
		[], 
		0, 
		false, 
		true, 
		"", 
		"_this == (vehicle _target) && {(count nearestObjects [_target, ['landVehicle'], 5]) > 0 && {(vectorUp cursorTarget) select 2 < 0}}"
	];
}];
};

//=============================================================================================