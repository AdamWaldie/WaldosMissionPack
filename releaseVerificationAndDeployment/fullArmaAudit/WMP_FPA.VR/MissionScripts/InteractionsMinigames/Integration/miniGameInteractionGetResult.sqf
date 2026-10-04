/*
 * Author: WaldoTheWarfighter
 * Returns named fields derived from Waldo_MG_InteractionResult. The broadcast source remains a
 * stable eight-element array so JIP and condition consumers do not depend on hashmap transport.
 * Locality/Authority: Any machine; reads the object's broadcast result without mutating it.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP clients receive the published source array.
 * Arguments: 0: interaction object <OBJECT>, default objNull.
 * Return Value: <HASHMAP> with state, outcomeCode, reason, challengeId, actor, attemptId,
 * startedAt, finishedAt and raw keys; null objects yield idle/default values.
 * Current Callers: Mission scripts and interaction state diagnostics.
 * Example: [_terminal] call Waldo_fnc_MiniGameInteractionGetResult;
 * Result: Returns the latest authoritative outcome in named fields.
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
