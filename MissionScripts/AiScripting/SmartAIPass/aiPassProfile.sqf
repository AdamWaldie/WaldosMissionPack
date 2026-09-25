/*
 * Author: WaldoTheWarfighter
 * Returns the behaviour profile values that apply to a group.
 *
 * Behaviour profiles sit alongside AI Rebalance's skill profiles and use the same names (MILITIA,
 * LINE, VETERAN, ELITE, LEGACY), so choosing a WMP opposition profile changes how squads decide as
 * well as how well they shoot. Skill values are never changed here; this only answers
 * "how willing is this squad to flank, assault or hold". Resolution order:
 * 1. the group variable Waldo_AIPass_Profile (a mission maker's per-group choice);
 * 2. Waldo_AIPass_FactionProfiles (a map of CfgFactionClasses name to profile) for the leader's faction;
 * 3. Waldo_AIRebalance_Profile, the active AI Rebalance profile (PUBLIC and STANDARD map to MILITIA
 *    and LINE);
 * 4. LINE.
 * Missing keys in a mission-edited profile fall back to LINE's values, and an unknown profile name
 * uses LINE.
 * Keys: flankChance, assaultChance, advanceChance, investigateChance, coordinatedChance (0-1 rolls),
 * moraleShaken and moraleBroken (morale thresholds), retreatScale (multiplies
 * Waldo_AIPass_Morale_RetreatDistance), surrenderSurvivors (largest squad that may surrender).
 * Locality and authority: read-only; callable anywhere.
 *
 * Arguments:
 * 0: group <GROUP>
 * 1: key <STRING> - one value to return (optional, default: "" returns the whole map)
 *
 * Return Value:
 * HashMap or Number - the resolved profile, or one value from it
 *
 * Example:
 * private _chance = [_group, "flankChance"] call Waldo_fnc_AIPassProfile;
 * Result: 0.3 for a MILITIA squad, 0.7 for an ELITE one with the shipped table.
 *
 * Current callers: flank, advance, assault, investigate, coordinated assault, morale and retreat.
 */

params [["_group", grpNull, [grpNull]], ["_key", "", [""]]];
private _table = missionNamespace getVariable ["Waldo_AIPass_ProfileBehaviour", createHashMap];
private _name = _group getVariable ["Waldo_AIPass_Profile", ""];
if (_name == "") then {
    _name = (missionNamespace getVariable ["Waldo_AIPass_FactionProfiles", createHashMap]) getOrDefault [faction leader _group, ""];
};
if (_name == "") then {
    _name = if (missionNamespace getVariable ["Waldo_AIRebalance_Enable", true]) then {
        missionNamespace getVariable ["Waldo_AIRebalance_Profile", "LINE"]
    } else {"LINE"};
};
_name = toUpperANSI _name;
if (_name == "PUBLIC") then {_name = "MILITIA"};
if (_name == "STANDARD") then {_name = "LINE"};
private _defaults = createHashMapFromArray [
    ["flankChance", 0.5], ["assaultChance", 0.4], ["advanceChance", 0.5], ["investigateChance", 0.6],
    ["coordinatedChance", 0.4], ["moraleShaken", 0.55], ["moraleBroken", 0.3], ["retreatScale", 1], ["surrenderSurvivors", 2]
];
private _line = _table getOrDefault ["LINE", createHashMap];
private _profile = _table getOrDefault [_name, _line];
if (_key != "") exitWith {_profile getOrDefault [_key, _line getOrDefault [_key, _defaults getOrDefault [_key, 0]]]};
private _merged = +_defaults;
_merged merge [_line, true];
_merged merge [_profile, true];
_merged
