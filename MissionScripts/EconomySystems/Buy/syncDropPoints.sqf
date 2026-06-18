/*
 * Author: Waldo
 * Sync drop points.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_syncDropPoints;
 */

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        private _kept = [];
        private _changed = false;

        {
            private _row = _x;
            private _anchor = _row param [4, objNull];
            if (isNull _anchor) then {
                _changed = true;
                continue;
            };

            private _pos = getPosATL _anchor;
            private _dir = getDir _anchor;
            if ((_pos distance2D (_row param [2, [0, 0, 0]])) > 0.5 || {abs (_dir - (_row param [3, 0])) > 0.5}) then {
                _row set [2, _pos];
                _row set [3, _dir];
                _changed = true;
            };

            private _sideKey = [_row param [5, _anchor getVariable ["WaldoEcoBuy_DropPointSide", "ANY"]]] call Waldo_fnc_EcoBuy_normalizeDropPointSide;
            if (_sideKey isNotEqualTo (_row param [5, "ANY"])) then {
                _row set [5, _sideKey];
                _changed = true;
            };

            _kept pushBack _row;
        } forEach _rows;

        if (_changed || {(count _kept) isNotEqualTo (count _rows)}) then {
            [_kept] call Waldo_fnc_EcoBuy_setDropPoints;
        };

