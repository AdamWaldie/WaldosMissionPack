/*
 * Author: Waldo
 * Returns true on the single state authority for the economy suite - the server only.
 *
 * The server is the one machine that owns and mutates shared economy state (catalogs, side
 * resources, zones, jobs) and creates global world objects/markers. Every such mutation is gated
 * by this. Client-only work (Zeus menu injection, ACE action setup, dialogs, request publishing)
 * is gated by hasInterface instead, never by this. On a hosted/listen server or in SP the host is
 * the server, so this is true there too; on a dedicated server it is true only on the server -
 * NOT on player clients (which is what makes the suite correct on dedicated multiplayer).
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true only on the server (state authority)
 *
 * Example:
 * if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
 */

    isServer
