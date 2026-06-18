/*
 * Author: Waldo
 * Delete drop point.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _dropPointId <STRING> - drop point id (optional, default: "")
 * 1: _deleteAnchor <BOOL> - delete anchor (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_dropPointId, _deleteAnchor] call Waldo_fnc_EcoBuy_deleteDropPoint;
 */

        params [["_dropPointId", ""], ["_deleteAnchor", true]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (_dropPointId isEqualTo "") exitWith {};

        private _index = [_dropPointId] call Waldo_fnc_EcoBuy_findDropPointIndex;
        if (_index < 0) exitWith {};

        private _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        private _row = _rows select _index;
        private _anchor = _row param [4, objNull];

        if (_deleteAnchor && {!isNull _anchor}) then {
            _anchor setVariable ["WaldoEcoBuy_DropDeleting", true];
            deleteVehicle _anchor;
        };

        _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        _index = [_dropPointId] call Waldo_fnc_EcoBuy_findDropPointIndex;
        if (_index < 0) exitWith {};

        _rows deleteAt _index;
        [_rows] call Waldo_fnc_EcoBuy_setDropPoints;

