/*
 * Author: WaldoTheWarfighter
 * Tests whether a soldier can contribute now; wounded conscious soldiers remain eligible.
 * Locality/authority: read-only on the requesting owner unless stated below.
 * Repeat/JIP: no side effects; runtime gates are read again on every call.
 * Arguments: 0: soldier <OBJECT>, objNull.
 * Return Value: Boolean.
 * Current callers: Capability, morale, passenger and reinforcement checks.
 * Example: [_soldier] call Waldo_fnc_AIPassCombatEffective;
 */
params [["_unit", objNull, [objNull]]];
!isNull _unit && {alive _unit} && {!(_unit getVariable ["ACE_isUnconscious", false])}
    && {lifeState _unit != "INCAPACITATED"} && {!captive _unit}
    && {!(_unit getVariable ["ace_captives_isSurrendering", false])}
    && {!(_unit getVariable ["ace_captives_isHandcuffed", false])}
