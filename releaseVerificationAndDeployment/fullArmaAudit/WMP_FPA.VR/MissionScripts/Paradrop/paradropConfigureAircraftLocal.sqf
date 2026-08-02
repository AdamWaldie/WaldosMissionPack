/*
 * Author: WaldoTheWarfighter
 * Applies one dynamic paradrop operation's selected static-line and HALO capabilities to its
 * aircraft on each interface. The single JIP-replayed call keeps both jump actions and the ACE
 * settings summary together, while the individual installers reconcile repeated configuration.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 * 1: configuration <HASHMAP> - staticJumpEnabled, staticMinimumAltitude,
 *    staticMaximumAltitude, staticMaximumSpeed, staticChuteClass, haloJumpEnabled,
 *    haloMinimumAltitude, haloBackpackClass and requireOpenDoor
 *
 * Return Value:
 * Boolean - true when a valid local aircraft configuration was processed.
 *
 * Called by:
 * Waldo_fnc_ParadropCreateDropZone through a global object-keyed JIP remote execution.
 *
 * Example:
 * [_aircraft, _config] call Waldo_fnc_ParadropConfigureAircraftLocal;
 */

params [
    ["_aircraft", objNull, [objNull]],
    ["_config", createHashMap, [createHashMap]]
];

if (!hasInterface || {isNull _aircraft}) exitWith {false};

[
    _aircraft,
    _config getOrDefault ["staticMinimumAltitude", 180],
    _config getOrDefault ["staticMaximumAltitude", 350],
    _config getOrDefault ["staticMaximumSpeed", 310],
    _config getOrDefault ["staticChuteClass", "NonSteerable_Parachute_F"],
    _config getOrDefault ["requireOpenDoor", false],
    _config getOrDefault ["staticJumpEnabled", true]
] call Waldo_fnc_AddStaticJump;

[
    _aircraft,
    _config getOrDefault ["haloMinimumAltitude", 1000],
    _config getOrDefault ["haloBackpackClass", "B_Parachute"],
    _config getOrDefault ["requireOpenDoor", false],
    _config getOrDefault ["haloJumpEnabled", false]
] call Waldo_fnc_AddHaloJump;

[_aircraft] call Waldo_fnc_JumpSettingsCheck;
true
