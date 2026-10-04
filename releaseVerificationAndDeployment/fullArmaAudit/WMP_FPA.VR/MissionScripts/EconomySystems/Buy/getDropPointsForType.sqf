/*
 * Author: WaldoTheWarfighter
 * Filters published delivery points by purchase type and side access.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _typeName <STRING> - type name (optional, default: "Ground")
 * 1: _sideKey <STRING> - side key (optional, default: "ANY")
 *
 * Return Value:
 * <ARRAY> matching drop-point rows.
 *
 * Example:
 * [_typeName, _sideKey] call Waldo_fnc_EcoBuy_getDropPointsForType;
 * Locality/Authority: Any machine; read-only registry filter.
 * Repeat/JIP Behaviour: Repeat-safe read of the published registry.
 * Current Callers: Purchase status and drop-point selection.
 * Result: Includes side-neutral points and points matching the requested side.
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

