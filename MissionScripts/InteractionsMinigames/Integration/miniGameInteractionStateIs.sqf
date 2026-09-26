/*
 * Author: WaldoTheWarfighter
 * Tests an interaction object's lifecycle state. Safe for ACE condition code.
 * Locality/Authority: Any machine; reads public object state only.
 * Repeat/JIP Behaviour: Pure comparison; JIP sees the broadcast lifecycle state.
 * Arguments: 0: interaction object <OBJECT>, default objNull; 1: expected state <STRING>,
 * default "IDLE".
 * Return Value: <BOOL> true when state matches, false for a null object or mismatch.
 * Current Callers: ACE interaction visibility conditions and mission scripts.
 * Example: [_terminal, "COMPLETE"] call Waldo_fnc_MiniGameInteractionStateIs;
 * Result: Returns whether the object is in the named state.
 */

params [
    ["_object", objNull, [objNull]],
    ["_state", "IDLE", [""]]
];
if (isNull _object) exitWith {false};
((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == toUpper _state)
