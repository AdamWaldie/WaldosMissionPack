/*
 * Author: WaldoTheWarfighter
 * Lists every pure-data WMP feature configuration in deterministic load order. Add a new feature
 * configuration here; do not call it directly from an init file or place lifecycle code in it.
 *
 * Arguments: None.
 * Return Value: ARRAY of STRING mission-relative configuration paths.
 *
 * Example: private _files = call compile preprocessFileLineNumbers "MissionConfig\featureConfigManifest.sqf";
 * Result: returns the ordered config paths that each lifecycle scope asks the loader to consume.
 * Current caller: Waldo_fnc_LoadFeatureConfigs for SHARED, SERVER and PLAYER_LOCAL scopes.
 *
 * ACTIVATION MODEL: INFRASTRUCTURE ONLY. This file enables no gameplay feature and contains no
 * mission settings. Do not add setup calls, variables, waits or event handlers here.
 *
 * EDIT FOR A NORMAL MISSION: nothing.
 * LEAVE ALONE UNLESS EXTENDING/TESTING: the complete ordered file list.
 * CUSTOM CALLS: none. Add/reorder an entry only when introducing a new semantic config file and its
 * loader, documentation and regression coverage. ACRE remains separate because pre-init consumes it.
 *
 * HOW TO READ THE DATA BELOW: each string is a mission-relative pure-data config path. Order is
 * deterministic but settings in different files must not depend on it. Do not add acreConfig.sqf:
 * ACRE pre-init must read it before this ordinary SHARED/SERVER/PLAYER_LOCAL loader lifecycle.
 *
 * SETTING-BY-SETTING GUIDE: there are no mission settings in this file. Every row is an
 * infrastructure path. Ordinary mission makers should not add, remove, rename or reorder rows.
 * A new path is valid only when a new pure-data config file, loader scope, documentation page,
 * generated-audit copy and regression coverage are introduced together.
 */
[
    "MissionConfig\persistenceConfig.sqf",
    "MissionConfig\interfaceConfig.sqf",
    "MissionConfig\aiConfig.sqf",
    "MissionConfig\airOperationsConfig.sqf",
    "MissionConfig\logisticsConfig.sqf",
    "MissionConfig\environmentConfig.sqf",
    "MissionConfig\electronicWarfareConfig.sqf",
    "MissionConfig\missionSystemsConfig.sqf"
]
