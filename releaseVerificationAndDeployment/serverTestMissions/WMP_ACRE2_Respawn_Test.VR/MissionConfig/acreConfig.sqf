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
            ["ALPHA_NET", "ALPHA TEST", [["ACRE_PRC152", 4], ["ACRE_PRC77", 45.500]]],
            ["BRAVO_NET", "BRAVO TEST", [["ACRE_PRC152", 8], ["ACRE_PRC77", 51.000]]]
        ],
        [
            ["ALPHA", ["ALPHA_NET"], [5, 3], [
                ["ACRE_PRC343", 1, [5, 3], "LEFT"],
                ["ACRE_PRC152", 1, 4, "RIGHT"],
                ["ACRE_PRC77", 1, 45.500, "CENTER"]
            ]],
            ["BRAVO", ["BRAVO_NET"], [6, 7], [
                ["ACRE_PRC343", 1, [6, 7], "RIGHT"],
                ["ACRE_PRC152", 1, 8, "LEFT"],
                ["ACRE_PRC77", 1, 51.000, "CENTER"]
            ]]
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
