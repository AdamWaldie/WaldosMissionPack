/* Creates a group-filtered local marker and removes it when ownership/state changes. */
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
