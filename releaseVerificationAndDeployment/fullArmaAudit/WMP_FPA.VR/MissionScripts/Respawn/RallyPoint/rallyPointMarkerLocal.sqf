/*
 * Author: WaldoTheWarfighter
 * Creates a local map marker for the receiving player's active squad rally.
 * Locality and authority: Interface-client only; rejects non-server remote calls and rallies
 * belonging to another player group. The server owns the public rally state.
 * Repeat/JIP: The public rally can be replayed to a joining client. Repeated calls reuse the
 * marker name, but start another removal watcher; callers should only send state changes once.
 * Arguments:
 * 0: rally object <OBJECT> (default objNull)
 * 1: owning squad <GROUP> (default grpNull)
 * 2: marker label <STRING> (default "Squad Rally")
 * 3: marker colour <STRING> (default "ColorWEST")
 * Return Value: <BOOL> - true after creating/updating a local marker; false for invalid state.
 * Current callers: Waldo_fnc_RallyPointRequestServer during squad rally deployment.
 * Example: [_rally, group player, "Squad Rally", "ColorWEST"] call Waldo_fnc_RallyPointMarkerLocal;
 * Result: Only the owning squad sees the rally marker; it is removed when the rally ends.
 */
params [["_rally", objNull, [objNull]], ["_group", grpNull, [grpNull]], ["_label", "Squad Rally", [""]], ["_colour", "ColorWEST", [""]]];
if (remoteExecutedOwner > 0 && {remoteExecutedOwner != 2}) exitWith {false};
if (!hasInterface || {isNull _rally}) exitWith {false};
if (isNull _group || {group player != _group}) exitWith {false};
private _id = format ["Waldo_Rally_Local_%1", ((netId _rally) splitString ":") joinString "_"];
private _marker = createMarkerLocal [_id, getPosATL _rally];
_marker setMarkerTypeLocal "mil_start";
_marker setMarkerTextLocal _label;
_marker setMarkerColorLocal _colour;
[_rally, _group, _marker] spawn {
    params ["_rally", "_group", "_marker"];
    waitUntil {sleep 1; isNull _rally || {group player != _group} || {!(_group getVariable ["Waldo_Rally_Active", false])}};
    deleteMarkerLocal _marker;
};
true
