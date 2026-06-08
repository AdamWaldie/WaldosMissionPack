_Associated Files:_
* _MissionScripts\VehicleActionsSetup_
* _MissionScripts\Paradrop_

The following actions are available:
* Static Line Parachuting and Halo Jumping
* Player Dismount Side Selection for two-door helicopters (E.g UH-60)
* Set ACE Cargo and movement settings for an object.

CUP, RHS and Vanilla assets have these automatically applied by default, as well as preliminary support for medical class vehicles from any mod. As such if you are using these mods, you don't need to do anything else.

## Set Cargo Attributes
Associated Files: MissionScripts\VehicleActionsSetup\SetCargoAttributes.sqf

This function allows you to set the cargo space and size of the given object and if you can drag or carry it.

Arguments:
* 0: Vehicle       <OBJECT>
* 1: Cargo Space   <NUMBER> (nil to keep default value)
* 2: Cargo Size    <NUMBER> (nil to keep default value) 
* 3: Draggable     <BOOLEAN> (Default; true)
* 4: Carryable     <BOOLEAN> (Default; true)

Example:
* `[myTruck] call Waldo_fnc_SetCargoAttributes;`
* `[myTruck, 30, -1] call Waldo_fnc_SetCargoAttributes;`
* `[myCrate, -1, 2] call Waldo_fnc_SetCargoAttributes;`
* `[myCrate, -1, 2, true, false] call Waldo_fnc_SetCargoAttributes;`
* `[myCrate, nil, nil, true, false] call Waldo_fnc_SetCargoAttributes;`

## Exit Side Selection
Associated Files: MissionScripts\VehicleActionsSetup\AddExitAction.sqf

This function adds two addictions available for players in passenger positions to choose whether to exit to the left or right of the vehicle. Mission Makers should only attempt to apply this to helicopters with two side doors for expected results.

Arguments:
* 0: Object <OBJECT>
* 1: Color Action <BOOL>

Example:
* `[this] call Waldo_fnc_AddExitActions;`
* `[this, true] call Waldo_fnc_AddExitActions;`

## Paradrop/HALO Setup
Associated Files: MissionScripts\Paradrop

This is only required if the vehicle is not already set up by the pack during init.

For the default setup, simply paste the below code into the init of the drop vehicle.

`[this] call Waldo_fnc_VehicleJumpSetup;`

You can also customise the parameters for all jump aircraft in the initServer.sqf Pictured below:

![Plane Parameters](https://i.imgur.com/qrayy7a.png)

Static Line:

* **WALDO_STATIC_MINALTITUDE** is the minimum altitude the plane must exceed to perform a static line jump.
* **WALDO_STATIC_MAXALTITUDE** is the maximum altitude the plane must not exceed to perform a static line jump.
* **WALDO_STATIC_MAXSPEED** is the maximum vehicle speed before the static line becomes unavailable.
* **WALDO_STATIC_STATICCHUTE** is the class name of the chute you wish to use for static line jumps.

HALO:
* **WALDO_PARA_HALOALTITUDE** is the minimum altitude the plane must exceed to perform a HALO jump.
* **WALDO_PARA_HALOCHUTE** is the class name of the chute you wish to use for HALO jumps.
