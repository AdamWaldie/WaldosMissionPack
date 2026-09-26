/*
 * Author: WaldoTheWarfighter
 * Removes a detector building's contact and coverage-area markers.
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
 * [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
 * Locality/Authority: Economy authority only; deletes global markers and public tags.
 * Repeat/JIP Behaviour: Repeat cleanup is harmless; JIP sees cleared marker names.
 * Current Callers: Building disable/deletion and detector teardown.
 * Result: No detector visuals remain attached to the building.
 */

        params [["_building", objNull]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};

        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorContactMarkers;

        private _areaMarker = _building getVariable ["WaldoEcoBuild_DetectorAreaMarker", ""];
        if (_areaMarker isNotEqualTo "") then {
            [_areaMarker] call Waldo_fnc_EcoBuild_deleteNamedMarker;
            _building setVariable ["WaldoEcoBuild_DetectorAreaMarker", "", true];
        };

