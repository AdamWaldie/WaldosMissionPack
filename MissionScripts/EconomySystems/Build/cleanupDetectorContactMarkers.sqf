/*
 * Author: WaldoTheWarfighter
 * Removes every contact marker owned by one detector building.
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
 * Locality/Authority: Economy authority only; deletes global markers and publishes empty list.
 * Repeat/JIP Behaviour: Repeat cleanup is harmless; JIP sees no remaining contact names.
 * Current Callers: Detector rescans and detector-building cleanup.
 * Result: Existing contacts disappear before fresh scan markers are placed.
 */

        params [["_building", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        {
            [_x] call Waldo_fnc_EcoBuild_deleteNamedMarker;
        } forEach (_building getVariable ["WaldoEcoBuild_DetectorContactMarkers", []]);

        _building setVariable ["WaldoEcoBuild_DetectorContactMarkers", [], true];

