/*
 * Author: WaldoTheWarfighter
 * Creates or updates a detector building's global area marker.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _range <NUMBER> - radius in metres (optional, default: 0)
 *
 * Return Value:
 * <STRING> marker name, or "" for an invalid building/range.
 *
 * Example:
 * [_building, _range] call Waldo_fnc_EcoBuild_ensureDetectorAreaMarker;
 * Locality/Authority: Call on Economy authority; this helper itself has no authority guard.
 * Repeat/JIP Behaviour: Reuses the building's marker name on later calls; global marker
 * and published object tag are available to JIP.
 * Current Callers: Detector building scan/visual maintenance.
 * Result: Marker shape, size, colour and position match the detector area.
 */

        params [["_building", objNull], ["_range", 0]];

        if (isNull _building || {_range <= 0}) exitWith {""};

        private _markerName = _building getVariable ["WaldoEcoBuild_DetectorAreaMarker", ""];
        if (_markerName isEqualTo "") then {
            _markerName = format ["WaldoEcoBuild_DetectorArea_%1_%2", diag_tickTime, floor (random 100000)];
            createMarker [_markerName, getPosATL _building];
            _building setVariable ["WaldoEcoBuild_DetectorAreaMarker", _markerName, true];
            [_markerName] call Waldo_fnc_EcoBuild_addSharedMarkerName;
        };

        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        _markerName setMarkerSize [_range, _range];
        _markerName setMarkerColor ([(_building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"])] call Waldo_fnc_EcoBuild_getMarkerColorBySide);
        _markerName setMarkerText "";
        _markerName setMarkerPos (getPosATL _building);
        _markerName

