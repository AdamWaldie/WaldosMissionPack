/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - ensureDetectorAreaMarker
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_ensureDetectorAreaMarker via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

