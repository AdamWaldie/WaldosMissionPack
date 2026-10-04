/*
 * Author: WaldoTheWarfighter
 * Returns an interaction object's broadcast lifecycle state. Safe for unscheduled ACE and
 * vanilla action conditions.
 * Locality/Authority: Any machine; reads public object state only.
 * Repeat/JIP Behaviour: Repeat-safe read; published state is available to JIP clients.
 * Arguments: 0: interaction object <OBJECT>, default objNull.
 * Return Value: Lifecycle state <STRING>, or "IDLE" for a null object.
 * Current Callers: MiniGameInteraction action conditions and mission scripts.
 * Example: [_terminal] call Waldo_fnc_MiniGameInteractionGetState;
 * Result: Returns the object's current broadcast interaction state.
 */

params [["_object", objNull, [objNull]]];
if (isNull _object) exitWith {"IDLE"};
_object getVariable ["Waldo_MG_InteractionState", "IDLE"]
