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
 * Result: returns the authored ACRE baseline as data; it does not directly retune a player's radios.
 * Current callers: automatic WMP ACRE pre-init, initServer.sqf and initPlayerLocal.sqf lifecycle.
 *
 * ACTIVATION MODEL: AUTOMATIC WHEN ENABLED.
 * EDIT FOR A NORMAL MISSION: enabled, prc343PresetPolicy, namedDisplays, sides, radioOverrides and Babel.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: strict and additionalRadioProfiles.
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
 * HOW TO READ THE DATA BELOW:
 * This file is returned directly as one HashMap, so each top-level row is `[setting key, value]`.
 * Side rows are `[side ID, official ACRE preset, nets ARRAY, groups ARRAY]`. Net rows are
 * `[net key, display label, tunings ARRAY]`; each tuning is `[base radio class, channel number]` for
 * channel radios or `[base radio class, MHz]` for frequency radios. Group rows are
 * `[editor groupId, ordered fallback net keys, PRC-343 [block,channel] or [], assignments]`.
 * Matching ignores capitalization and common callsign separators: spaces, hyphens, underscores and
 * dots. `VIKING-2-3`, `Viking 2-3` and `viking_2_3` therefore select the same group row.
 * Assignment rows are `[base radio class, same-type occurrence starting at 1, target, ear]`.
 * `target` is a net key or a direct channel/frequency supported by that profile; `ear` is LEFT,
 * RIGHT or BOTH. Radios not present in a player's inventory are simply skipped.
 *
 * WORKED EXAMPLES:
 * `['ACRE_PRC152', 2]` inside PLT1 means PLT1 uses channel 2 on every carried PRC-152 assigned
 * to that net. `['ACRE_PRC77', 34.000]` means tune the analogue PRC-77 to 34 MHz. A group row of
 * `['VIKING-1-1',['PLT1','AIRGND'],[],[]]` matches editor groupId VIKING-1-1, automatically derives
 * its PRC-343 block/channel from that callsign, and assigns each supported carried radio to the
 * first compatible named net. To give two PRC-152s different ears/nets, use assignments such as
 * `[['ACRE_PRC152',1,'PLT1','LEFT'],['ACRE_PRC152',2,'AIRGND','RIGHT']]`.
 *
 * PLAYER LOADOUT AND RESPAWN RULES:
 * ACRE's `_ID_n` class identifies a unique local physical radio and must never be persisted as an
 * inventory classname. Normal Save Respawn Loadout stores filtered base classes plus a separate
 * player-level radio snapshot by `[base class, same-type occurrence]`. After respawn creates fresh
 * IDs, WMP restores the channels/frequencies, ears, volume, supported audio source and selected
 * radio that existed when the player last saved. The authored side/group/role plan is used for the
 * initial setup and as a safe fallback when no usable snapshot exists; WMP does not repeatedly
 * police radios. INIDBI2 `Waldo_Persistence_SaveRadios = true` persists the same player-level state
 * across sessions. PTT keybind defaults are never changed by either path.
 * In short: this config is the starting state, not an ongoing enforcement policy. Players may alter
 * their radios and call Waldo_fnc_SaveLoadout again whenever that personal state should become their
 * new respawn condition.
 */
createHashMapFromArray [
    // SETTING: enabled
    // WHAT IT CHANGES: whether WMP supplies the starting ACRE radio setup.
    // VALUES: true = use this file; false = leave ACRE radios untouched.
    // EXAMPLE/RESULT: true gives joining players the side/group setup defined below.
    ["enabled", true],

    // SETTING: strict
    // WHAT IT CHANGES: how authoring mistakes such as duplicate explicit PRC-343 slots are handled.
    // VALUES: true = reject/report the mistake; false = retain it and warn. Beginners should keep true.
    // EXAMPLE/RESULT: true prevents two manually configured groups silently sharing one explicit slot.
    ["strict", true],

    // SETTING: prc343PresetPolicy
    // WHAT IT CHANGES: available PRC-343 blocks and whether opposing sides use separated presets.
    // VALUES: FULL_RANGE = blocks 1-16 on all sides; SIDE_ISOLATED = side separation but only blocks 1-5.
    // EXAMPLE/RESULT: FULL_RANGE allows a WEST assignment such as block 12/channel 6.
    ["prc343PresetPolicy", "FULL_RANGE"],

    // SETTING: namedDisplays
    // WHAT IT CHANGES: names shown on supported PRC-148, PRC-152 and PRC-117F radio displays.
    // VALUES: true or false. Naming does not alter the underlying frequencies.
    // EXAMPLE/RESULT: true lets channel 2 display PLATOON 1 when that label is configured below.
    ["namedDisplays", true],

    // SETTING: notifyAssignmentProblems
    // WHAT IT CHANGES: whether the affected player receives a WMP warning when setup fails.
    // VALUES: true or false.
    // EXAMPLE/RESULT: true reports a missing group mapping instead of failing silently.
    ["notifyAssignmentProblems", true],

    // SETTING: additionalRadioProfiles (ADVANCED)
    // WHAT IT CHANGES: teaches WMP how to configure a tested third-party carried radio.
    // VALUES: [] for none, or documented profile rows. Beginners should leave this empty.
    // EXAMPLE: a channel radio profile would look like:
    // ["RADIO_CLASSNAME", "CHANNEL", ["RIGHT", "LEFT"], MAXIMUM_CHANNEL, []]
    // RESULT: [] means unknown/third-party radios remain untouched.
    ["additionalRadioProfiles", []],

    // SETTING: radioOverrides (OPTIONAL PLAYER/ROLE EXCEPTIONS)
    // WHAT IT CHANGES: gives one side-specific UID, Eden variable or role a different starting setup.
    // VALUES: [] for no exceptions, or one/more four-field override blocks.
    // EXAMPLE/RESULT: the disabled example makes a WEST JTAC's first PRC-152 use AIRGND in right ear.
    // Leave this empty unless one person or role needs a different starting radio setup.
    // Remove the /* and */ around the example to enable it.
    ["radioOverrides", [
        /*
        [
            "WEST",                         // 0: side this exception belongs to.
            ["ROLE", "JTAC"],              // 1: match ROLE "JTAC". UID and VARIABLE are also supported.
            "MERGE",                        // 2: MERGE changes listed radios; REPLACE discards the group template first.
            [
                ["ACRE_PRC152", 1, "AIRGND", "RIGHT"] // first PRC-152 -> AIRGND net -> right ear.
            ]
        ]
        */
    ]],

    // SETTING: sides
    // WHAT IT CHANGES: defines each side's available radio nets and maps Eden groups onto them.
    // VALUES: one four-field side block for WEST, EAST, GUER and/or CIV.
    // EXAMPLE/RESULT: the WEST block below gives matching WEST groups the defined starting nets.
    // SIDE SETUP.
    // Each side block is: [SIDE NAME, OFFICIAL ACRE PRESET, NETS, GROUPS].
    // A net is a named radio channel/frequency. A group chooses which nets its carried radios use.
    ["sides", [
        [
            "WEST",      // 0: applies to BLUFOR players.
            "default3",  // 1: BLUFOR's official ACRE preset. Do not invent or copy another preset.
            [              // 2: NETS available to WEST groups.
                [
                    "PLT1",      // 0: short internal key used by group assignments below.
                    "PLATOON 1", // 1: player-facing name shown on supported radio displays/CEOI.
                    [             // 2: how each supported radio reaches this net.
                        ["ACRE_PRC148", 2],  // A PRC-148 uses its channel 2.
                        ["ACRE_PRC152", 2],  // A PRC-152 uses its channel 2.
                        ["ACRE_PRC117F", 2]  // A PRC-117F uses its channel 2.
                    ]
                ],
                [
                    "PLT2",      // internal net key used by group rows.
                    "PLATOON 2", // player-facing name.
                    [             // channel used by each listed radio type.
                        ["ACRE_PRC148", 3],  // PRC-148 channel 3.
                        ["ACRE_PRC152", 3],  // PRC-152 channel 3.
                        ["ACRE_PRC117F", 3]  // PRC-117F channel 3.
                    ]
                ],
                [
                    "PLT3",      // internal net key.
                    "PLATOON 3", // player-facing name.
                    [
                        ["ACRE_PRC148", 4], ["ACRE_PRC152", 4], ["ACRE_PRC117F", 4] // channel 4 on each listed radio.
                    ]
                ],
                [
                    "COY",     // internal net key.
                    "COMPANY", // player-facing name.
                    [
                        ["ACRE_PRC148", 5], ["ACRE_PRC152", 5], ["ACRE_PRC117F", 5] // company net: channel 5.
                    ]
                ],
                [
                    "AIRGND", // internal net key.
                    "AIR-GND", // player-facing name.
                    [
                        ["ACRE_PRC148", 6], ["ACRE_PRC152", 6], ["ACRE_PRC117F", 6] // air-to-ground net: channel 6.
                    ]
                ],
                [
                    "AIR",     // internal net key.
                    "AIR-AIR", // player-facing name.
                    [
                        ["ACRE_PRC148", 7], ["ACRE_PRC152", 7], ["ACRE_PRC117F", 7] // air-to-air net: channel 7.
                    ]
                ],
                [
                    "CAS1",  // internal net key.
                    "CAS 1", // player-facing name.
                    [
                        ["ACRE_PRC148", 8], ["ACRE_PRC152", 8], ["ACRE_PRC117F", 8] // first CAS net: channel 8.
                    ]
                ],
                [
                    "CAS2",  // internal net key.
                    "CAS 2", // player-facing name.
                    [
                        ["ACRE_PRC148", 9], ["ACRE_PRC152", 9], ["ACRE_PRC117F", 9] // second CAS net: channel 9.
                    ]
                ],
                [
                    "CFF1",  // internal net key.
                    "CFF 1", // player-facing name.
                    [
                        ["ACRE_PRC148", 10], ["ACRE_PRC152", 10], ["ACRE_PRC117F", 10] // first fires net: channel 10.
                    ]
                ],
                [
                    "CFF2",  // internal net key.
                    "CFF 2", // player-facing name.
                    [
                        ["ACRE_PRC148", 11], ["ACRE_PRC152", 11], ["ACRE_PRC117F", 11] // second fires net: channel 11.
                    ]
                ],
                [
                    "CONVOY", // internal net key.
                    "CONVOY", // player-facing name.
                    [
                        ["ACRE_PRC148", 12], ["ACRE_PRC152", 12], ["ACRE_PRC117F", 12] // convoy net: channel 12.
                    ]
                ],
                [
                    "BF_LOCAL", // internal net key.
                    "LOCAL BF", // player-facing name.
                    [
                        ["ACRE_BF888S", 4] // the BF-888S uses its own channel 4; this does not consume PRC channels.
                    ]
                ],
                [
                    "SEM_LOCAL", // internal net key.
                    "LOCAL SEM", // player-facing name.
                    [
                        ["ACRE_SEM52SL", 4] // the SEM52SL uses its own channel 4.
                    ]
                ],
                [
                    "LEGACY", // internal net key; rename this if a clearer mission name is available.
                    "LEGACY", // player-facing name.
                    [
                        ["ACRE_PRC77", 34.000], // frequency radio: tune PRC-77 to 34.000 MHz.
                        ["ACRE_SEM70", 34.000]   // frequency radio: tune SEM70 to the same 34.000 MHz.
                    ]
                ]
            ],
            [ // 3: GROUPS. The first text matches the group's Eden `groupId` (case/separators are ignored).
                [
                    "VIKING-1-1", // 0: Eden groupId. `Viking 1-1` also matches; change the words/numbers for your squad.
                    ["PLT1", "AIRGND", "BF_LOCAL", "SEM_LOCAL", "LEGACY"], // 1: preferred nets, in order.
                    [], // 2: empty = automatically choose this group's PRC-343 block/channel from its groupId.
                    []  // 3: empty = automatically assign carried supported radios to the first compatible net above.
                ],
                [
                    "VIKING 5",       // company/HQ groupId.
                    ["COY", "AIRGND"], // company first; air-ground is the next compatible choice.
                    [],                // automatic PRC-343 assignment.
                    []                 // automatic carried-radio assignment.
                ],
                [
                    "VIKING 3.2",       // third-platoon groupId example.
                    ["PLT3", "AIRGND"], // third-platoon net first.
                    [],                  // automatic PRC-343 assignment.
                    []                   // automatic other-radio assignments.
                ],
                [
                    "BANSHEE",         // aviation groupId example.
                    ["AIRGND", "AIR"], // air-ground first, then air-to-air.
                    [],                 // automatic PRC-343 assignment.
                    []                  // automatic other-radio assignments.
                ]
            ]
        ],
        [
            "EAST",              // OPFOR side.
            "default2",          // OPFOR's official ACRE preset.
            [],                   // no EAST nets supplied yet: add net rows using the WEST example.
            []                    // no EAST group mappings supplied yet.
        ],
        [
            "GUER",              // Independent side.
            "default4",          // Independent's official ACRE preset.
            [],                   // no Independent nets supplied yet.
            []                    // no Independent group mappings supplied yet.
        ],
        [
            "CIV",               // Civilian side.
            "default",           // Civilian's official ACRE preset.
            [],                   // no Civilian nets supplied yet.
            []                    // no Civilian group mappings supplied yet.
        ]
    ]],

    // SETTING: babel
    // WHAT IT CHANGES: which spoken languages players understand and initially speak.
    // VALUES: the HashMap below; its own enabled switch controls whether any language rule is applied.
    // EXAMPLE/RESULT: enabled=false keeps all example languages inactive without deleting the setup.
    // OPTIONAL ACRE BABEL LANGUAGE SYSTEM.
    // Babel changes which spoken languages players understand. It does not configure radio channels.
    ["babel", createHashMapFromArray [
        ["enabled", false], // false = Babel is disabled, even though examples remain below for future use.
        ["languages", [     // every language is [short internal ID, name shown to players].
            ["common", "Common"], // shared language understood by every side in the examples below.
            ["en", "English"],    // WEST-specific example language.
            ["ru", "Russian"],    // EAST-specific example language.
            ["fr", "French"],     // Independent-specific example language.
            ["ar", "Arabic"]      // Civilian-specific example language.
        ]],
        ["sideDefaults", [
            // Each row is [side, languages understood, language spoken initially].
            ["WEST", ["common", "en"], "en"], // WEST understands Common+English and initially speaks English.
            ["EAST", ["common", "ru"], "ru"], // EAST understands Common+Russian and initially speaks Russian.
            ["GUER", ["common", "fr"], "fr"], // Independent understands Common+French and initially speaks French.
            ["CIV", ["common", "ar"], "ar"]   // Civilians understand Common+Arabic and initially speak Arabic.
        ]],
        // OPTIONAL individual exception format. Rows are checked top-to-bottom; first match wins.
        // 0: selector <ARRAY> - ["UID", Steam UID] or ["VARIABLENAME", Eden Variable Name].
        //    "VARIABLE" remains an accepted short alias for "VARIABLENAME".
        // 1: understood languages <ARRAY of STRING language IDs>.
        // 2: initially spoken language <STRING>; must also appear in field 1.
        // UID example/result: this account understands three languages and initially speaks English.
        // [["UID", "7656119..."], ["common", "en", "ru"], "en"]
        // Variable-name example/result: the playable unit named interpreter_1 in Eden speaks Russian.
        // [["VARIABLENAME", "interpreter_1"], ["common", "en", "ru"], "ru"]
        // Variable-name matching uses vehicleVarName on the current player object. If respawn creates
        // a replacement unit, ensure the replacement retains that Variable Name.
        ["unitOverrides", []],
        ["changeOnSideChange", false], // false = changing side does not erase languages already assigned.
        ["followPlayerUnit", true]      // true = restore languages when respawn replaces the player's unit object.
    ]]
]
