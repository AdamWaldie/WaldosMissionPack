/*
 * Author: WaldoTheWarfighter
 * Defines guarded presentation and timing defaults for Simple Dialogue and Advanced Conversations.
 * It contains data only: the dialogue component self-bootstraps and individual NPCs are configured
 * from Eden init fields, scripts, triggers or ZEN rather than from mission init event scripts.
 *
 * Schema: SHARED entries are [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 * Current caller: the WMP feature-config loader on every machine.
 *
 * Result: every registered NPC uses the retained timing and distance values without starting any
 * dialogue by itself. Current caller: Waldo_fnc_LoadFeatureConfigs in SHARED scope.
 *
 * ACTIVATION MODEL: CALL-DRIVEN OBJECT SETUP OR ZEN. This file never registers an NPC.
 * EDIT FOR A NORMAL MISSION: normally nothing; adjust reading speed only for a known audience need.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: punctuation, duration and distance safety bounds.
 * CUSTOM CALLS: use an NPC Eden init field, for example `[this,"CIVILIAN"] call Waldo_fnc_SimpleDialogue;`.
 * CUSTOMISATION GUIDE: MISSION MAKER may tune seconds per word and distances. ADVANCED TUNING covers
 * punctuation pauses, hard duration bounds and safe-zone-relative UI sizing.
 * HOW TO READ THE DATA BELOW: SHARED rows are guarded defaults loaded on every machine. They create
 * no actions, callbacks, threads or world state.
 * SETTING-BY-SETTING GUIDE: Waldo_Dialogue_SecondsPerWord is seconds added per word;
 * Waldo_Dialogue_MinimumLineSeconds and Waldo_Dialogue_MaximumLineSeconds clamp line duration;
 * Waldo_Dialogue_CommaPause and Waldo_Dialogue_TerminalPause add punctuation pauses;
 * Waldo_Dialogue_AudienceRadius selects subtitle/audio listeners; Waldo_Dialogue_InteractionDistance
 * shows the interaction; Waldo_Dialogue_CancelDistance ends an abandoned conversation;
 * Waldo_Dialogue_SubtitleMinimumWidth and Waldo_Dialogue_SubtitleMaximumWidth bound responsive subtitles;
 * Waldo_Dialogue_SubtitleMaximumHeight caps wrapped subtitle height;
 * Waldo_Dialogue_SubtitleTextScale sizes subtitle text;
 * Waldo_Dialogue_ChoiceMinimumWidth and Waldo_Dialogue_ChoiceMaximumWidth bound response panels;
 * Waldo_Dialogue_ChoiceMaximumHeight caps the scrollable response region;
 * Waldo_Dialogue_ChoiceMinimumRowHeight preserves a usable click target; and
 * Waldo_Dialogue_ChoiceTextScale sizes response and cancel text. All geometry values are fractions
 * of the current safe zone, with text wrapping and scrolling at the configured caps.
 *
 * Example: set Waldo_Dialogue_SecondsPerWord to 0.4 for faster subtitle pacing.
 */
createHashMapFromArray [
    ["shared", [
        ["Waldo_Dialogue_SecondsPerWord", 0.5],
        ["Waldo_Dialogue_MinimumLineSeconds", 1.5],
        ["Waldo_Dialogue_MaximumLineSeconds", 15],
        ["Waldo_Dialogue_CommaPause", 0.12],
        ["Waldo_Dialogue_TerminalPause", 0.25],
        ["Waldo_Dialogue_AudienceRadius", 10],
        ["Waldo_Dialogue_InteractionDistance", 3],
        ["Waldo_Dialogue_CancelDistance", 6],
        ["Waldo_Dialogue_SubtitleMinimumWidth", 0.22],
        ["Waldo_Dialogue_SubtitleMaximumWidth", 0.46],
        ["Waldo_Dialogue_SubtitleMaximumHeight", 0.20],
        ["Waldo_Dialogue_SubtitleTextScale", 0.90],
        ["Waldo_Dialogue_ChoiceMinimumWidth", 0.20],
        ["Waldo_Dialogue_ChoiceMaximumWidth", 0.34],
        ["Waldo_Dialogue_ChoiceMaximumHeight", 0.42],
        ["Waldo_Dialogue_ChoiceMinimumRowHeight", 0.038],
        ["Waldo_Dialogue_ChoiceTextScale", 0.90]
    ]],
    ["server", []],
    ["playerLocal", []],
    ["aliases", []],
    ["fallbacks", []],
    ["conditional", []]
]
