/*
 * Author: WaldoTheWarfighter
 * Defines the initial ACRE2 radio plan for the dedicated multiplayer respawn test mission.
 * Both WEST groups carry one PRC-343, PRC-152 and PRC-77 with deliberately non-default settings.
 * Players may alter them and use the save crate; their saved personal settings should then win on
 * ordinary respawn.
 *
 * Locality and authority: loaded on every ACRE machine. The server publishes one plan; each client
 * applies only its own carried-radio assignments.
 * Arguments: None.
 * Return Value: HASHMAP consumed by the automatic WMP ACRE lifecycle.
 * Example: automatically compiled from MissionConfig\acreConfig.sqf.
 * Result: ALPHA and BRAVO begin on different non-default radio settings.
 * Current callers: automatic pre-init, initServer.sqf and initPlayerLocal.sqf lifecycle.
 */
createHashMapFromArray [
    ["enabled", true],
    ["strict", true],
    ["prc343PresetPolicy", "FULL_RANGE"],
    ["namedDisplays", true],
    ["notifyAssignmentProblems", true],
    ["additionalRadioProfiles", []],
    ["radioOverrides", []],
    ["sides", [[
        "WEST",
        "default3",
        [
            ["ALPHA_NET", "ALPHA TEST", "PRC_LR", 4],
            ["BRAVO_NET", "BRAVO TEST", "PRC_LR", 8],
            ["ALPHA_77", "ALPHA 77", "LEGACY_VHF", 45.500],
            ["BRAVO_77", "BRAVO 77", "LEGACY_VHF", 51.000]
        ],
        [
            ["ALPHA", [["ACRE_PRC343", "ALL", [5, 3], "LEFT"], ["ACRE_PRC152", "ALL", "ALPHA_NET", "RIGHT"], ["ACRE_PRC77", "ALL", "ALPHA_77", "BOTH"]]],
            ["BRAVO", [["ACRE_PRC343", "ALL", [6, 7], "RIGHT"], ["ACRE_PRC152", "ALL", "BRAVO_NET", "LEFT"], ["ACRE_PRC77", "ALL", "BRAVO_77", "BOTH"]]]
        ]
    ]]],
    ["babel", createHashMapFromArray [
        ["enabled", true],
        ["languages", [["common", "Common"], ["en", "English"], ["ru", "Russian"]]],
        ["sideDefaults", [["WEST", ["common", "en"], "en"]]],
        ["unitOverrides", [[
            ["VARIABLENAME", "acre_bravo_1"], ["common", "en", "ru"], "ru"
        ]]],
        ["changeOnSideChange", false],
        ["followPlayerUnit", true]
    ]]
]
