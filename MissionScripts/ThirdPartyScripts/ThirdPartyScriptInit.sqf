/*
 * Author: WaldoTheWarfighter
 * Provides one optional entry point for the legacy player-marker integration. Native WMP Headless
 * Client support is configured separately in MissionConfig\headlessConfig.sqf; this file does not
 * enable it. The shipped calls remain commented out until a mission maker deliberately enables them.
 *
 * Locality and authority: Execute on each interface client only when the optional local marker
 * overlay is required. This commented launcher creates no authoritative server state.
 * Repeat/JIP: The marker script replaces its prior local loop when started again. Enable this
 * launcher in per-client setup for joining players; it has no public-state replay of its own.
 *
 * Arguments: None.
 * Return Value: Nothing.
 * Current callers: optional mission-maker call from initPlayerLocal.sqf; disabled in the release template.
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
