/*
 * Author: Waldo
 * Returns an interaction object's broadcast lifecycle state. Safe for unscheduled ACE and
 * vanilla action conditions.
 */

params [["_object", objNull, [objNull]]];
if (isNull _object) exitWith {"IDLE"};
_object getVariable ["Waldo_MG_InteractionState", "IDLE"]
