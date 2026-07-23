/*
 * Reads or updates local field-equipment accessibility preferences.
 * Call with [] to read settings, or an array/hashmap of named overrides to update them.
 * Presentation preferences never alter challenge difficulty or timing.
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
