/*
 * Author: Waldo
 * Creates (or updates) a localised radio jammer anchored to a world object. This is the main
 * ease-of-use entry point for the jamming system: give it an object and a radius and you have
 * a working jammer that denies ACRE2 and/or TFAR radio comms in that area. Server-authoritative
 * - calling it from a client (or an object init field on a client) forwards to the server, which
 * owns the broadcast jammer registry so JIP / rejoining players inherit every jammer. Idempotent
 * per object: calling again on the same object updates that jammer in place instead of stacking.
 *
 * Arguments:
 * 0: Object <OBJECT> - the emitter the jammer is anchored to (its position is the jam centre)
 * 1: Radius <NUMBER> - full-strength jamming radius in metres (optional, default: 300)
 * 2: Affected sides <STRING or ARRAY> - "ALL", a single side/side-string, or an array of them.
 *      Accepts sides (west/east/...) or strings ("WEST"/"BLUFOR","EAST"/"OPFOR",
 *      "IND"/"INDFOR","CIV"/"CIVILIAN"). Only listed sides are jammed (optional, default: "ALL")
 * 3: Bands <STRING or ARRAY> - "ALL" for every frequency, or an array of [minMHz, maxMHz] ranges
 *      to jam only those bands. Band filtering is ACRE2 only; TFAR is always broadband
 *      (optional, default: "ALL")
 * 4: Falloff <NUMBER> - extra metres of linear falloff beyond the radius (optional, default: 50)
 * 5: Strength <NUMBER> - jamming strength at full effect, 0..1 (optional, default: 1)
 * 6: Active <BOOL> - start switched on (optional, default: true)
 * 7: Create marker <BOOL> - place a map marker on the jammer (optional, default: false)
 *
 * Return Value:
 * Number <NUMBER> - the jammer id (server side); -1 when forwarded from a client
 *
 * Example:
 * // Simplest - a 300 m jammer that jams everyone, from an object's init field:
 * [this] call Waldo_fnc_Jammer;
 * // A 500 m jammer that only jams OPFOR, on the 30-88 MHz band, with a map marker:
 * [this, 500, "EAST", [[30, 88]], 50, 1, true, true] call Waldo_fnc_Jammer;
 */

params [
    ["_object", objNull, [objNull]],
    ["_radius", 300, [0]],
    ["_sides", "ALL", ["", [], sideUnknown]],
    ["_bands", "ALL", ["", []]],
    ["_falloff", 50, [0]],
    ["_strength", 1, [0]],
    ["_active", true, [false]],
    ["_marker", false, [false]]
];

if (isNull _object) exitWith {
    diag_log "[WMP JAM] Waldo_fnc_Jammer called with a null object - ignored.";
    -1
};

// Keep all registry writes on the server so JIP behaviour stays correct.
if (!isServer) exitWith {
    _this remoteExec ["Waldo_fnc_Jammer", 2];
    -1
};

// Normalise the affected-sides argument to "ALL" or an array of side values.
private _sidesN = "ALL";
if !(_sides isEqualType "" && {toUpper _sides == "ALL"}) then {
    private _raw = _sides;
    if !(_raw isEqualType []) then { _raw = [_raw]; };
    private _out = [];
    {
        private _s = _x;
        if (_s isEqualType "") then {
            switch (toUpper _s) do {
                case "WEST"; case "BLUFOR": { _s = west; };
                case "EAST"; case "OPFOR": { _s = east; };
                case "IND"; case "INDEP"; case "INDFOR"; case "GUER"; case "GUERRILA": { _s = independent; };
                case "CIV"; case "CIVILIAN": { _s = civilian; };
                default { _s = sideUnknown; };
            };
        };
        if (_s isEqualType sideUnknown && {!(_s in _out)}) then { _out pushBack _s; };
    } forEach _raw;
    if (_out isEqualTo []) then { _sidesN = "ALL"; } else { _sidesN = _out; };
};

// Normalise the bands argument to "ALL" or an array of [min, max] ranges.
private _bandsN = "ALL";
if !(_bands isEqualType "" && {toUpper _bands == "ALL"}) then {
    private _raw = _bands;
    // Allow a single [min, max] range without the outer array.
    if (_raw isEqualType [] && {count _raw == 2} && {(_raw select 0) isEqualType 0}) then { _raw = [_raw]; };
    if (_raw isEqualType [] && {count _raw > 0}) then { _bandsN = _raw; } else { _bandsN = "ALL"; };
};

// Clamp strength into a sane range.
_strength = (_strength max 0) min 1;

// Re-use an existing id for this object so repeat calls update rather than duplicate.
private _id = _object getVariable ["Waldo_Jamming_Id", -1];
if (_id < 0) then {
    _id = missionNamespace getVariable ["Waldo_Jamming_NextId", 0];
    missionNamespace setVariable ["Waldo_Jamming_NextId", _id + 1, true];
    _object setVariable ["Waldo_Jamming_Id", _id, true];
};

private _markerName = "";
if (_marker) then {
    _markerName = format ["Waldo_Jammer_%1", _id];
    if (getMarkerType _markerName == "") then {
        createMarker [_markerName, getPosATL _object];
        _markerName setMarkerType "mil_warning";
        _markerName setMarkerColor "ColorRed";
        _markerName setMarkerText "Radio Jammer";
    };
};

private _entry = [_id, _object, _radius, _falloff, _sidesN, _bandsN, _strength, _active, _markerName];

// Replace an existing entry for this id, else append.
private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
private _idx = _registry findIf { (_x select 0) == _id };
if (_idx >= 0) then {
    // Preserve any marker created previously if this call did not make one.
    if (_markerName == "") then { _entry set [8, (_registry select _idx) select 8]; };
    _registry set [_idx, _entry];
} else {
    _registry pushBack _entry;
};
missionNamespace setVariable ["Waldo_Jamming_Registry", _registry, true];

diag_log format ["[WMP JAM] Jammer %1 registered: radius=%2 falloff=%3 sides=%4 active=%5", _id, _radius, _falloff, _sidesN, _active];

_id
