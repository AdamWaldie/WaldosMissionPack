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
 * SETTING-BY-SETTING GUIDE - SHARED SIDE CHANNEL SETS (COOPERATIVE / MULTI-FACTION MISSIONS)
 * - Want two or more sides to just fully talk to each other - a co-op mission where WEST and GUER are
 *   both player-controlled coalition partners, not one bridge channel at a time like jointNets below?
 *   Give the sides you want joined the SAME preset, and set one of them (any side but the one holding
 *   the real channel list) to `"INHERIT:<SIDE>"` instead of writing its own nets array:
 *   `["GUER", "default3", "INHERIT:WEST", [...GUER's own groups...]]`
 *   Now every channel WEST has - PLT1, COY, AIRGND, whichever nets you've defined - GUER has too, same
 *   real frequency, same channel label, automatically; add a channel to WEST later and GUER gets it too
 *   with no further edits. Groups still stay separate per side (your WEST and GUER units are still
 *   different Eden groups), only the channel list itself is shared. Inherit directly from the side
 *   that defines the real channel list - chaining (a side inheriting from a side that itself inherits)
 *   is not supported and is rejected at validation, same as a side inheriting from itself or from an
 *   unknown side.
 *
 * SETTING-BY-SETTING GUIDE - JOINT RADIO NETS
 * - jointNets: [] by default (no cross-side bridging). Each row is
 *   ["netId", "label", "radio family", shared frequency, [["side", channel], ...]] - deliberately the
 *   same [key, label, family, value] shape an ordinary named net uses (label right after the id), with
 *   the per-side channel list appended after. "" for label means none. Frequency is the thing
 *   genuinely shared across sides; channel NUMBERS stay per-side, since a channel number only means
 *   something on that side's own preset - each side can therefore use whichever of its own free
 *   channels it likes for the bridge. A non-empty label is written to the physical PRC-148/152/117F
 *   channel display (same 12-character safe-charset rule as an ordinary named net's label) so the
 *   shared channel visibly reads as e.g. "COALITION" instead of just a plain number - do NOT also add
 *   a matching entry in that side's own nets array to try to label it the old way; that is rejected as
 *   a channel collision, the label field replaces that need entirely. Only CHANNEL-mode radio families
 *   are supported (PRC_LR, BF888, SEM52) - PRC-343
 *   (BLOCK_CHANNEL) and PRC-77/SEM70 (FREQUENCY, no channel concept - their preset value already IS
 *   the raw frequency) are rejected at validation with a clear reason; the label itself only applies
 *   to PRC_LR (BF888/SEM52 radios have no on-screen display field, same as ordinary named nets). A
 *   joint net is referenceable by its own netId from a group's assignment rows exactly like an
 *   ordinary named net - ["ACRE_PRC152", "ALL", "GAME_CONTROL", "RIGHT"] resolves to whichever channel
 *   that side's own [side, channel] entry gave it. A joint net's id must be unique across every
 *   jointNets row (it is now a real lookup key, not just a diagnostics label) and cannot reuse a key
 *   already used by that side's own ordinary nets; both are rejected at validation with a clear
 *   reason. There is no in-mission Zeus toggle for a joint net yet; it is mission-start configuration
 *   only. The shared frequency itself is only checked for being a positive number - ACRE2 has no
 *   documented tunable range for PRC_LR/BF888/SEM52 and its own API stores whatever value it is given,
 *   so a wrong but plausible-looking MHz figure will not be caught. Confirm in-game that both sides
 *   actually hear each other on the channel you picked.
 *
 * SETTING-BY-SETTING GUIDE - NORMAL MISSION SETTINGS
 * - enabled: master switch for WMP's replacement ACRE lifecycle.
 * - prc343PresetPolicy: FULL_RANGE keeps all 16 blocks; SIDE_ISOLATED uses ACRE side presets and
 *   gives combat sides five blocks. FULL_RANGE does not provide side frequency isolation.
 * - namedDisplays: labels PRC-148/152/117F channels without changing their frequencies.
 * - sides: [side, official ACRE preset, nets, groups]. Keep the shipped official preset per side.
 * - babel: language content and defaults. It remains inert while babel.enabled is false.
 * - notifyAssignmentProblems: true warns affected players when their authored baseline cannot apply.
 * - radioOverrides: optional side-scoped UID, Eden Variable Name or role exceptions.
 * - rackProfiles: reusable vehicle/object rack setups. Beginners may use the supplied examples.
 * - additionalRadioProfiles: advanced definitions for tested third-party carried radios only.
 *
 * NETS
 * Every named net has exactly one value.
 * A net is [stable key, display label, radio family, one value]. It never contains a different
 * channel per radio. PRC_LR means PRC-148/152/117F using the same side-preset channel. BF888 and
 * SEM52 are separate channel families. LEGACY_VHF is a frequency shared by PRC-77 and SEM70.
 * A net is valid when at least one radio in its family supports the value. Assigning that net to a
 * less-capable family member is rejected and diagnosed for that specific radio.
 *
 * RADIO COMPATIBILITY - READ BEFORE ADDING OR REUSING A NET:
 * - ACRE_PRC343 uses [block, channel]. It does not use the named long-range net rows.
 * - ACRE_PRC148, ACRE_PRC152 and ACRE_PRC117F use numbered channels. Matching channel numbers on
 *   their official side presets are interoperable, so they may share PLT/AIR/CAS nets.
 * - ACRE_BF888S is a 16-channel radio in a different band. Give it a BF-only net such as BF_HANDHELD.
 * - ACRE_SEM52SL is a 12-channel radio in a different band. Give it a SEM-only net such as SEM_HANDHELD.
 * - ACRE_PRC77 and ACRE_SEM70 use explicit MHz. They may share a net only where that frequency is
 *   valid for both radios; 51.000 MHz is a valid shared example.
 * - Unknown and vehicle-rack radios are deliberately preserved by the carried-radio scan.
 *   Vehicle-mounted racks use the separate rackProfiles section below plus a simple object Init
 *   call such as `[this, "COMMAND_VEHICLE"] call Waldo_fnc_ACRE2RackSetup;`.
 * A PRC-152 cannot consume BF_HANDHELD or VHF_COMMON even when the number happens to fit. Diagnostics name
 * the group, radio occurrence, requested net, expected family and invalid range when setup is wrong.
 *
 * GROUPS AND RADIO ASSIGNMENTS
 * A group is [editor group ID, assignment rows]. Every radio uses the same assignment shape:
 * [base class, "ALL" or same-type occurrence, target, ear]. "ALL" is the readable default for every
 * carried radio of that class. When duplicate radios differ, use numbered rows for each one instead;
 * never combine ALL and numbered rows for the same class. PRC-343 is no longer a disconnected group field: its target is
 * [block,channel], and [] asks WMP to infer the slot from the callsign. LEFT, RIGHT and BOTH/CENTER
 * work independently on every radio, including multiple PRC-343s. PTT, volume and speaker settings
 * remain player-owned. A radio without a matching ALL or numbered row is preserved unchanged.
 *
 * OVERRIDES
 * radioOverrides entries are [side, [UID|VARIABLE|ROLE, value], MERGE|REPLACE, assignments]. MERGE
 * replaces matching ALL rows and preserves the rest. Numbered exceptions use REPLACE with a complete
 * explicit radio list, avoiding a hidden ALL-versus-number precedence rule.
 * Side scoping prevents a net from another side being accepted accidentally.
 *
 * ADVANCED EXTENSION
 * additionalRadioProfiles is only for a tested third-party carried radio. Entry format is
 * [class, BLOCK_CHANNEL|CHANNEL|FREQUENCY, default ears, maximum channel, frequency range, family]. WMP's
 * built-in ACRE profiles live in code and should not be copied here. Unknown radios and racks are
 * preserved. WMP does not retune on group changes or poll radios during play.
 *
 * HOW TO READ THE DATA BELOW:
 * This file is returned directly as one HashMap, so each top-level row is `[setting key, value]`.
 * Side rows are `[side ID, official ACRE preset, nets ARRAY, groups ARRAY]`. Net rows are
 * `[net key, display label, radio family, one channel/frequency value]`. Group rows are
 * `[editor groupId, assignment rows]`.
 * Matching ignores capitalization and common callsign separators: spaces, hyphens, underscores and
 * dots. `VIKING-2-3`, `Viking 2-3` and `viking_2_3` therefore select the same group row.
 * Assignment rows are `[base radio class, "ALL" or same-type occurrence starting at 1, target, ear]`.
 * `target` is a net key or a direct channel/frequency supported by that profile; `ear` is LEFT,
 * RIGHT or BOTH. Radios not present in a player's inventory are simply skipped.
 * Babel rows are also positional: language `[internal ID, display name]`, side default
 * `[side, understood language IDs, initial speaking ID]`, and unit override
 * `[[UID|VARIABLENAME, selector value], understood IDs, initial speaking ID]`. The speaking ID must
 * exist in the understood list. changeOnSideChange=false preserves learned languages; followPlayerUnit=true
 * reapplies the assignment when respawn replaces the local player object.
 *
 * WORKED EXAMPLES:
 * `['PLT1','PLATOON 1','PRC_LR',2]` means the one PLATOON 1 value is channel 2 for compatible
 * PRC-148/152/117F radios. `['ACRE_PRC152','ALL','PLT1','RIGHT']` puts every carried 152 on PLT1
 * in the right ear. To make two 152s differ, use occurrence 1 for PLT1 and occurrence 2 for AIRGND
 * instead of ALL. A PRC-343 target
 * `[2,3]` explicitly means Block 2, Channel 3; `[]` asks WMP to infer it from a
 * callsign such as Viking 2-3, otherwise WMP uses deterministic collision-safe allocation.
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

    // SETTING: readinessTimeoutSeconds (ADVANCED TUNING)
    // WHAT IT CHANGES: how long WMP waits for ACRE2 to finish converting a joining player's carried
    // radios to unique IDs (acre_api_fnc_isInitialized) before giving up on that attempt and retrying.
    // A heavy modset, a slow terrain (large ACE advanced_ballistics initialization is a known
    // contributor), or a loaded server can legitimately push this past the default. When this window
    // expires before ACRE finishes, whatever a unit's Eden "ACRE Radio Setup" attribute applied is
    // left in place until the automatic retry catches up - it is not a permanent loss, but it is a
    // visible delay worth tuning out on a mission that consistently needs longer.
    // VALUES: seconds, default 120. Raise it if WMP Diagnostics or RPT repeatedly shows
    // "ACRE did not finish converting carried radios to unique IDs within N seconds" on this mission.
    // EXAMPLE/RESULT: 180 gives a heavy-modset mission an extra minute before WMP retries.
    ["readinessTimeoutSeconds", 120],

    // SETTING: jointNets
    // WHAT IT CHANGES: deliberately bridges specific radio channels across chosen sides for an
    // operation, without touching WMP's ordinary per-side net isolation everywhere else.
    // VALUES: [] for none, or one or more joint net rows.
    // DEFAULT: a GAME CONTROL net at channel 99 on every side, for admin/GM/out-of-character use -
    // any player who manually switches a PRC-152 or PRC-117F to channel 99 reaches it, on any side.
    // Nothing assigns it to anyone's radio automatically; add a group assignment row referencing its
    // netId, exactly like an ordinary named net, if you want it preset for specific players:
    // ["ACRE_PRC152", "ALL", "GAME_CONTROL", "RIGHT"]. PRC-148 cannot reach channel 99 at all (its
    // preset only has 32 channels); PRC-152/117F support up to 100. Delete this row (or replace it
    // with []) if you don't want a shared admin channel.
    // OTHER EXAMPLE: a WEST/EAST/GUER joint command net on PRC_LR at 45.500 MHz, each side free to
    // place it on whichever of its own channels is open, labelled "COALITION" on the physical display:
    // ["JOINT_CMD", "COALITION", "PRC_LR", 45.500, [["WEST", 13], ["EAST", 6], ["GUER", 6]]]
    // RESULT: [] means no cross-side bridging exists; WMP's normal per-side isolation is unchanged.
    ["jointNets", [
        ["GAME_CONTROL", "GAME CONTROL", "PRC_LR", 99.000, [["WEST", 99], ["EAST", 99], ["GUER", 99], ["CIV", 99]]]
    ]],

    // SETTING: additionalRadioProfiles (ADVANCED)
    // WHAT IT CHANGES: teaches WMP how to configure a tested third-party carried radio.
    // VALUES: [] for none, or documented profile rows. Beginners should leave this empty.
    // EXAMPLE: a channel radio profile would look like:
    // ["RADIO_CLASSNAME", "CHANNEL", ["RIGHT", "LEFT"], MAXIMUM_CHANNEL, [], "FAMILY_NAME"]
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
                ["ACRE_PRC152", "ALL", "AIRGND", "RIGHT"] // every carried PRC-152 -> AIRGND -> right ear.
            ]
        ]
        */
    ]],

    // SETTING: sides
    // WHAT IT CHANGES: defines each side's available radio nets and maps Eden groups onto them.
    // VALUES: one four-field side block for WEST, EAST, GUER and/or CIV.
    // EXAMPLE/RESULT: the WEST block below gives matching WEST groups the defined starting nets.
    // A side you don't need can be left out of this array entirely (not just given empty [] nets/
    // groups) - e.g. a WEST-only mission can delete the EAST/GUER/CIV blocks below completely. Players
    // on an omitted side simply get no named-channel setup and keep whatever radios they carried, on
    // that side's own correct official ACRE preset (WMP still resolves it correctly even with no row
    // present). This is different from jointNets/INHERIT below, which need every side they reference
    // to actually be defined here.
    // SIDE SETUP.
    // Each side block is: [SIDE NAME, OFFICIAL ACRE PRESET, NETS, GROUPS].
    // A net is a named radio channel/frequency, OR the string "INHERIT:<SIDE>" to reuse another side's
    // nets array word-for-word (see the SHARED SIDE CHANNEL SETS guide above) - both sides must then
    // use the same preset. A group chooses which nets its carried radios use.
    // COOPERATIVE-MISSION EXAMPLE (illustrative - edit GUER's own block below to use this, do not
    // paste this line in as-is): make GUER fully share WEST's channels instead of having its own, so
    // WEST and GUER players can always talk to each other.
    // ["GUER", "default3", "INHERIT:WEST", [ ["ALLY-1-1", [["ACRE_PRC152", "ALL", "PLT1", "RIGHT"]]] ]],
    ["sides", [
        [
            "WEST",      // 0: applies to BLUFOR players.
            "default3",  // 1: BLUFOR's official ACRE preset. Do not invent or copy another preset.
            [ // 2: NETS. Row parameters: [internal key, player-facing label, compatible radio family, one value].
                ["PLT1", "PLATOON 1", "PRC_LR", 2],     // PRC-148/152/117F channel 2.
                ["PLT2", "PLATOON 2", "PRC_LR", 3],     // PRC-148/152/117F channel 3.
                ["PLT3", "PLATOON 3", "PRC_LR", 4],     // PRC-148/152/117F channel 4.
                ["COY", "COMPANY", "PRC_LR", 5],        // PRC long-range family channel 5.
                ["AIRGND", "AIR-GND", "PRC_LR", 6],     // PRC long-range family channel 6.
                ["AIR", "AIR-AIR", "PRC_LR", 7],        // PRC long-range family channel 7.
                ["CAS1", "CAS 1", "PRC_LR", 8],         // PRC long-range family channel 8.
                ["CAS2", "CAS 2", "PRC_LR", 9],         // PRC long-range family channel 9.
                ["CFF1", "CFF 1", "PRC_LR", 10],        // PRC long-range family channel 10.
                ["CFF2", "CFF 2", "PRC_LR", 11],        // PRC long-range family channel 11.
                ["CONVOY", "CONVOY", "PRC_LR", 12],     // PRC long-range family channel 12.
                ["BF_HANDHELD", "BF HANDHELD", "BF888", 6], // BF-888S handheld net, channel 6.
                ["SEM_HANDHELD", "SEM HANDHELD", "SEM52", 3], // SEM52SL handheld net, channel 3.
                ["VHF_COMMON", "VHF COMMON", "LEGACY_VHF", 51.000] // PRC-77/SEM70 shared 51 MHz net.
            ],
            [ // 3: GROUPS. Each row is [editor groupId, assignment rows].
                [
                    "VIKING 2-3", // TestMission squad; matches common separator/capitalisation variants.
                    [ // [radio class, "ALL" or occurrence number, net/direct value, LEFT/RIGHT/BOTH].
                        ["ACRE_PRC343", 1, [2, 3], "LEFT"],     // first 343: Block 2/Ch 3, left ear. Use [] for callsign inference.
                        ["ACRE_PRC343", 2, [2, 4], "RIGHT"],    // second 343: Block 2/Ch 4, right ear.
                        ["ACRE_PRC148", "ALL", "PLT1", "RIGHT"],
                        ["ACRE_PRC152", 1, "PLT1", "RIGHT"],  // first 152.
                        ["ACRE_PRC152", 2, "AIRGND", "LEFT"], // second 152.
                        ["ACRE_PRC117F", "ALL", "PLT1", "BOTH"],
                        ["ACRE_BF888S", "ALL", "BF_HANDHELD", "LEFT"],
                        ["ACRE_SEM52SL", "ALL", "SEM_HANDHELD", "LEFT"],
                        ["ACRE_PRC77", "ALL", "VHF_COMMON", "RIGHT"],
                        ["ACRE_SEM70", "ALL", "VHF_COMMON", "RIGHT"]
                    ]
                ],
                ["VIKING 2-7", [["ACRE_PRC343", 1, [2, 7], "LEFT"], ["ACRE_PRC152", 1, "COY", "RIGHT"], ["ACRE_PRC152", 2, "AIRGND", "LEFT"], ["ACRE_PRC117F", "ALL", "COY", "BOTH"]]],
                ["VIKING 3.2", [["ACRE_PRC343", "ALL", [], "LEFT"], ["ACRE_PRC148", "ALL", "PLT3", "RIGHT"], ["ACRE_PRC152", "ALL", "PLT3", "RIGHT"]]],
                ["BANSHEE", [["ACRE_PRC343", "ALL", [], "LEFT"], ["ACRE_PRC148", "ALL", "AIRGND", "RIGHT"], ["ACRE_PRC152", 1, "AIRGND", "RIGHT"], ["ACRE_PRC152", 2, "AIR", "LEFT"]]]
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

    // SETTING: rackProfiles (OPTIONAL, AFTER THE RADIO NETS ABOVE)
    // Rack assignments deliberately live after `sides`: their friendly net keys (COY, AIRGND,
    // PLT1, etc.) refer back to the single channel/frequency definitions above. Configure player
    // radios first, then reuse those exact nets here for vehicle/object racks.
    // WHAT IT CHANGES: defines reusable named starting setups for ACRE racks. Nothing happens merely
    // because a profile exists here: place its call in the target vehicle/object's Eden Init field.
    // SIMPLE CALL: [this, "EXISTING_RACKS_COY"] call Waldo_fnc_ACRE2RackSetup;
    // MIXED CALL: [this, "COMMAND_VEHICLE", [["assignments", [["ALL", "AIRGND"]]]]] call Waldo_fnc_ACRE2RackSetup;
    // The mixed call loads COMMAND_VEHICLE, then replaces that profile's assignments with the inline
    // row. This is explicit top-level replacement, not a hidden array merge.
    //
    // Each profile is ["UNIQUE_PROFILE_NAME", SETTINGS]. SETTINGS supports:
    // - preset: optional existing ACRE preset name, applied BEFORE rack initialisation. Leave this
    //   as "" to reuse the preset already configured for netSide below (WEST uses default3, etc.).
    //   Enter a preset explicitly only when this rack needs a deliberately different complete
    //   channel/frequency programme, especially for PRC-77 and SEM70 racks.
    // - netSide: AUTO, WEST, EAST, GUER or CIV. AUTO uses the vehicle class side, then accepts a net
    //   key only when exactly one compatible side defines it. Set this explicitly on ambiguous props.
    // - addRacks: optional physical rack definitions. Each is [rack class, named rack settings].
    // - assignments: optional tuning/replacement jobs after racks exist and synchronize. The target
    //   should normally be a net key from the sides section above, e.g. "PLT1" or "AIRGND". WMP
    //   checks that the mounted radio belongs to that net's radio family, then uses its one value.
    //
    // addRacks named settings:
    // - count: desired TOTAL racks of this class on the object, not "add this many". That makes a
    //   retry safe. count=1 adds one only when the object currently has no rack of that class.
    // - displayName / shortName: ACE interaction names. ACRE permits 1-4 shortName characters.
    // - removable: whether users/scripts may remove the mounted radio later.
    // - access: ACRE access positions. ["inside"] is the safest beginner default; ["external"] is
    //   useful for a radio table or command post accessible while standing beside it.
    // - disabled: positions denied access; [] denies none of the otherwise allowed positions.
    // - mountedRadio: compatible base radio or "" for an empty rack.
    // - components: advanced ACRE component classes; [] uses no extra authored component.
    // - intercoms: connected ACRE intercom IDs, e.g. ["intercom_1"], or [] for none.
    //
    // assignment row: [RACK SELECTOR, NET KEY OR CHANNEL, OPTIONAL RADIO ACTION]
    // Selectors: "ALL" for tune-only work on every already-mounted radio; rack number starting at
    // 1; "ACRE_VRC110" for every rack of that type; or
    // ["ACRE_VRC110", 1] for the first rack of that type. Type selectors survive unrelated rack
    // order changes and are recommended. Use a central net key such as "AIRGND" whenever possible;
    // a number is a direct channel override. -1 leaves tuning unchanged. The optional third value is
    // a compatible radio classname, "UNMOUNT_RADIO", "REMOVE_RACK", or "" for no hardware change.
    // Compatible pairs are VRC64/PRC77, VRC103/PRC117F, VRC110/PRC152, VRC111/PRC148, SEM90/SEM70.
    //
    // COPYABLE SELECTOR EXAMPLES (put one or more rows inside a profile's assignments array):
    // ["ALL", "COY"]                              // tune every compatible mounted channel radio.
    // [1, "COY"]                                  // tune ACRE's first rack; simple, but rack order can change.
    // ["ACRE_VRC110", "AIRGND"]                  // tune every VRC-110/PRC-152 on this object.
    // [["ACRE_VRC110", 1], "AIRGND"]             // tune only the first VRC-110; recommended selector.
    // [["ACRE_VRC110", 1], 6]                    // direct channel 6; a named net is easier to maintain.
    //
    // COPYABLE HARDWARE-ACTION EXAMPLES (the selected rack must be removable for these changes):
    // [["ACRE_VRC110", 1], "AIRGND", "ACRE_PRC152"] // mount/replace with a PRC-152, then tune it.
    // [["ACRE_VRC110", 1], -1, "UNMOUNT_RADIO"]       // remove its radio; -1 means do not retune.
    // [["ACRE_VRC110", 1], -1, "REMOVE_RACK"]         // remove the complete physical rack.
    // Never use "ALL" with a hardware action: WMP deliberately rejects that ambiguous request.
    //
    // ALL SUPPORTED BUILT-IN PHYSICAL PAIRS (copy one row into addRacks and use its matching radio):
    // ["ACRE_VRC64",  [["count", 1], ["displayName", "PRC-77 Rack"],  ["shortName", "77"],
    //                   ["removable", true], ["access", ["inside"]], ["disabled", []],
    //                   ["mountedRadio", "ACRE_PRC77"],  ["components", []], ["intercoms", []]]]
    // ["ACRE_VRC103", [["count", 1], ["displayName", "PRC-117F Rack"],["shortName", "117"],
    //                   ["removable", true], ["access", ["inside"]], ["disabled", []],
    //                   ["mountedRadio", "ACRE_PRC117F"],["components", []], ["intercoms", []]]]
    // ["ACRE_VRC110", [["count", 1], ["displayName", "PRC-152 Rack"], ["shortName", "152"],
    //                   ["removable", true], ["access", ["inside"]], ["disabled", []],
    //                   ["mountedRadio", "ACRE_PRC152"], ["components", []], ["intercoms", []]]]
    // ["ACRE_VRC111", [["count", 1], ["displayName", "PRC-148 Rack"], ["shortName", "148"],
    //                   ["removable", true], ["access", ["inside"]], ["disabled", []],
    //                   ["mountedRadio", "ACRE_PRC148"], ["components", []], ["intercoms", []]]]
    // ["ACRE_SEM90",  [["count", 1], ["displayName", "SEM70 Rack"],   ["shortName", "SEM"],
    //                   ["removable", true], ["access", ["inside"]], ["disabled", []],
    //                   ["mountedRadio", "ACRE_SEM70"],  ["components", []], ["intercoms", []]]]
    // Use ["access", ["external"]] for a radio table, ["inside", "external"] for both, or
    // ["mountedRadio", ""] for an initially empty rack. PRC-77/SEM70 frequency programming must
    // come from a tested ACRE preset; it is not a numbered-channel assignment.
    ["rackProfiles", [
        [
            "EXISTING_RACKS_COY",
            [
                ["preset", ""], // Blank safely reuses WEST's configured default3 preset.
                ["netSide", "WEST"],
                ["addRacks", []],
                ["assignments", [["ALL", "COY"]]] // Reuse WEST COY (PRC_LR channel 5).
            ]
        ],
        [
            "COMMAND_VEHICLE",
            [
                ["preset", "default3"], // Existing ACRE preset, applied before initialization.
                ["netSide", "WEST"],
                ["addRacks", [
                    [
                        "ACRE_VRC110", // AN/VRC-110 hardware; accepts an ACRE_PRC152.
                        [
                            ["count", 1],
                            ["displayName", "Command Radio"],
                            ["shortName", "CMD"],
                            ["removable", true],
                            ["access", ["inside"]],
                            ["disabled", []],
                            ["mountedRadio", "ACRE_PRC152"],
                            ["components", []],
                            ["intercoms", []]
                        ]
                    ]
                ]],
                ["assignments", [
                    // Mounts the radio when the vehicle already has an empty VRC-110.
                    [["ACRE_VRC110", 1], "AIRGND", "ACRE_PRC152"] // WEST AIRGND, PRC_LR channel 6.
                ]]
            ]
        ],
        [
            "EXTERNAL_RADIO_POINT",
            [
                ["preset", "default3"],
                ["netSide", "WEST"],
                ["addRacks", [
                    ["ACRE_VRC103", [
                        ["count", 1], ["displayName", "Radio Point"], ["shortName", "RDO"],
                        ["removable", false], ["access", ["external"]], ["disabled", []],
                        ["mountedRadio", "ACRE_PRC117F"], ["components", []], ["intercoms", []]
                    ]]
                ]],
                ["assignments", [[["ACRE_VRC103", 1], "PLT1", "ACRE_PRC117F"]]]
            ]
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
