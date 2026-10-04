/*
 * Author: WaldoTheWarfighter
 * Checks whether a unit's resolved key belongs to Ground Command.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _unit <OBJECT> - unit (optional, default: objNull)
 *
 * Return Value:
 * <BOOL> true when the unit is assigned Ground Command.
 *
 * Example:
 * [_unit] call Waldo_fnc_EcoCommand_isGroundCommandUnit;
 * Locality/Authority: Any machine; compares the unit identity with published keys.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP clients see current list/identity state.
 * Current Callers: EcoCommand_hasCommandAuthority and command-gated actions.
 * Result: Returns false for a null unit or unresolved key.
 */

    params [["_unit", objNull]];

    if (isNull _unit) exitWith {false};

    private _unitKey = [_unit] call Waldo_fnc_EcoCommand_getGroundCommandKey;
    if (_unitKey isEqualTo "") exitWith {false};

    ((call Waldo_fnc_EcoCommand_getGroundCommandUIDs) find _unitKey) >= 0
