/*
 * Author: WaldoTheWarfighter
 * Returns the current list of valid Ground Command identity keys.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * <ARRAY of STRING> filtered command keys.
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_getGroundCommandUIDs;
 * Locality/Authority: Any machine; reads missionNamespace state without mutating it.
 * Repeat/JIP Behaviour: Repeat-safe read of published command keys; JIP receives current state.
 * Current Callers: Ground Command checks, curator prompt and authority updates.
 * Result: Invalid stored keys are excluded from the returned list.
 */

    private _stored = +(missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []]);
    _stored select {[_x] call Waldo_fnc_EcoCommand_isGroundCommandStoredKey}
