/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - clusterDetectorContacts
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_clusterDetectorContacts via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_contacts", []], ["_radius", 200]];

        private _clusters = [];

        {
            private _pos = _x param [1, [0, 0, 0]];
            private _sideKey = _x param [2, "NONE"];
            private _markerType = _x param [3, "mil_dot"];

            private _clusterIndex = _clusters findIf {
                ((_x param [0, "NONE"]) isEqualTo _sideKey)
                && {((_x param [1, "mil_dot"]) isEqualTo _markerType)}
                && {((_x param [2, [0, 0, 0]]) distance2D _pos) <= _radius}
            };

            if (_clusterIndex < 0) then {
                _clusters pushBack [_sideKey, _markerType, _pos, 1];
            } else {
                private _cluster = +(_clusters select _clusterIndex);
                private _count = 1 + (_cluster param [3, 1]);
                private _currentPos = _cluster param [2, [0, 0, 0]];
                private _newPos = [
                    (((_currentPos param [0, 0]) * (_count - 1)) + (_pos param [0, 0])) / _count,
                    (((_currentPos param [1, 0]) * (_count - 1)) + (_pos param [1, 0])) / _count,
                    0
                ];
                _cluster set [2, _newPos];
                _cluster set [3, _count];
                _clusters set [_clusterIndex, _cluster];
            };
        } forEach _contacts;

        _clusters

