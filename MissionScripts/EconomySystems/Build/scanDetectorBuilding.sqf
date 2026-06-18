/*
 * Author: Waldo
 * Scan detector building.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_building, _entry] call Waldo_fnc_EcoBuild_scanDetectorBuilding;
 */

        params [["_building", objNull], ["_entry", []]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building || {(count _entry) <= 0}) exitWith {};

        private _range = 0 max (_entry param [14, 0]);
        if (_range <= 0) exitWith {};

        private _sideKey = _building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
        if !(_sideKey in ["WEST", "EAST", "GUER"]) exitWith {};

        private _origin = getPosATL _building;
        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorContactMarkers;
        [_building, _range] call Waldo_fnc_EcoBuild_ensureDetectorAreaMarker;

        private _seenKeys = [];
        private _contacts = [];

        {
            private _unit = _x;
            if (isNull _unit || {!alive _unit}) then {continue;};

            private _enemySide = [side group _unit] call Waldo_fnc_EcoResource_getSideKeyFromSide;
            if !(_enemySide in ["WEST", "EAST", "GUER"]) then {continue;};
            if (_enemySide isEqualTo _sideKey) then {continue;};

            private _entity = vehicle _unit;
            if (isNull objectParent _unit || {_entity isEqualTo _unit}) then {
                _entity = _unit;
            };
            if (isNull _entity || {!alive _entity}) then {continue;};

            private _key = netId _entity;
            if (_key isEqualTo "") then {
                _key = str _entity;
            };
            if ((_seenKeys find _key) >= 0) then {continue;};

            private _pos = getPosATL _entity;
            if ((_pos distance2D _origin) > _range) then {continue;};

            _seenKeys pushBack _key;
            _contacts pushBack [_entity, _pos, _enemySide, [_entity, _enemySide] call Waldo_fnc_EcoBuild_getDetectorMarkerType];
        } forEach allUnits;

        private _clusters = [_contacts, 200] call Waldo_fnc_EcoBuild_clusterDetectorContacts;
        private _markerNames = [];

        {
            private _enemySide = _x param [0, "NONE"];
            private _markerType = _x param [1, "mil_dot"];
            private _pos = _x param [2, [0, 0, 0]];
            private _count = _x param [3, 1];

            private _markerName = format ["WaldoEcoBuild_DetectorContact_%1_%2_%3", diag_tickTime, floor (random 100000), _forEachIndex];
            createMarker [_markerName, _pos];
            _markerName setMarkerShape "ICON";
            _markerName setMarkerType _markerType;
            _markerName setMarkerColor ([_enemySide] call Waldo_fnc_EcoBuild_getMarkerColorBySide);
            _markerName setMarkerText (if (_count > 1) then {format ["x%1", _count]} else {""});
            [_markerName] call Waldo_fnc_EcoBuild_addSharedMarkerName;
            _markerNames pushBack _markerName;
        } forEach _clusters;

        _building setVariable ["WaldoEcoBuild_DetectorContactMarkers", _markerNames, true];
        _building setVariable ["WaldoEcoBuild_LastDetectionScan", serverTime, false];

