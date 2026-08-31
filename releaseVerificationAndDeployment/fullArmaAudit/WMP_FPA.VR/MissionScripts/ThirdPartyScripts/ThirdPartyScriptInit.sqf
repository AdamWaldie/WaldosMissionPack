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
