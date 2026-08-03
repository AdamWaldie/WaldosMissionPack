/*
 * Author: WaldoTheWarfighter
 * Defines the pure-data ACRE2 communications and Babel configuration consumed during pre-init,
 * server init and player-local init. Mission makers should edit this file instead of lifecycle
 * scripts. The schema separates radio capabilities from group or player assignment policy.
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
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED.
 * Set `enabled` below and configure the side/net/group data in this file. Do not add an ACRE call
 * to init.sqf, initServer.sqf or initPlayerLocal.sqf: WMP already reads this file at the required
 * pre-init, server and player-local lifecycle stages. ACRE must be loaded on the relevant machines.
 *
 * EDIT FOR A NORMAL MISSION: enabled, prc343PresetPolicy, namedDisplays, radioOverrides, sides and
 * babel. Within each side, edit the named nets and the group assignment rows that match your real
 * editor group IDs. Explicit radio rows are optional and are needed only when multiple radios of
 * the same type require different nets or ears.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: version, strict, retuneOnGroupChange, radioPriority and
 * radioProfiles. These describe parser and radio capabilities rather than an ordinary radio plan.
 * CUSTOM CALLS: none for normal setup. The active lifecycle owns join, JIP, respawn and Babel.
 *
 * CUSTOMISATION GUIDE:
 * MISSION MAKER - enabled, prc343PresetPolicy, namedDisplays, sides, nets, groups, radioOverrides and Babel content are
 * intended mission choices. Group entries are [group ID, fallback net keys, fallback 343 [block,
 * channel], explicit assignments]. An assignment is [base radio class, same-type occurrence
 * (1-based), target, ear]. Target is a net key, a 343 [block, channel], or a
 * direct frequency supported by acre_api_fnc_setupRadios. Ear accepts LEFT, RIGHT, BOTH or CENTER;
 * BOTH is the mission-facing alias for ACRE CENTER. WMP deliberately leaves alternate PTT, volume,
 * current-radio, speaker and audio-source preferences under the player's control.
 *
 * radioOverrides optionally replace the matching group's explicit assignments. Each entry is
 * [[selector type, value], assignments]. Supported selectors are UID, VARIABLE and ROLE. ROLE
 * matches roleDescription text before an optional @ suffix. First matching override wins.
 *
 * ADVANCED TUNING - strict should normally remain true. When false, duplicate explicit PRC-343
 * assignments are warnings rather than errors. retuneOnGroupChange should normally remain false so
 * collected radios are preserved. Explicit assignment lists manage only the listed occurrences;
 * additional or captured radios are deliberately untouched. radioPriority and radioProfiles should change only when
 * adding a tested carried-radio profile. A profile is [class, mode, default ear sequence, maximum
 * channel, frequency range]. Frequency range is `[minimum MHz, maximum MHz, step kHz, ACRE pair
 * divisor]`; numbered channel profiles use `[]`. The divisor converts the second API pair value to
 * MHz (PRC-77 100, SEM70 1000). Modes are BLOCK_CHANNEL, CHANNEL or FREQUENCY.
 *
 * COMPATIBILITY - version is the parser schema and must remain 2 until the implementation changes.
 * prc343PresetPolicy is FULL_RANGE by default: every side retains all sixteen PRC-343 blocks while
 * the other radios continue to use the existing ACRE side presets. SIDE_ISOLATED applies those side
 * presets to the PRC-343 as well, reducing WEST/EAST/GUER to five blocks in exchange for frequency
 * separation. Existing non-343 side presets remain WEST default3, EAST default2, GUER default4 and
 * CIV default.
 */
createHashMapFromArray [
    ["version", 2],
    ["enabled", true],                    // MISSION MAKER: false disables all replacement ACRE setup.
    ["strict", true],                     // ADVANCED: reject explicit PRC-343 assignment collisions.
    ["prc343PresetPolicy", "FULL_RANGE"], // MISSION MAKER: FULL_RANGE (16 blocks) or SIDE_ISOLATED (5 combat-side blocks).
    ["retuneOnGroupChange", false],       // ADVANCED: true reapplies the current group's plan after a group change.
    ["namedDisplays", true],              // MISSION MAKER: label supported physical radio preset channels.
    ["notifyAssignmentProblems", true],   // MISSION MAKER: show a local WMP card when configured assignments cannot apply.
    ["radioPriority", ["ACRE_PRC152", "ACRE_PRC148", "ACRE_PRC117F", "ACRE_BF888S", "ACRE_SEM52SL", "ACRE_PRC77", "ACRE_SEM70"]],
    ["radioProfiles", [
        ["ACRE_PRC343", "BLOCK_CHANNEL", ["LEFT", "RIGHT", "BOTH"], 256, []],
        ["ACRE_PRC148", "CHANNEL", ["RIGHT", "LEFT", "BOTH"], 32, []],
        ["ACRE_PRC152", "CHANNEL", ["RIGHT", "LEFT", "BOTH"], 100, []],
        ["ACRE_PRC117F", "CHANNEL", ["BOTH", "RIGHT", "LEFT"], 100, []],
        ["ACRE_BF888S", "CHANNEL", ["RIGHT", "LEFT", "BOTH"], 16, []],
        ["ACRE_SEM52SL", "CHANNEL", ["RIGHT", "LEFT", "BOTH"], 13, []],
        ["ACRE_PRC77", "FREQUENCY", ["RIGHT", "LEFT", "BOTH"], 0, [30, 75.95, 50, 100]],
        ["ACRE_SEM70", "FREQUENCY", ["RIGHT", "LEFT", "BOTH"], 0, [30, 79.975, 25, 1000]]
    ]],
    ["radioOverrides", [                 // MISSION MAKER: optional UID, editor-variable or role-specific replacement plans.
        // [["ROLE", "JTAC"], [["ACRE_PRC152", 1, "AIRGND", "RIGHT"]]]
    ]],
    ["sides", [                          // MISSION MAKER: side preset, logical nets and group allocations.
        ["WEST", "default3", [
            ["PLT1", "PLATOON 1", [["ACRE_PRC77", 31.00], ["ACRE_SEM70", 34.000]]],
            ["PLT2", "PLATOON 2", [["ACRE_PRC77", 31.05], ["ACRE_SEM70", 34.025]]],
            ["PLT3", "PLATOON 3", [["ACRE_PRC77", 31.10], ["ACRE_SEM70", 34.050]]],
            ["COY", "COMPANY", [["ACRE_PRC77", 31.15], ["ACRE_SEM70", 34.075]]],
            ["AIRGND", "AIR-GND", [["ACRE_PRC77", 31.20], ["ACRE_SEM70", 34.100]]],
            ["AIR", "AIR-AIR", [["ACRE_PRC77", 31.25], ["ACRE_SEM70", 34.125]]],
            ["CAS1", "CAS 1", [["ACRE_PRC77", 31.30], ["ACRE_SEM70", 34.150]]],
            ["CAS2", "CAS 2", [["ACRE_PRC77", 31.35], ["ACRE_SEM70", 34.175]]],
            ["CFF1", "CFF 1", [["ACRE_PRC77", 31.40], ["ACRE_SEM70", 34.200]]],
            ["CFF2", "CFF 2", [["ACRE_PRC77", 31.45], ["ACRE_SEM70", 34.225]]],
            ["CONVOY", "CONVOY 1", [["ACRE_PRC77", 31.50], ["ACRE_SEM70", 34.250]]]
        ], [
            ["VIKING-1-1", ["PLT1", "AIRGND"], [1, 1], []],
            ["VIKING 5", ["COY", "AIRGND"], [1, 5], []],
            ["VIKING 3.2", ["PLT3", "AIRGND"], [3, 2], []],
            ["BANSHEE", ["AIRGND", "AIR"], [4, 1], []]
        ]],
        ["EAST", "default2", [], []],
        ["GUER", "default4", [], []],
        ["CIV", "default", [], []]
    ]],
    ["babel", createHashMapFromArray [
        ["enabled", false],                 // MISSION MAKER: enable ACRE Babel language simulation.
        ["languages", [["en", "English"]]], // MISSION MAKER: ordered [stable ID, display name] pairs.
        ["sideDefaults", [["WEST", ["en"], "en"], ["EAST", ["en"], "en"], ["GUER", ["en"], "en"], ["CIV", ["en"], "en"]]],
        ["unitOverrides", []],              // MISSION MAKER: optional UID/unit multilingual overrides.
        ["changeOnSideChange", false],      // ADVANCED: true replaces learned languages after a side change.
        ["followPlayerUnit", true]          // ADVANCED: reapply after player-object replacement.
    ]]
]
