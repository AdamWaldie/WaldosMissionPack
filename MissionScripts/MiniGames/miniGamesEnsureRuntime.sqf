/*
 * Author: WaldoTheWarfighter
 * Lazily compiles the seated MiniGames runtime for the role of the calling machine.
 * The server receives authority and all game rules, interface clients receive interaction and UI
 * code, and headless clients receive only the shared core needed by locality callbacks. The local
 * version guard makes repeat calls harmless. No code is transmitted and no JIP entry is created.
 *
 * Locality/authority: Local execution on server, interface client, or headless client. This function
 * does not register tables or mutate authoritative game state.
 * Repeat/JIP: Repeat-safe per machine. JIP clients compile only after table metadata is replayed.
 *
 * Arguments: None.
 * Return Value: Boolean - true when the role runtime is available.
 * Current callers: MiniGamesRegisterTable, MiniGamesRegisterTableLocal, MiniGamesInitPlayerLocal,
 * MiniGamesRequestServer.
 * Example: [] call Waldo_fnc_MiniGamesEnsureRuntime;
 */

private _role = if (isServer) then {"SERVER"} else {if (hasInterface) then {"CLIENT"} else {"HEADLESS"}};
private _runtimeKey = format ["Waldo_MG_Runtime_%1_2.0.0", _role];
if (missionNamespace getVariable [_runtimeKey, false]) exitWith {true};

Waldo_MG_Version = "2.0.0";

#include "engine\config.sqf"
#include "engine\core.sqf"

if (_role != "HEADLESS") then {
    #include "engine\games\battleship.sqf"
    #include "engine\games\blackjack.sqf"
    #include "engine\games\checkers.sqf"
    #include "engine\games\chess.sqf"
    #include "engine\games\poker.sqf"
    #include "engine\games\drawpoker.sqf"
    #include "engine\games\liarsdice.sqf"
    #include "engine\games\connectfour.sqf"
    #include "engine\games\rps.sqf"
    #include "engine\games\shotgun.sqf"
    #include "engine\games\uno.sqf"
    #include "engine\games\whoswho.sqf"
};

if (isServer) then {
    call Waldo_MG_fnc_initializeServerState;
};
missionNamespace setVariable [_runtimeKey, true];
missionNamespace setVariable ["Waldo_MG_SystemInitialized", true];
true
