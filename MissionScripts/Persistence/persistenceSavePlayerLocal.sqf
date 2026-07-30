/*
 * Author: WaldoTheWarfighter
 * Captures and submits the local player's configured persistence state immediately.
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

if !(hasInterface && {!isNull player} && {missionNamespace getVariable ["Waldo_Persistence_Active", false]}) exitWith {false};
private _state = [] call Waldo_fnc_PersistenceClientCapture;
["SAVE_PLAYER", _state] remoteExecCall ["Waldo_fnc_PersistenceServerHandle", 2];
true
