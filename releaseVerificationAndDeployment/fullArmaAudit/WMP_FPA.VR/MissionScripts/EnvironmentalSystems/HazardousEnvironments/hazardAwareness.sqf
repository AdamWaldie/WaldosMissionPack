/*
 * Author: WaldoTheWarfighter
 * Decides whether one player can perceive a hazard's UI feedback. Hazards remain physically
 * dangerous when feedback is hidden; this controls information only. By default every player is
 * aware. A profile may require carried/worn detector items, a nearby detector object, an advanced
 * callback, or any combination of those requirements.
 *
 * Arguments:
 * 0: unit <OBJECT> - player whose awareness is being checked.
 * 1: hazard key <STRING> - stable registered-zone ID.
 * 2: profile <HASHMAP> - hazard profile containing the optional awareness settings.
 * 3: inside <BOOL> - whether the unit is currently inside the hazard.
 * 4: exposure <NUMBER> - current local accumulated exposure.
 *
 * Profile settings:
 * detectorItems <ARRAY<STRING>> - at least one listed carried, worn or assigned classname.
 * detectorObjects <ARRAY<STRING>> - at least one listed CfgVehicles class nearby.
 * detectorObjectRange <NUMBER> - nearby-object search range in metres (default 5).
 * awarenessCondition <CODE|STRING> - advanced final condition; string names a missionNamespace
 * function. It receives the five arguments above and must return true or false.
 *
 * Return Value: <BOOL> - true when all configured awareness requirements are satisfied.
 *
 * Example:
 * [_unit, "REACTOR", _profile, true, 0.4] call Waldo_fnc_HazardAwareness;
 * Current caller: Waldo_fnc_HazardTick before transition or continuous hazard UI is shown.
 */
params [
    ["_unit", objNull, [objNull]],
    ["_key", "", [""]],
    ["_profile", createHashMap, [createHashMap]],
    ["_inside", false, [false]],
    ["_exposure", 0, [0]]
];
if (isNull _unit) exitWith {false};

private _detectorItems = _profile getOrDefault ["detectorItems", []];
private _aware = true;
if !(_detectorItems isEqualTo []) then {
    private _possessions = items _unit + assignedItems _unit + weapons _unit + magazines _unit;
    {
        if !(_x isEqualTo "") then {_possessions pushBack _x;};
    } forEach [uniform _unit, vest _unit, backpack _unit, headgear _unit, goggles _unit, binocular _unit];
    _aware = (_detectorItems findIf {_x in _possessions}) >= 0;
};
if (!_aware) exitWith {false};

private _detectorObjects = (_profile getOrDefault ["detectorObjects", []]) select {
    isClass (configFile >> "CfgVehicles" >> _x)
};
if !(_detectorObjects isEqualTo []) then {
    private _range = (_profile getOrDefault ["detectorObjectRange", 5]) max 0;
    _aware = !((nearestObjects [_unit, _detectorObjects, _range, true]) isEqualTo []);
};
if (!_aware) exitWith {false};

private _condition = _profile getOrDefault ["awarenessCondition", {}];
if (_condition isEqualType "") then {_condition = missionNamespace getVariable [_condition, {}]};
if (_condition isEqualType {}) exitWith {
    private _result = [_unit, _key, _profile, _inside, _exposure] call _condition;
    _result isEqualType true && {_result}
};
true
