/*
 * Author: WaldoTheWarfighter
 * Checks whether a unit may issue Ground Command orders.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * <BOOL> true when no commander is assigned, or the unit is on the commander list.
 *
 * Example:
 * [_unit] call Waldo_fnc_EcoCommand_hasCommandAuthority;
 * Locality/Authority: Any machine; read-only check against published command membership.
 * Repeat/JIP Behaviour: Repeat-safe and follows JIP command-list state.
 * Current Callers: Build, Buy and Research status checks and authority gates.
 * Result: Refuses a null unit once a commander has been assigned.
 */

    params [["_unit", objNull]];

    if !((call Waldo_fnc_EcoCommand_hasAnyGroundCommand)) exitWith {true};
    if (isNull _unit) exitWith {false};
    [_unit] call Waldo_fnc_EcoCommand_isGroundCommandUnit
