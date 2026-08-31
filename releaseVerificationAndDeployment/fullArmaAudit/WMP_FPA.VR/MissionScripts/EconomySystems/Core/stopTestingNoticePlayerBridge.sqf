/*
 * Author: WaldoTheWarfighter
 * Removes the Economy testing-notice player lifecycle handlers.
 *
 * Locality/authority: server only. Repeat/JIP behaviour: repeat-safe; missing handlers are ignored.
 * The notice uses owner-targeted transient installation and therefore has no JIP queue entry to remove.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - true after the bridge is stopped; false when called outside the server.
 *
 * Current callers: purgeEconomySystems.
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_stopTestingNoticePlayerBridge;
 */

if (!isServer) exitWith {false};

private _connectedHandler = missionNamespace getVariable ["WaldoEcoCore_TestingNoticePlayerConnectedEH", -1];
if (_connectedHandler >= 0) then {
    removeMissionEventHandler ["PlayerConnected", _connectedHandler];
};

private _respawnHandler = missionNamespace getVariable ["WaldoEcoCore_TestingNoticeRespawnEH", -1];
if (_respawnHandler >= 0) then {
    removeMissionEventHandler ["EntityRespawned", _respawnHandler];
};

missionNamespace setVariable ["WaldoEcoCore_TestingNoticePlayerConnectedEH", nil];
missionNamespace setVariable ["WaldoEcoCore_TestingNoticeRespawnEH", nil];
missionNamespace setVariable ["WaldoEcoCore_TestingNoticePlayerBridgeStarted", false];

true
