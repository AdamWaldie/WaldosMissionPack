/*
 * Author: WaldoTheWarfighter
 * Returns named fields derived from Waldo_MG_InteractionResult. The broadcast source remains a
 * stable eight-element array so JIP and condition consumers do not depend on hashmap transport.
 */

params [["_object", objNull, [objNull]]];
private _raw = if (isNull _object) then {
    ["IDLE", "", "", "", objNull, "", -1, -1]
} else {
    _object getVariable ["Waldo_MG_InteractionResult", ["IDLE", "", "", "", objNull, "", -1, -1]]
};

createHashMapFromArray [
    ["state", _raw param [0, "IDLE"]],
    ["outcomeCode", _raw param [1, ""]],
    ["reason", _raw param [2, ""]],
    ["challengeId", _raw param [3, ""]],
    ["actor", _raw param [4, objNull]],
    ["attemptId", _raw param [5, ""]],
    ["startedAt", _raw param [6, -1]],
    ["finishedAt", _raw param [7, -1]],
    ["raw", +_raw]
]
