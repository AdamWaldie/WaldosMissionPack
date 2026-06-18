/*
 * Author: Waldo
 * Get drop points for type.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _typeName <STRING> - type name (optional, default: "Ground")
 * 1: _sideKey <STRING> - side key (optional, default: "ANY")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_typeName, _sideKey] call Waldo_fnc_EcoBuy_getDropPointsForType;
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

