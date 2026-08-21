/*
 * Author: WaldoTheWarfighter
 * Normalises one object, group, or object array into unique non-null dialogue speakers.
 * Locality/authority: pure helper; no network or world mutation. Repeat/JIP behaviour: deterministic.
 * Arguments: 0 target <OBJECT|GROUP|ARRAY>. Return Value: ARRAY<OBJECT>.
 * Current callers: SimpleDialogue, SimpleDialogueClear, ConversationAssign and ConversationClear.
 * Example: private _speakers = [group this] call Waldo_fnc_DialogueResolveTargets;
 */
params ["_target"];
private _targets = switch (typeName _target) do {
    case "OBJECT": {[_target]};
    case "GROUP": {units _target};
    case "ARRAY": {_target};
    default {[]};
};
private _validTargets = _targets select {_x isEqualType objNull && {!isNull _x} && {_x isKindOf "CAManBase"}};
_validTargets arrayIntersect _validTargets
