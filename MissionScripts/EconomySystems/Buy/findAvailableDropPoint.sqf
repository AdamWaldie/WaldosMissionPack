/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - findAvailableDropPoint
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_findAvailableDropPoint via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_typeName", "Ground"], ["_origin", [0, 0, 0]], ["_className", ""], ["_sideKey", "ANY"]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {[]};

        private _candidates = [[_typeName] call Waldo_fnc_EcoBuy_normalizeDropPointType, _sideKey] call Waldo_fnc_EcoBuy_getDropPointsForType;
        if ((count _candidates) <= 0) exitWith {[]};

        _candidates = [_candidates, [], {
            ((_x param [2, [0, 0, 0]]) distance2D _origin)
        }, "ASCEND"] call BIS_fnc_sortBy;

        private _selected = [];
        {
            private _row = _x;
            private _anchor = _row param [4, objNull];

            private _pos = _row param [2, [0, 0, 0]];
            private _clearance = 4 max ((sizeOf _className) * 0.6);
            private _nearby = nearestObjects [_pos, ["AllVehicles", "Air", "LandVehicle", "Ship", "StaticWeapon", "Thing"], _clearance];
            _nearby = _nearby select {
                !isNull _x
                && {_x isNotEqualTo _anchor}
                && {!(_x getVariable ["WaldoEcoBuy_IsDropPointAnchor", false])}
            };

            if ((count _nearby) isEqualTo 0) exitWith {
                _selected = +_row;
            };
        } forEach _candidates;

        _selected

