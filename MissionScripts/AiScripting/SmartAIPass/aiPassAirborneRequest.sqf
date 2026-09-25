/*
 * Author: WaldoTheWarfighter
 * Calls in an airborne reinforcement: a WMP Dynamic Paradrop aircraft drops a squad near a position,
 * and once the squad is on the ground it is released to fight under the Smart AI Pass.
 *
 * PROTOCOL Airborne's idea, rebuilt on WMP's own paradrop system instead of its faulty filters and
 * backpack replacement (which dropped jumpers' backpacks under the aircraft). Three ways to use it:
 * - a trigger (e.g. "OPFOR detected by BLUFOR", server only):
 *   [thisTrigger, east] call Waldo_fnc_AIPassAirborneRequest;
 * - a script, with a position and options;
 * - automatically, when a squad in contact finds no ground responders and Waldo_AIPass_Airborne_Auto
 *   is on (Waldo_fnc_AIPassReinforce).
 * Each side may make Waldo_AIPass_Airborne_MaxDrops drops, at least Waldo_AIPass_Airborne_Cooldown
 * seconds apart (script and trigger calls may pass "force" to skip the cooldown, never the budget).
 * The drop uses Waldo_fnc_ParadropCreateDropZone with generated jumpers, the side's aircraft from
 * Waldo_AIPass_Airborne_AircraftClasses and jumper class from Waldo_AIPass_Airborne_JumperClasses,
 * DESPAWN lifecycle and no map markers. A server job watches the jumpers. When every surviving jumper
 * has left the aircraft and landed (or 15 minutes pass), it clears the paradrop ownership flags on the
 * squad and gives it a SEEK AND DESTROY waypoint at the target. The Smart AI Pass then picks it up.
 * Locality and authority: server-authoritative. Non-server copies of a trigger or init line do
 * nothing. Remote calls are accepted only from the server itself or a connected headless client.
 *
 * Arguments:
 * 0: side <SIDE or STRING> - side that receives the reinforcement
 * 1: target <ARRAY, OBJECT> - ATL position, or an object/trigger whose position is used
 * 2: options <HASHMAP> (optional) - aircraftClass, jumperClass, jumperCount, direction (approach
 *    heading), altitude, force (skip cooldown), automatic (set by the pass itself)
 *
 * Return Value:
 * Boolean - true when the drop was launched
 *
 * Example:
 * [east, getMarkerPos "reinforce_dz", createHashMapFromArray [["jumperCount", 10]]] call Waldo_fnc_AIPassAirborneRequest;
 * Result: an OPFOR transport drops ten paratroopers who then assault the area.
 *
 * Current callers: mission triggers and scripts, Waldo_fnc_AIPassReinforce and the AI Control ZEN module.
 */

params [["_side", sideUnknown, [sideUnknown, ""]], ["_target", [], [[], objNull]], ["_options", createHashMap, [createHashMap]]];
if (!isServer) exitWith {false};
if (remoteExecutedOwner > 2 && {!(remoteExecutedOwner in ((entities "HeadlessClient_F") apply {owner _x}))}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_AIPass_Airborne_Enable", false]) exitWith {false};
if (_side isEqualType "") then {
    _side = switch (toUpperANSI _side) do {case "WEST"; case "BLUFOR": {west}; case "EAST"; case "OPFOR": {east}; case "GUER"; case "INDEPENDENT"; case "IND": {independent}; default {sideUnknown}};
};
if !(_side in [west, east, independent]) exitWith {false};
private _position = if (_target isEqualType objNull) then {getPosATL _target} else {+_target};
if (count _position < 2) exitWith {false};
_position resize 2;

private _key = switch (_side) do {case west: {"WEST"}; case east: {"EAST"}; default {"GUER"}};
private _used = missionNamespace getVariable ["Waldo_AIPass_AirborneUsed", createHashMap];
private _record = _used getOrDefault [_key, [0, -1e6]];
_record params ["_drops", "_lastAt"];
if (_drops >= (missionNamespace getVariable ["Waldo_AIPass_Airborne_MaxDrops", 2])) exitWith {false};
if (!(_options getOrDefault ["force", false]) && {time - _lastAt < (missionNamespace getVariable ["Waldo_AIPass_Airborne_Cooldown", 600])}) exitWith {false};
private _aircraftClass = _options getOrDefault ["aircraftClass", (missionNamespace getVariable ["Waldo_AIPass_Airborne_AircraftClasses", createHashMap]) getOrDefault [_key, ""]];
if !(isClass (configFile >> "CfgVehicles" >> _aircraftClass)) exitWith {
    diag_log format ["[WMP AI PASS] Airborne request refused: aircraft class '%1' for %2 is not loaded.", _aircraftClass, _key];
    false
};
private _jumperClass = _options getOrDefault ["jumperClass", (missionNamespace getVariable ["Waldo_AIPass_Airborne_JumperClasses", createHashMap]) getOrDefault [_key, ""]];
_used set [_key, [_drops + 1, time]];
missionNamespace setVariable ["Waldo_AIPass_AirborneUsed", _used];

private _id = format ["WMP_AIRBORNE_%1_%2", _key, _drops + 1];
private _config = createHashMapFromArray [
    ["id", _id], ["name", format ["Airborne reinforcement %1 %2", _key, _drops + 1]], ["centre", _position],
    ["direction", _options getOrDefault ["direction", random 360]], ["side", _side], ["aircraftClass", _aircraftClass],
    ["createJumpers", true], ["jumperCount", _options getOrDefault ["jumperCount", missionNamespace getVariable ["Waldo_AIPass_Airborne_JumperCount", 8]]],
    ["lifecycle", "DESPAWN"], ["createMarkers", false], ["autoDropPlayers", false], ["automaticJumpMode", "STATIC"],
    ["notifyRequester", false]
];
if (isClass (configFile >> "CfgVehicles" >> _jumperClass)) then {_config set ["jumperClass", _jumperClass]};
if ("altitude" in _options) then {_config set ["altitude", _options get "altitude"]};
// Run outside any remote-execution context: the paradrop API treats remoteExecutedOwner > 0 as a
// curator request and would refuse a call forwarded by a headless client.
[{
    params ["_config", "_target"];
    if !([_config] call Waldo_fnc_ParadropCreateDropZone) exitWith {
        diag_log format ["[WMP AI PASS] Airborne drop %1 could not be created.", _config get "id"];
    };
    [Waldo_fnc_AIPassAirborneWatch, createHashMapFromArray [["id", _config get "id"], ["target", _target], ["deadline", time + 900]], 10] call Waldo_fnc_AIPassQueueJob;
}, [_config, _position]] call CBA_fnc_execNextFrame;
missionNamespace setVariable ["Waldo_AIPass_AirborneDrops", (missionNamespace getVariable ["Waldo_AIPass_AirborneDrops", 0]) + 1];
diag_log format ["[WMP AI PASS] Airborne reinforcement %1 requested at %2 (automatic=%3).", _id, _position, _options getOrDefault ["automatic", false]];
true
