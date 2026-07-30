/*
 * Author: WaldoTheWarfighter
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
 * 8: Sector <ARRAY> - [] for omnidirectional, or [bearing, arc] for a directional cone facing
 *      "bearing" degrees with a total width of "arc" degrees (optional, default: [])
 * 9: Duty <ARRAY> - [] for a constant jammer, or [onSeconds, offSeconds] to pulse it on and off
 *      (optional, default: [])
 * 10: Jam UAVs <BOOL> - also jam drones/UGVs in the field (freeze autonomous ones, cut controlling
 *      players' datalinks) as well as radios (optional, default: false)
 * 11: Curator 3D marker <BOOL> - show this emitter in the curator-only Draw3D overlay even when
 *      the global all-jammer overlay is disabled (optional, default: false)
 * 12: Interaction options <ARRAY or HASHMAP> - optional named settings:
 *      disableChallenge <BOOL>, challengeId <STRING>, difficulty <STRING>,
 *      engineerOnly <BOOL>, resultMode <STRING: DISABLE/DESTROY>, allowPlayerToggle <BOOL>.
 *      Defaults come from the matching Waldo_Jamming_* mission settings.
 *
 * Return Value:
 * Number <NUMBER> - the jammer id (server side); -1 when forwarded from a client
 *
 * Example:
 * // Simplest - a 300 m jammer that jams everyone, from an object's init field:
 * [this] call Waldo_fnc_Jammer;
 * // A 500 m jammer that only jams OPFOR, on the 30-88 MHz band, with a map marker:
 * [this, 500, "EAST", [[30, 88]], 50, 1, true, true] call Waldo_fnc_Jammer;
 * // An 800 m cone facing 090 deg, 60 deg wide, pulsing 4s on / 2s off:
 * [this, 800, "ALL", "ALL", 50, 1, true, true, [90, 60], [4, 2]] call Waldo_fnc_Jammer;
 */

params [
    ["_object", objNull, [objNull]],
    ["_radius", 300, [0]],
    ["_sides", "ALL", ["", [], sideUnknown]],
    ["_bands", "ALL", ["", []]],
    ["_falloff", 50, [0]],
    ["_strength", 1, [0]],
    ["_active", true, [false]],
    ["_marker", false, [false]],
    ["_sector", [], [[]]],
    ["_duty", [], [[]]],
    ["_jamUAV", false, [false]],
    ["_gmMarker", false, [false]],
    ["_interactionOptions", [], [[], createHashMap]]
];

if (isNull _object) exitWith {
    diag_log "[WMP JAM] Waldo_fnc_Jammer called with a null object - ignored.";
    -1
};

// Keep all registry writes on the server so JIP behaviour stays correct.
if (!isServer) exitWith {
    private _interactionForward = _interactionOptions;
    if (typeName _interactionForward == "HASHMAP") then {
        private _pairs = [];
        {_pairs pushBack [_x, _interactionForward get _x];} forEach keys _interactionForward;
        _interactionForward = _pairs;
    };
    [_object, _radius, _sides, _bands, _falloff, _strength, _active, _marker, _sector, _duty, _jamUAV, _gmMarker, _interactionForward]
        remoteExec ["Waldo_fnc_Jammer", 2];
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

// Normalise the directional sector: [] omni, or a valid [bearing, arc].
private _sectorN = [];
if (_sector isEqualType [] && {count _sector == 2}) then {
    private _b = (_sector select 0) % 360;
    private _a = (_sector select 1) max 0;
    if (_a > 0 && {_a < 360}) then { _sectorN = [_b, _a]; };
};

// Normalise the duty cycle: [] constant, or a valid [on, off] with a positive period.
private _dutyN = [];
if (_duty isEqualType [] && {count _duty == 2}) then {
    private _onT = (_duty select 0) max 0;
    private _offT = (_duty select 1) max 0;
    if ((_onT + _offT) > 0 && {_offT > 0}) then { _dutyN = [_onT, _offT]; };
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

private _entry = [_id, _object, _radius, _falloff, _sidesN, _bandsN, _strength, _active, _markerName, _sectorN, _dutyN, _jamUAV, _gmMarker];

private _interactionPairs = [];
if (typeName _interactionOptions == "HASHMAP") then {
    {_interactionPairs pushBack [_x, _interactionOptions get _x];} forEach keys _interactionOptions;
} else {
    _interactionPairs = _interactionOptions;
};
private _interactionOption = {
    params ["_key", "_default"];
    private _value = _default;
    {if ((_x param [0, ""]) == _key) exitWith {_value = _x param [1, _default];};} forEach _interactionPairs;
    _value
};
private _allowPlayerToggle = ["allowPlayerToggle", missionNamespace getVariable ["Waldo_Jamming_AllowPlayerToggle", true]] call _interactionOption;
private _disableChallenge = ["disableChallenge", missionNamespace getVariable ["Waldo_Jamming_DisableChallenge", false]] call _interactionOption;
private _challengeId = toLower (["challengeId", missionNamespace getVariable ["Waldo_Jamming_DisableChallengeId", "circuit"]] call _interactionOption);
if !(_challengeId in ["wirecut", "minesweeper", "keypad", "lockpick", "circuit", "repair", "radiotune", "pressure", "sequence", "commandinput"]) then {_challengeId = "circuit";};
private _difficulty = toLower (["difficulty", missionNamespace getVariable ["Waldo_Jamming_DisableDifficulty", "standard"]] call _interactionOption);
if !(_difficulty in ["easy", "standard", "hard", "expert"]) then {_difficulty = "standard";};
private _engineerOnly = ["engineerOnly", missionNamespace getVariable ["Waldo_Jamming_DisableEngineerOnly", true]] call _interactionOption;
private _resultMode = toUpper (["resultMode", missionNamespace getVariable ["Waldo_Jamming_DisableResult", "DISABLE"]] call _interactionOption);
if !(_resultMode in ["DISABLE", "DESTROY"]) then {_resultMode = "DISABLE";};
private _interactionSettings = [_allowPlayerToggle, _disableChallenge, _challengeId, _difficulty, _engineerOnly, _resultMode];
_object setVariable ["Waldo_Jamming_AllowPlayerToggle", _allowPlayerToggle, true];
_object setVariable ["Waldo_Jamming_DisableChallenge", _disableChallenge, true];
_object setVariable ["Waldo_Jamming_DisableChallengeId", _challengeId, true];
_object setVariable ["Waldo_Jamming_DisableDifficulty", _difficulty, true];
_object setVariable ["Waldo_Jamming_DisableEngineerOnly", _engineerOnly, true];
_object setVariable ["Waldo_Jamming_DisableResult", _resultMode, true];

// Replace an existing entry for this id, else append.
private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
private _idx = _registry findIf { (_x select 0) == _id };
private _isNew = _idx < 0;
if (_idx >= 0) then {
    // Preserve any marker created previously if this call did not make one.
    if (_markerName == "") then { _entry set [8, (_registry select _idx) select 8]; };
    _registry set [_idx, _entry];
} else {
    _registry pushBack _entry;
};
missionNamespace setVariable ["Waldo_Jamming_Registry", _registry, true];

// Destructible jammers: auto-deregister when the emitter is destroyed (EW objectives for free).
if (_isNew && {missionNamespace getVariable ["Waldo_Jamming_Destructible", true]}) then {
    _object addEventHandler ["Killed", {
        params ["_deadObj"];
        [_deadObj] call Waldo_fnc_JammerRemove;
    }];
};

// Install the player ACE interaction (toggle / detonate) on every machine for this emitter.
if (_isNew) then {
    [_object, _interactionSettings] remoteExec ["Waldo_fnc_JammerInteraction", 0, _object];
};

diag_log format ["[WMP JAM] Jammer %1 registered: radius=%2 falloff=%3 sides=%4 sector=%5 duty=%6 active=%7", _id, _radius, _falloff, _sidesN, _sectorN, _dutyN, _active];

_id
