/*
 * Author: Waldo
 * Cleanup detector contact markers.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_cleanupDetectorContactMarkers;
 */

        params [["_building", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        {
            [_x] call Waldo_fnc_EcoBuild_deleteNamedMarker;
        } forEach (_building getVariable ["WaldoEcoBuild_DetectorContactMarkers", []]);

        _building setVariable ["WaldoEcoBuild_DetectorContactMarkers", [], true];

