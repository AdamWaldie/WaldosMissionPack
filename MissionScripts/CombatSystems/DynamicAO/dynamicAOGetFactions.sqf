/*
 * Author: WaldoTheWarfighter
 * Dynamic AO-specific alias of the shared faction-discovery primitive, kept for backward
 * compatibility with the documented public API and existing mission scripts. The scan itself lives
 * in Waldo_fnc_ResolveFactionCatalog (MissionScripts\CombatSystems\resolveFactionCatalog.sqf) so
 * Dynamic AA and other faction/unit-selection features share the exact same live modset scan
 * instead of each keeping their own copy.
 *
 * Arguments:
 * 0: allowed sides <ARRAY<SIDE>> (default [west,east,independent])
 *
 * Return Value:
 * Array of [side <SIDE>, faction classname <STRING>, label <STRING>]
 *
 * Current callers: DynamicAOZen and mission-maker validation scripts.
 *
 * Example:
 * [[east, independent]] call Waldo_fnc_DynamicAOGetFactions;
 */
params [["_allowedSides", [west, east, independent], [[]]]];
[_allowedSides] call Waldo_fnc_ResolveFactionCatalog
