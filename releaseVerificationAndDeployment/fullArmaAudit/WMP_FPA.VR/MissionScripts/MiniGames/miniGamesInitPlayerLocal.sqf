/*
 * Author: WaldoTheWarfighter
 * Replays registered seated-table metadata for one interface client without transmitting executable code.
 *
 * Locality/authority: Interface client only; reads the server-published membership registry.
 * Repeat/JIP: Repeat-safe and intended for initPlayerLocal and respawn/local-player replacement.
 * Arguments: None.
 * Return Value: Boolean.
 * Current callers: initPlayerLocal.sqf.
 * Example: [] call Waldo_fnc_MiniGamesInitPlayerLocal;
 */

if (!hasInterface) exitWith {false};
if !(missionNamespace getVariable ["Waldo_MG_TableRegistryListenerLocal", false]) then {
    "Waldo_MG_Tables" addPublicVariableEventHandler {
        params ["", "_registeredTables"];
        if ((count _registeredTables) > 0 && {!isNull player}) then {
            [player] remoteExecCall ["Waldo_fnc_MiniGamesRequestMetadataServer", 2];
        };
    };
    missionNamespace setVariable ["Waldo_MG_TableRegistryListenerLocal", true];
};
private _tables = missionNamespace getVariable ["Waldo_MG_Tables", []];
if ((count _tables) == 0) exitWith {true};
[player] remoteExecCall ["Waldo_fnc_MiniGamesRequestMetadataServer", 2];
true
