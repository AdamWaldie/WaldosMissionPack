/*
 * Author: WaldoTheWarfighter
 * Tests an interaction object's lifecycle state. Safe for ACE condition code.
 */

params [
    ["_object", objNull, [objNull]],
    ["_state", "IDLE", [""]]
];
if (isNull _object) exitWith {false};
((_object getVariable ["Waldo_MG_InteractionState", "IDLE"]) == toUpper _state)
