/*
 * Author: WaldoTheWarfighter
 * Defines the pure-data ACRE2 communications and Babel configuration consumed during pre-init,
 * server init and player-local init. Mission makers should edit this file instead of lifecycle
 * scripts. Group entries use stable net keys; explicit PRC-343 assignments are [block, channel].
 *
 * Arguments: None.
 *
 * Return Value:
 * HashMap - validated by Waldo_fnc_ACRE2ValidateConfig before it is used.
 *
 * Example:
 * private _config = call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf";
 *
 * Current callers: Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init.
 */
createHashMapFromArray [
    ["version", 1],
    ["enabled", true],
    ["strict", true],
    ["retuneOnGroupChange", false],
    ["namedDisplays", true],
    ["radioPriority", ["ACRE_PRC152", "ACRE_PRC148", "ACRE_PRC117F", "ACRE_BF888S", "ACRE_SEM52SL", "ACRE_PRC77", "ACRE_SEM70"]],
    ["radioProfiles", [
        ["ACRE_PRC343", "BLOCK_CHANNEL", "LEFT"],
        ["ACRE_PRC148", "CHANNEL", "RIGHT"],
        ["ACRE_PRC152", "CHANNEL", "RIGHT"],
        ["ACRE_PRC117F", "CHANNEL", "CENTER"],
        ["ACRE_BF888S", "CHANNEL", "RIGHT"],
        ["ACRE_SEM52SL", "CHANNEL", "RIGHT"],
        ["ACRE_PRC77", "FREQUENCY", "RIGHT"],
        ["ACRE_SEM70", "FREQUENCY", "RIGHT"]
    ]],
    ["sides", [
        ["WEST", "default3", [
            ["PLT1", "PLATOON 1", []], ["PLT2", "PLATOON 2", []],
            ["PLT3", "PLATOON 3", []], ["COY", "COMPANY", []],
            ["AIRGND", "AIR-GND", []], ["AIR", "AIR-AIR", []],
            ["CAS1", "CAS 1", []], ["CAS2", "CAS 2", []],
            ["CFF1", "CFF 1", []], ["CFF2", "CFF 2", []],
            ["CONVOY", "CONVOY 1", []]
        ], [
            ["VIKING-1-1", ["PLT1", "AIRGND"], [1, 1]],
            ["VIKING 5", ["COY", "AIRGND"], [1, 5]],
            ["VIKING 3.2", ["PLT3", "AIRGND"], [3, 2]],
            ["BANSHEE", ["AIRGND", "AIR"], [4, 1]]
        ]],
        ["EAST", "default2", [], []],
        ["GUER", "default4", [], []],
        ["CIV", "default", [], []]
    ]],
    ["babel", createHashMapFromArray [
        ["enabled", false],
        ["languages", [["en", "English"]]],
        ["sideDefaults", [["WEST", ["en"], "en"], ["EAST", ["en"], "en"], ["GUER", ["en"], "en"], ["CIV", ["en"], "en"]]],
        ["unitOverrides", []],
        ["changeOnSideChange", false],
        ["followPlayerUnit", true]
    ]]
]
