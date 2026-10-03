/*
 * Author: WaldoTheWarfighter
 * Purpose: Reads or updates local field-equipment accessibility preferences. These are
 * presentation settings; they do not change challenge difficulty or timing.
 * Locality/Authority: Run on the interface client whose profile should change.
 * Repeat/JIP Behaviour: Reads are repeat-safe. Updates persist in that client's profile;
 * each joining client reads its own saved settings, not a server snapshot.
 * Arguments: 0: overrides <ARRAY of [STRING, BOOL] pairs or HASHMAP>, default [].
 * The recognized keys are highContrast, colourblind, largeText, strongOutlines,
 * reducedMotion and audioCaptions. An empty array only reads current values.
 * Return Value: <HASHMAP> effective accessibility settings.
 * Current Callers: MiniGameChallengeUI, MiniGameEquipmentProfile and local UI setup.
 * Example: [["largeText", true]] call Waldo_fnc_MiniGameAccessibility;
 * Result: Saves the override locally and returns the updated settings.
 */
private _overrides = _this;
if (typeName _overrides == "ARRAY" && {(count _overrides) == 1} && {typeName (_overrides select 0) in ["ARRAY", "HASHMAP"]}) then {
    _overrides = _overrides select 0;
};

private _settings = profileNamespace getVariable ["Waldo_IMG_Accessibility", createHashMapFromArray [
    ["highContrast", false],
    ["colourblind", true],
    ["largeText", false],
    ["strongOutlines", true],
    ["reducedMotion", false],
    ["audioCaptions", true]
]];

private _pairs = [];
if (typeName _overrides == "HASHMAP") then {
    { _pairs pushBack [_x, _overrides get _x]; } forEach keys _overrides;
} else {
    _pairs = _overrides;
};
{
    _x params ["_key", "_value"];
    if (_key in ["highContrast", "colourblind", "largeText", "strongOutlines", "reducedMotion", "audioCaptions"]) then {
        _settings set [_key, _value isEqualTo true];
    };
} forEach _pairs;

if ((count _pairs) > 0) then {
    profileNamespace setVariable ["Waldo_IMG_Accessibility", _settings];
    saveProfileNamespace;
};

_settings
