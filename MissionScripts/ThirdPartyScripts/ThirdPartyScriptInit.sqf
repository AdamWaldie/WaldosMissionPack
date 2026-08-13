/*
 * Author: WaldoTheWarfighter
 * Provides one optional entry point for the legacy player-marker integration. Native WMP Headless
 * Client support is configured separately in MissionConfig\headlessConfig.sqf; this file does not
 * enable it. The shipped calls remain commented out until a mission maker deliberately enables them.
 *
 * Locality and repeat/JIP behaviour: execute from init.sqf only when the optional local marker
 * overlay is required. The marker script manages its own local replacement/stop behaviour. No
 * authoritative server state or JIP replay is created here.
 *
 * Arguments: None.
 * Return Value: Nothing.
 * Current callers: optional mission-maker call from init.sqf; disabled in the release template.
 *
 * Example:
 * [] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
 * Result: executes only the integrations uncommented below; the release default does nothing.
 */

/* 

Player Makers Script (Best utilised When ACE Markers Are Not An Option)

Parameters >>
    "players" - Will show players.
    "ais" - Will show AIs.
    "allsides" - Will show all sides not only the units on player's side.
    "all" - Enable all of the above.
    "stop" - Stop the script.

Example code - 0 = ["players"] execVM "player_markers.sqf";

*/
//0 = ["players"] execVM "MissionScripts\ThirdPartyScripts\player_markers.sqf";


/*
SUPERSEDED - do not enable this block.

Werthles' Headless Kit v2.3 is replaced by WMP's own native headless-client support
(Waldo_fnc_HeadlessDetectLocal / Waldo_fnc_HeadlessRegisterClient / Waldo_fnc_HeadlessRebalance /
Waldo_fnc_HeadlessMigrateGroup / Waldo_fnc_HeadlessReassignOnDisconnect / Waldo_fnc_HeadlessGetDiagnostics,
registered under WaldosFunctions.sqf's "Headless" category). Enable it explicitly through
MissionConfig\headlessConfig.sqf, then connect a headless client; it self-registers and receives only
eligible AI groups. See wiki/Headless-Client-Support.md.

WerthlesHeadless.sqf itself is left in the repository, unmodified and still fully disabled below, for
reference only - it has known deviations from WMP's own locality/exclusion model (a non-standard
headless-client detection test, a name-string exclusion list unaware of WMP-owned control groups, and
zero integration with WMP's diagnostics or JIP snapshot handshake) and has not been re-validated
against current CBA_A3/ACE3/Arma versions. Do not re-enable it without first reading those notes.
*/
//[true,30,false,true,30,10,true,[]] execVM "MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf";
