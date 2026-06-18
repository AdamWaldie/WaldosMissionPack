/*
 * Author: Waldo
 * Get ground command UI ds.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCommand_getGroundCommandUIDs;
 */

    private _stored = +(missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []]);
    _stored select {[_x] call Waldo_fnc_EcoCommand_isGroundCommandStoredKey}
