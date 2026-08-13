/*
 * Author: WaldoTheWarfighter, Val
 * Starts the repeat-safe server authority for WMP helicopter, ground and boat transport services.
 * The server owns registry membership, pool availability, reservations, request IDs and public
 * state. AI movement is dispatched separately to the machine that owns each driver group.
 * Locality and authority: server-only registry initialization; no interface state is created here.
 *
 * Arguments: None.
 * Return Value: Boolean - true on the server after initialization.
 *
 * Example:
 * [] call Waldo_fnc_TransportInitServer;
 * Result: creates empty typed registries and one cleanup/marker monitor.
 * Current callers: initServer.sqf and Waldo_fnc_TransportRegister.
 */

if (!isServer) exitWith {false};
if (missionNamespace getVariable ["Waldo_Transport_ServerStarted", false]) exitWith {true};
missionNamespace setVariable ["Waldo_Transport_ServerStarted", true];
missionNamespace setVariable ["Waldo_Transport_Services", createHashMap];
missionNamespace setVariable ["Waldo_Transport_Pools", createHashMapFromArray [["HELICOPTER", []], ["GROUND", []], ["BOAT", []]]];
missionNamespace setVariable ["Waldo_Transport_RequestSerial", 0];
missionNamespace setVariable ["Waldo_HeliTransport_Available", false, true];
missionNamespace setVariable ["Waldo_GroundTransport_Available", false, true];
missionNamespace setVariable ["Waldo_BoatTransport_Available", false, true];
[] spawn Waldo_fnc_TransportMonitorServer;
true
