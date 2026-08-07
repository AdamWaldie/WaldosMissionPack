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
 *    haloMinimumAltitude, haloBackpackClass and requireOpenDoor. Both current callers
 *    (Waldo_fnc_ParadropQuickFlightSetup, Waldo_fnc_ParadropCreateDropZone) always resolve and
 *    normalize every threshold/class before calling this, so the getOrDefault fallbacks below are a
 *    last-resort safety net for a direct/incomplete call, not something either caller relies on -
 *    they still prefer the mission's own configured WALDO_STATIC_/WALDO_PARA_ defaults over the
 *    shipped vanilla literals, for the same reason those callers do.
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
    _config getOrDefault ["staticMinimumAltitude", missionNamespace getVariable ["WALDO_STATIC_MINALTITUDE", 180]],
    _config getOrDefault ["staticMaximumAltitude", missionNamespace getVariable ["WALDO_STATIC_MAXALTITUDE", 350]],
    _config getOrDefault ["staticMaximumSpeed", missionNamespace getVariable ["WALDO_STATIC_MAXSPEED", 310]],
    _config getOrDefault ["staticChuteClass", missionNamespace getVariable ["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F"]],
    _config getOrDefault ["requireOpenDoor", true],
    _config getOrDefault ["staticJumpEnabled", true]
] call Waldo_fnc_AddStaticJump;

[
    _aircraft,
    _config getOrDefault ["haloMinimumAltitude", missionNamespace getVariable ["WALDO_PARA_HALOALTITUDE", 1000]],
    _config getOrDefault ["haloBackpackClass", missionNamespace getVariable ["WALDO_PARA_HALOCHUTE", "B_Parachute"]],
    _config getOrDefault ["requireOpenDoor", true],
    _config getOrDefault ["haloJumpEnabled", false]
] call Waldo_fnc_AddHaloJump;

[_aircraft] call Waldo_fnc_JumpSettingsCheck;
true
