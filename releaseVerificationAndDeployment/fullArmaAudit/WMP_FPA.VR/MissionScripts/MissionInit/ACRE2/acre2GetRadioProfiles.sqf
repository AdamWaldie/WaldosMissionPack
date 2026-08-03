/*
 * Author: WaldoTheWarfighter
 * Returns WMP's tested carried-radio capability catalogue plus optional mission extensions. Keeping
 * built-in ACRE behaviour here prevents mission makers from having to maintain implementation data.
 * Mission extensions replace a built-in entry with the same base class.
 *
 * Arguments:
 * 0: ACRE configuration <HASHMAP> (default current mission configuration)
 *
 * Return Value: ARRAY of [class, mode, default ears, maximum channel, frequency range].
 * Frequency range is [minimum MHz, maximum MHz, step kHz, ACRE pair divisor].
 *
 * Example: private _profiles = [] call Waldo_fnc_ACRE2GetRadioProfiles;
 * Current callers: ACRE validation, pre-init, assignment, capture and restore functions.
 */
params [["_config", missionNamespace getVariable ["Waldo_ACRE2_Config", createHashMap], [createHashMap]]];
private _profiles = [
    ["ACRE_PRC343", "BLOCK_CHANNEL", ["LEFT", "RIGHT", "CENTER"], 256, []],
    ["ACRE_PRC148", "CHANNEL", ["RIGHT", "LEFT", "CENTER"], 32, []],
    ["ACRE_PRC152", "CHANNEL", ["RIGHT", "LEFT", "CENTER"], 100, []],
    ["ACRE_PRC117F", "CHANNEL", ["CENTER", "RIGHT", "LEFT"], 100, []],
    ["ACRE_BF888S", "CHANNEL", ["RIGHT", "LEFT", "CENTER"], 16, []],
    ["ACRE_SEM52SL", "CHANNEL", ["RIGHT", "LEFT", "CENTER"], 12, []],
    ["ACRE_PRC77", "FREQUENCY", ["RIGHT", "LEFT", "CENTER"], 0, [30, 75.95, 50, 100]],
    ["ACRE_SEM70", "FREQUENCY", ["RIGHT", "LEFT", "CENTER"], 0, [30, 79.975, 25, 1000]]
];
{
    private _class = toUpper (_x param [0, ""]);
    private _index = _profiles findIf {toUpper (_x select 0) == _class};
    if (_index < 0) then {_profiles pushBack _x} else {_profiles set [_index, _x]};
} forEach (_config getOrDefault ["additionalRadioProfiles", []]);
_profiles
