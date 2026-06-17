/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - getDropPointsForType
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_getDropPointsForType via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_typeName", "Ground"], ["_sideKey", "ANY"]];

        private _safeType = [_typeName] call Waldo_fnc_EcoBuy_normalizeDropPointType;
        private _safeSide = [_sideKey] call Waldo_fnc_EcoBuy_normalizeDropPointSide;
        (call Waldo_fnc_EcoBuy_getDropPoints) select {
            ((_x param [1, "Ground"]) isEqualTo _safeType)
            && {
                private _rowSide = [_x param [5, "ANY"]] call Waldo_fnc_EcoBuy_normalizeDropPointSide;
                (_rowSide isEqualTo "ANY") || {_rowSide isEqualTo _safeSide}
            }
        }

