/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCommand system - getGroundCommandUIDs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCommand_getGroundCommandUIDs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    private _stored = +(missionNamespace getVariable ["WaldoEcoCommand_GroundCommandUIDs", []]);
    _stored select {[_x] call Waldo_fnc_EcoCommand_isGroundCommandStoredKey}
