/*
 * Author: WaldoTheWarfighter
 * Validates and broadcasts live improved-helicopter-landing settings. Remote changes require an
 * assigned curator. Connected machines receive one ordered payload before the event-driven handler
 * is initialised; the server's durable values are included in the normal JIP runtime snapshot.
 *
 * Arguments:
 * 0: settings <ARRAY> - enabled, minimum distance, transit altitude, glideslope ratio, tree radius,
 *    tree buffer, go-around height, maximum climb, maximum descent, maximum go-arounds and
 *    touchdown settling delay.
 *
 * Return Value: BOOL - true when accepted.
 *
 * Example: [[true, 50, 30, 4, 25, 5, 150, 8, 10, 1, 8]] call Waldo_fnc_ImprovedHelicopterLandingConfigureServer;
 * Current callers: mission scripts that intentionally change the live global landing profile.
 */

params [["_settings", [], [[]]]];
if (!isServer) exitWith {[_settings] remoteExecCall ["Waldo_fnc_ImprovedHelicopterLandingConfigureServer", 2]; false};
if (remoteExecutedOwner > 0) then {
    private _index = allPlayers findIf {owner _x == remoteExecutedOwner};
    private _caller = if (_index >= 0) then {allPlayers select _index} else {objNull};
    if (isNull _caller || {isNull getAssignedCuratorLogic _caller}) exitWith {false};
};
if (count _settings < 11) exitWith {false};
_settings params ["_enabled", "_minimumDistance", "_transitAltitude", "_glideRatio", "_treeRadius", "_treeBuffer", "_goAroundHeight", "_maxClimb", "_maxDescent", "_maxGoArounds", "_touchdownHold"];
private _updates = [
    ["Waldo_ImprovedHelicopterLanding_Enable", _enabled],
    ["Waldo_ImprovedHelicopterLanding_MinimumActivationDistance", (_minimumDistance max 50) min 500],
    ["Waldo_ImprovedHelicopterLanding_TransitAltitude", (_transitAltitude max 15) min 150],
    ["Waldo_ImprovedHelicopterLanding_GlideSlopeRatio", (_glideRatio max 2) min 10],
    ["Waldo_ImprovedHelicopterLanding_TreeScanRadius", (_treeRadius max 0) min 75],
    ["Waldo_ImprovedHelicopterLanding_TreeSafetyBuffer", (_treeBuffer max 0) min 25],
    ["Waldo_ImprovedHelicopterLanding_GoAroundHeight", (_goAroundHeight max 50) min 500],
    ["Waldo_ImprovedHelicopterLanding_MaximumClimbRate", (_maxClimb max 1) min 20],
    ["Waldo_ImprovedHelicopterLanding_MaximumDescentRate", (_maxDescent max 1) min 25],
    ["Waldo_ImprovedHelicopterLanding_MaximumGoArounds", round ((_maxGoArounds max 0) min 3)],
    ["Waldo_ImprovedHelicopterLanding_TouchdownHoldSeconds", (_touchdownHold max 0) min 60]
];
{_x params ["_name", "_value"]; missionNamespace setVariable [_name, _value, true];} forEach _updates;
[_updates, false] remoteExecCall ["Waldo_fnc_FeatureRuntimeReceiveState", -2];
[] call Waldo_fnc_ImprovedHelicopterLandingInit;
[] remoteExecCall ["Waldo_fnc_ImprovedHelicopterLandingInit", -2];
diag_log format ["[WMP AI LANDING] Runtime configuration applied enabled=%1", _enabled];
true
