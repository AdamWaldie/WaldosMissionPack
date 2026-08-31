/*
 * Author: WaldoTheWarfighter
 * Defines headless-client (HC) support defaults shared by every machine (server, players, and any
 * connected headless client itself all read the same SHARED config).
 *
 * Schema: each SHARED entry is [missionNamespace variable name, guarded default value].
 * Arguments: None.
 * Return Value: HASHMAP consumed by Waldo_fnc_LoadFeatureConfigs.
 *
 * Example: set Waldo_Headless_Enable to true once the manual HC test matrix
 * (wiki/Headless-Client-Support.md) has been run against your mission's mod set.
 * Result: a connected headless client self-registers and eligible AI groups migrate to it.
 * Current caller: Waldo_fnc_LoadFeatureConfigs from init.sqf using the SHARED scope.
 *
 * ACTIVATION MODEL: OFF BY DEFAULT. Waldo_fnc_HeadlessDetectLocal (init.sqf, every machine) and
 * Waldo_fnc_HeadlessRegisterClient (server-side) both refuse to do anything while Enable is false -
 * connecting a headless client to a mission that has not turned this on has no effect at all. This
 * is deliberately conservative: the system has not yet been verified against a live Arma 3 engine or
 * a connected headless client (see FEATURE_LOG.md's "Headless-client compatibility rework" entry),
 * so it ships requiring an explicit opt-in rather than activating automatically the moment a
 * headless client connects.
 *
 * EDIT FOR A NORMAL MISSION: Enable, once the live test matrix has been run for your mod set.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: the three pacing/settle-time values below, and Debug.
 * CUSTOM CALLS: none for normal use - a group opts itself out at any time with
 * `_group setVariable ["Waldo_Headless_ExcludeGroup", true];` (see wiki/Headless-Client-Support.md).
 *
 * HOW TO READ THE DATA BELOW:
 * Every `shared` row is `[variable name, guarded default]`. The loader installs it only when no
 * earlier mission value exists, on every machine - the server, every player, and any headless client
 * that connects, so all of them agree on the same Enable/timing values without needing a broadcast.
 *
 * SETTING-BY-SETTING GUIDE:
 * - Waldo_Headless_Enable (MISSION MAKER): master switch. False (default) makes headless-client
 *   detection and registration a complete no-op - connect an HC and nothing happens.
 * - Waldo_Headless_StartDelaySeconds (ADVANCED): no group migration begins before this much mission
 *   time has passed, even if a headless client registers earlier - gives other AI-setup
 *   infrastructure (a custom AI mod's own initial pass, WMP's own systems) a moment to finish first.
 * - Waldo_Headless_MinGroupAgeSeconds (ADVANCED): a group must have existed at least this long before
 *   it becomes eligible for migration - protects against outrunning a spawner script still
 *   configuring it.
 * - Waldo_Headless_MigrationPaceSeconds (ADVANCED): pause between each queued group migration -
 *   moving many groups in the same frame is a known source of a server hitch.
 * - Waldo_Headless_Debug (ADVANCED/TROUBLESHOOTING): off by default. Extends the one-line-per-event
 *   RPT trail every registration/rebalance/migration/disconnect already writes unconditionally with
 *   the noisier, genuinely optional detail (per-client load tables, exclusion-reason tallies) a
 *   mission maker only wants while actively diagnosing HC behaviour - see Waldo_fnc_HeadlessDebugLog.
 *   Toggle live in-mission with Waldo_fnc_HeadlessDebugToggle or the "Headless Client - Toggle Debug"
 *   ZEN module, no mission restart required. WMP routes output through its [WMP DIAG] RPT framing
 *   and notification-card conventions and makes the control available to assigned curators. Costs nothing
 *   when off (a single getVariable check at each of the four event sites).
 *
 * BEGINNER TEST: after running the manual HC matrix once, set Enable to true, connect one headless
 * client, and confirm it appears in the "headless-clients" diagnostics row
 * (Waldo_fnc_HeadlessGetDiagnostics / Waldo_fnc_RunDiagnostics) after the start delay elapses. Set
 * Debug to true (or toggle it live from Zeus) to also see per-pass detail in RPT/hosted-server chat.
 */
createHashMapFromArray [
    ["featureFamilies", ["Headless Client Support"]],
    ["shared", [
        // MISSION MAKER: master switch. Off by default until the live HC test matrix has been run.
        ["Waldo_Headless_Enable", false],
        // ADVANCED TUNING: startup grace period, per-group settle time, and inter-migration pacing.
        ["Waldo_Headless_StartDelaySeconds", 30],   // SECONDS: no migration begins before this.
        ["Waldo_Headless_MinGroupAgeSeconds", 10],  // SECONDS: minimum group age before eligibility.
        ["Waldo_Headless_MigrationPaceSeconds", 3], // SECONDS: pause between each queued migration.
        // TROUBLESHOOTING: extended per-event debug detail. Off by default; toggle live from Zeus.
        ["Waldo_Headless_Debug", false]
    ]]
]
