/*
 * Author: WaldoTheWarfighter
 * Resolves one improved-landing setting, allowing a helicopter-specific profile to override the
 * global mission value. Overrides use a HashMap stored as Waldo_ImprovedHelicopterLanding_Profile
 * on the aircraft and must match the fallback value's type.
 *
 * Arguments:
 * 0: helicopter <OBJECT>
 * 1: setting suffix <STRING>
 * 2: fallback value <ANY>
 *
 * Return Value: ANY - validated object override, global setting or fallback.
 *
 * Example: [_helicopter, "TransitAltitude", 30] call Waldo_fnc_ImprovedHelicopterLandingSetting;
 * Current callers: improved landing waypoint tracker and vector controller.
 */

params [
    ["_helicopter", objNull, [objNull]],
    ["_setting", "", [""]],
    ["_fallback", nil]
];
private _value = missionNamespace getVariable [format ["Waldo_ImprovedHelicopterLanding_%1", _setting], _fallback];
if (!isNull _helicopter) then {
    private _profile = _helicopter getVariable ["Waldo_ImprovedHelicopterLanding_Profile", createHashMap];
    if (typeName _profile == "HASHMAP" && {!isNil {_profile get _setting}}) then {
        private _candidate = _profile get _setting;
        if (typeName _candidate == typeName _fallback) then {_value = _candidate;};
    };
};
_value
