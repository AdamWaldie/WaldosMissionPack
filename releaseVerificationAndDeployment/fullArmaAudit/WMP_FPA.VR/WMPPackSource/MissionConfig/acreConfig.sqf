/*
 * Author: WaldoTheWarfighter
 * Defines the mission-facing ACRE2 communications and optional Babel settings. WMP loads this file
 * automatically during pre-init, server init and player-local init; do not duplicate these calls in
 * init.sqf. The server compiles one authoritative plan and clients apply only local carried radios.
 *
 * Arguments: None.
 * Return Value: HASHMAP - configuration consumed by Waldo_fnc_ACRE2PreInit and Waldo_fnc_ACRE2Init.
 *
 * Example: private _config = call compile preprocessFileLineNumbers "MissionConfig\acreConfig.sqf";
 * Current callers: automatic WMP ACRE pre-init, initServer.sqf and initPlayerLocal.sqf lifecycle.
 *
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED.
 * EDIT FOR A NORMAL MISSION: enabled, prc343PresetPolicy, namedDisplays, sides, radioOverrides and Babel.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: version, strict and additionalRadioProfiles.
 * CUSTOM CALLS: none for normal setup; the WMP lifecycle owns join, JIP, respawn and replacement.
 * CUSTOMISATION GUIDE: settings marked as normal mission settings are encouraged mission choices;
 * advanced extension values describe tested implementation capability and need technical validation.
 * MISSION MAKER: begin with the shipped net/group examples and replace editor group IDs.
 * ADVANCED: add third-party radio profiles only after confirming their ACRE API behaviour.
 *
 * NORMAL MISSION SETTINGS
 * - enabled: master switch for WMP's replacement ACRE lifecycle.
 * - prc343PresetPolicy: FULL_RANGE keeps all 16 blocks; SIDE_ISOLATED uses ACRE side presets and
 *   gives combat sides five blocks. FULL_RANGE does not provide side frequency isolation.
 * - namedDisplays: labels PRC-148/152/117F channels without changing their frequencies.
 * - sides: [side, official ACRE preset, nets, groups]. Keep the shipped official preset per side.
 * - babel: language content and defaults. It remains inert while babel.enabled is false.
 *
 * NETS
 * A net is [stable key, display label, radio tunings]. A tuning is [base radio class, target].
 * CHANNEL radios use a channel number. FREQUENCY radios use MHz or ACRE's [MHz, fractional] pair.
 * A shared key means actual interoperability only when its radio tunings resolve to compatible
 * frequencies. Shipped PRC-148/152/117F presets share frequencies at matching channel numbers;
 * BF-888S and SEM52SL use separate nets. PRC-77 and SEM70 can share an explicit common frequency.
 *
 * GROUPS AND OPTIONAL RADIO TEMPLATES
 * A group is [editor group ID, ordered fallback net keys, PRC-343 [block,channel] or [], explicit
 * assignments]. An assignment is [base class, same-type occurrence, target, ear]. Explicit rows are
 * optional templates: they apply when that occurrence is carried and are quietly ignored otherwise.
 * LEFT, RIGHT and BOTH/CENTER are supported independently per radio. PTT, volume and speaker settings
 * remain player-owned. With no explicit rows, WMP assigns the first carried radio of each supported
 * type to the first compatible group net; there is no cross-radio priority list or global net cap.
 * Automatic PRC-343 allocation is deterministic from the callsign when its group field is [].
 *
 * OVERRIDES
 * radioOverrides entries are [side, [UID|VARIABLE|ROLE, value], MERGE|REPLACE, assignments]. MERGE
 * replaces matching [class, occurrence] rows and preserves the rest. REPLACE discards group rows.
 * Side scoping prevents a net from another side being accepted accidentally.
 *
 * ADVANCED EXTENSION
 * additionalRadioProfiles is only for a tested third-party carried radio. Entry format is
 * [class, BLOCK_CHANNEL|CHANNEL|FREQUENCY, default ears, maximum channel, frequency range]. WMP's
 * built-in ACRE profiles live in code and should not be copied here. Unknown radios and racks are
 * preserved. WMP does not retune on group changes or poll radios during play.
 *
 * COMPATIBILITY: schema version 3 is intentionally not compatible with the old positional-net or
 * unscoped override schema. Legacy radio/Babel functions remain manual emergency fallbacks only.
 */
createHashMapFromArray [
    ["version", 3],
    ["enabled", true],
    ["strict", true],
    ["prc343PresetPolicy", "FULL_RANGE"],
    ["namedDisplays", true],
    ["notifyAssignmentProblems", true],
    ["additionalRadioProfiles", []],
    ["radioOverrides", [
        // ["WEST", ["ROLE", "JTAC"], "MERGE", [["ACRE_PRC152", 1, "AIRGND", "RIGHT"]]]
    ]],
    ["sides", [
        ["WEST", "default3", [
            ["PLT1", "PLATOON 1", [["ACRE_PRC148", 2], ["ACRE_PRC152", 2], ["ACRE_PRC117F", 2]]],
            ["PLT2", "PLATOON 2", [["ACRE_PRC148", 3], ["ACRE_PRC152", 3], ["ACRE_PRC117F", 3]]],
            ["PLT3", "PLATOON 3", [["ACRE_PRC148", 4], ["ACRE_PRC152", 4], ["ACRE_PRC117F", 4]]],
            ["COY", "COMPANY", [["ACRE_PRC148", 5], ["ACRE_PRC152", 5], ["ACRE_PRC117F", 5]]],
            ["AIRGND", "AIR-GND", [["ACRE_PRC148", 6], ["ACRE_PRC152", 6], ["ACRE_PRC117F", 6]]],
            ["AIR", "AIR-AIR", [["ACRE_PRC148", 7], ["ACRE_PRC152", 7], ["ACRE_PRC117F", 7]]],
            ["CAS1", "CAS 1", [["ACRE_PRC148", 8], ["ACRE_PRC152", 8], ["ACRE_PRC117F", 8]]],
            ["CAS2", "CAS 2", [["ACRE_PRC148", 9], ["ACRE_PRC152", 9], ["ACRE_PRC117F", 9]]],
            ["CFF1", "CFF 1", [["ACRE_PRC148", 10], ["ACRE_PRC152", 10], ["ACRE_PRC117F", 10]]],
            ["CFF2", "CFF 2", [["ACRE_PRC148", 11], ["ACRE_PRC152", 11], ["ACRE_PRC117F", 11]]],
            ["CONVOY", "CONVOY", [["ACRE_PRC148", 12], ["ACRE_PRC152", 12], ["ACRE_PRC117F", 12]]],
            ["BF_LOCAL", "LOCAL BF", [["ACRE_BF888S", 4]]],
            ["SEM_LOCAL", "LOCAL SEM", [["ACRE_SEM52SL", 4]]],
            ["LEGACY", "LEGACY", [["ACRE_PRC77", 34.000], ["ACRE_SEM70", 34.000]]]
        ], [
            ["VIKING-1-1", ["PLT1", "AIRGND", "BF_LOCAL", "SEM_LOCAL", "LEGACY"], [], []],
            ["VIKING 5", ["COY", "AIRGND"], [], []],
            ["VIKING 3.2", ["PLT3", "AIRGND"], [], []],
            ["BANSHEE", ["AIRGND", "AIR"], [], []]
        ]],
        ["EAST", "default2", [], []],
        ["GUER", "default4", [], []],
        ["CIV", "default", [], []]
    ]],
    ["babel", createHashMapFromArray [
        ["enabled", false],
        ["languages", [["common", "Common"], ["en", "English"], ["ru", "Russian"], ["fr", "French"], ["ar", "Arabic"]]],
        ["sideDefaults", [
            ["WEST", ["common", "en"], "en"],
            ["EAST", ["common", "ru"], "ru"],
            ["GUER", ["common", "fr"], "fr"],
            ["CIV", ["common", "ar"], "ar"]
        ]],
        ["unitOverrides", []],
        ["changeOnSideChange", false],
        ["followPlayerUnit", true]
    ]]
]
