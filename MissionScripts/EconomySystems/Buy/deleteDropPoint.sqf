/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - deleteDropPoint
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_deleteDropPoint via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

