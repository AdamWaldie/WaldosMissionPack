/*
 * Author: Waldo
 * Ensure detector area marker.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _range <SCALAR> - range (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_building, _range] call Waldo_fnc_EcoBuild_ensureDetectorAreaMarker;
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

