/*
 * Author: WaldoTheWarfighter
 * Commands a paradrop aircraft's own recognised door/ramp animation open or closed, so the
 * static-line/HALO "ramp/door open" requirement (checkForJumpSettings.sqf, addStaticJump.sqf,
 * addHaloJump.sqf) can actually be satisfied. That requirement previously depended entirely on the
 * airframe having its own player-facing action wired to the animation - true for the small curated
 * vanilla list this feature shipped with, but no longer a safe assumption now that
 * Waldo_fnc_ResolveVehicleClassPool extends the airframe pool with any live-modset cargo aircraft:
 * plenty of those recognise one of these sources in config (so the requirement stays active) without
 * ever exposing a way for a player or the AI pilot to actually open it, leaving the jump action
 * permanently unavailable. Waldo_fnc_ParadropBuildFlightRoute calls this directly as the aircraft
 * nears the drop run instead of relying on the airframe's own action.
 *
 * Uses the exact same recognised-source list the requirement check reads, split by which live SQF
 * command each kind of source actually accepts - an unrecognised selection/source/door name is
 * silently ignored by the engine, so it is safe to issue all of them unconditionally rather than
 * re-deriving which ones a specific airframe actually has:
 *  - animate covers every source read back via animationPhase (ramp_bottom, door_2_1, door_2_2,
 *    jumpdoor_1, jumpdoor_2, back_ramp_switch, back_ramp_half_switch).
 *  - animateSource covers the one source read back via animationSourcePhase (ramp_anim).
 *  - animateDoor covers the two Doors-class components read back via doorPhase (RearDoors,
 *    Door_1_source). animateDoor's phase argument is a NUMBER (0..1), the same as animate/
 *    animateSource - it does not accept the "OPEN"/"CLOSE" strings some standalone door scripts use.
 *
 * Arguments:
 * 0: aircraft <OBJECT>
 * 1: open <BOOL> (default true) - true opens every recognised source, false closes them.
 *
 * Return Value:
 * Nothing.
 *
 * Current callers: the door-watcher spawned by Waldo_fnc_ParadropQuickFlightSetup and
 * Waldo_fnc_ParadropCreateDropZone, both server-only (the aircraft is server-owned in both flows).
 *
 * Example:
 * [_aircraft, true] call Waldo_fnc_ParadropOperateDoor;
 */

params [["_aircraft", objNull, [objNull]], ["_open", true, [true]]];
if (isNull _aircraft) exitWith {};

private _phase = if (_open) then {1} else {0};
{
    _aircraft animate [_x, _phase];
} forEach ["ramp_bottom", "door_2_1", "door_2_2", "jumpdoor_1", "jumpdoor_2", "back_ramp_switch", "back_ramp_half_switch"];
_aircraft animateSource ["ramp_anim", _phase];
{
    _aircraft animateDoor [_x, _phase];
} forEach ["RearDoors", "Door_1_source"];
