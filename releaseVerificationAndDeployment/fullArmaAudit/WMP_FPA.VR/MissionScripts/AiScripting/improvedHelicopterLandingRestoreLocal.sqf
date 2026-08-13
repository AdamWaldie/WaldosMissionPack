/*
 * Author: WaldoTheWarfighter
 * Releases WMP vector-flight control and restores only the AI systems changed during an approach.
 * A normal airborne abort does not impose a new flight height: the current waypoint/Zeus order is
 * allowed to resume with the aircraft's existing altitude policy. A ground anchor is different
 * because it deliberately used forced height zero; only that path receives a safe, non-forced
 * release height. This prevents moved waypoints and newly grouped formations being driven down to
 * the old 30 metre landing-transit value. Cleanup is safe after landing, cancellation, locality
 * migration, pilot takeover or feature stop.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 * 1: landed successfully <BOOL> (default false)
 * 2: waypoint type <STRING> (default "")
 * 3: stabilise airborne handoff <BOOL> (default false) - removes only downward velocity left by
 *    WMP when formation/group control supersedes an active approach.
 *
 * Return Value: BOOL - true when a local living helicopter was restored.
 *
 * Example: [_helicopter, true, "GETOUT"] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
 * Current callers: the landing controller and local tracker cleanup.
 */

params [
    ["_helicopter", objNull, [objNull]],
    ["_landed", false, [true]],
    ["_waypointType", "", [""]],
    ["_stabiliseAirborne", false, [true]]
];
if (isNull _helicopter) exitWith {false};
if (!local _helicopter) exitWith {false};
// Invalidate the exact scheduled approach/anchor that previously owned the aircraft. A Boolean
// alone is insufficient because a rapid retask can set it true for a new controller before the old
// scheduled loop notices the intervening false state.
_helicopter setVariable [
    "Waldo_ImprovedHelicopterLanding_ControlRevision",
    (_helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ControlRevision", 0]) + 1,
    true
];
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_Active", false, true];
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", false];
private _wasGroundAnchored = _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false];
private _releaseHeight = _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_ReleaseHeight", 100];
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GroundAnchored", false, true];
if (!alive _helicopter) exitWith {false};
_helicopter enableAI "MOVE";
_helicopter enableAI "PATH";
private _pilot = currentPilot _helicopter;
if (!isNull _pilot) then {_pilot enableAI "FSM";};
if (_landed) then {
    _helicopter setVelocity [0, 0, 0];
    _helicopter land "LAND";
    if (toUpperANSI _waypointType == "GETOUT") then {_helicopter engineOn false;};
} else {
    _helicopter land "NONE";
    if (_stabiliseAirborne && {!isTouchingGround _helicopter}) then {
        private _velocity = velocity _helicopter;
        // The vector controller may have issued a strong descent immediately before Zeus grouped
        // the aircraft. Arma formation control does not reliably arrest that inherited velocity in
        // time. Preserve horizontal flight and any climb, but remove WMP's residual dive.
        _helicopter setVelocity [_velocity select 0, _velocity select 1, (_velocity select 2) max 0];
    };
    if (
        _wasGroundAnchored
        && {!isNull _pilot}
        && {!isPlayer _pilot}
        && {isNull (remoteControlled _pilot)}
        && {isEngineOn _helicopter}
    ) then {
        // The anchor used forced height zero, which must be replaced before a new route can take
        // effect. Use the pre-approach height without forcing it: vanilla collision avoidance and
        // formation spacing retain priority after WMP releases ownership.
        _helicopter flyInHeight ((_releaseHeight max 20) min 500);
    };
};
true
