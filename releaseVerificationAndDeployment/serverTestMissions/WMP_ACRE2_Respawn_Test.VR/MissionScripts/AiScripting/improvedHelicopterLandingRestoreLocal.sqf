/*
 * Author: WaldoTheWarfighter
 * Releases WMP vector-flight control and restores the AI systems changed during an approach.
 * Cleanup is safe after landing, cancellation, locality migration, pilot takeover or feature stop.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 * 1: landed successfully <BOOL> (default false)
 * 2: waypoint type <STRING> (default "")
 *
 * Return Value: BOOL - true when a local living helicopter was restored.
 *
 * Example: [_helicopter, true, "GETOUT"] call Waldo_fnc_ImprovedHelicopterLandingRestoreLocal;
 * Current callers: the landing controller and local tracker cleanup.
 */

params [
    ["_helicopter", objNull, [objNull]],
    ["_landed", false, [true]],
    ["_waypointType", "", [""]]
];
if (isNull _helicopter) exitWith {false};
if (!local _helicopter) exitWith {false};
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_Active", false, true];
_helicopter setVariable ["Waldo_ImprovedHelicopterLanding_GearLocal", false];
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
    if (!isNull _pilot && {!isPlayer _pilot} && {isNull (remoteControlled _pilot)} && {isEngineOn _helicopter}) then {
        _helicopter flyInHeight ((missionNamespace getVariable ["Waldo_ImprovedHelicopterLanding_TransitAltitude", 30]) max 15);
    };
};
true
