/*
 * Author: WaldoTheWarfighter
 * Captures and submits the local player's configured persistence state immediately.
 * Locality and authority: call on an interface client; the server validates the resulting request
 * and owns the database write. The request is rejected until the initial FOUND/NONE handshake and
 * any required ACRE restore/baseline finish. This also protects manual/Zeus save requests from
 * overwriting an unread record. Repeated calls after readiness are safe.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Boolean - true when a save request was submitted
 *
 * Example:
 * [] call Waldo_fnc_PersistenceSavePlayerLocal;
 */

if !(
    hasInterface
    && {!isNull player}
    && {missionNamespace getVariable ["Waldo_Persistence_Active", false]}
    && {missionNamespace getVariable ["Waldo_Persistence_PlayerSaveReady", false]}
) exitWith {
    diag_log format [
        "[WMP PERSISTENCE] Player save withheld: loadState=%1 saveReady=%2.",
        missionNamespace getVariable ["Waldo_Persistence_PlayerLoadState", "UNKNOWN"],
        missionNamespace getVariable ["Waldo_Persistence_PlayerSaveReady", false]
    ];
    false
};
private _state = [] call Waldo_fnc_PersistenceClientCapture;
["SAVE_PLAYER", _state] remoteExecCall ["Waldo_fnc_PersistenceServerHandle", 2];
true
