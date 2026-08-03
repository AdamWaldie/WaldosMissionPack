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
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enabled, namedDisplays, sides/nets/groups and Babel content are intended mission
 * choices. Group assignments are [normalised group ID, [logical net keys], [343 block, channel]].
 * Blocks/channels are integers 1-16. A blank 343 assignment [] requests deterministic allocation.
 * Side presets must remain WEST default3, EAST default2, GUER default4 and CIV default.
 * ADVANCED TUNING - strict should normally remain true; retuneOnGroupChange should normally remain
 * false so collected radios are preserved. radioPriority and radioProfiles should change only when
 * adding a tested carried-radio profile. Profile modes are BLOCK_CHANNEL, CHANNEL or FREQUENCY;
 * CEOI placement is LEFT, CENTER or RIGHT.
 * COMPATIBILITY - version is the parser schema and must remain 1 until the implementation changes.
 */
createHashMapFromArray [
    ["version", 1],                       // COMPATIBILITY: schema revision; do not customise.
    ["enabled", true],                    // MISSION MAKER: false disables the replacement ACRE lifecycle.
    ["strict", true],                     // ADVANCED: reject invalid/colliding explicit allocations.
    ["retuneOnGroupChange", false],       // ADVANCED: true retunes on group change and may overwrite captured-radio state.
    ["namedDisplays", true],              // MISSION MAKER: enable supported physical radio channel labels.
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
    ["sides", [                           // MISSION MAKER: side preset, logical nets and group allocations.
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
        ["enabled", false],                // MISSION MAKER: enable ACRE Babel language simulation.
        ["languages", [["en", "English"]]], // MISSION MAKER: ordered [stable ID, display name] pairs.
        ["sideDefaults", [["WEST", ["en"], "en"], ["EAST", ["en"], "en"], ["GUER", ["en"], "en"], ["CIV", ["en"], "en"]]], // MISSION MAKER: [side, understood IDs, speaking ID].
        ["unitOverrides", []],             // MISSION MAKER: optional UID/unit multilingual overrides.
        ["changeOnSideChange", false],     // ADVANCED: true replaces learned languages after a side change.
        ["followPlayerUnit", true]         // ADVANCED: reapply after player-object replacement; normally true.
    ]]
]
