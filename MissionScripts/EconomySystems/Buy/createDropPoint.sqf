/*
 * Author: Waldo
 * Create drop point.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 * 1: _typeName <STRING> - type name (optional, default: "Ground")
 * 2: _dir <SCALAR> - dir (optional, default: 0)
 * 3: _sideKey <STRING> - side key (optional, default: "ANY")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_pos, _typeName, _dir, _sideKey] call Waldo_fnc_EcoBuy_createDropPoint;
 */

        params [["_pos", [0, 0, 0]], ["_typeName", "Ground"], ["_dir", 0], ["_sideKey", "ANY"]];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

        private _dropPointId = format ["buy_drop_%1_%2", floor serverTime, floor (random 100000)];
        private _safeType = [_typeName] call Waldo_fnc_EcoBuy_normalizeDropPointType;
        private _safeSide = [_sideKey] call Waldo_fnc_EcoBuy_normalizeDropPointSide;

        private _anchor = createVehicle ["Land_HelipadEmpty_F", _pos, [], 0, "CAN_COLLIDE"];
        _anchor setPosATL _pos;
        _anchor setDir _dir;
        _anchor enableSimulationGlobal false;
        _anchor setVariable ["WaldoEcoBuy_IsDropPointAnchor", true, true];
        _anchor setVariable ["WaldoEcoBuy_DropPointId", _dropPointId, true];
        _anchor setVariable ["WaldoEcoBuy_DropPointType", _safeType, true];
        _anchor setVariable ["WaldoEcoBuy_DropPointSide", _safeSide, true];

        [[_anchor], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        _anchor addEventHandler ["Deleted", {
            params ["_entity"];
            if (_entity getVariable ["WaldoEcoBuy_DropDeleting", false]) exitWith {};
            private _dropPointId = _entity getVariable ["WaldoEcoBuy_DropPointId", ""];
            if (_dropPointId isEqualTo "") exitWith {};
            [_dropPointId, false] call Waldo_fnc_EcoBuy_deleteDropPoint;
        }];

        _anchor addEventHandler ["Killed", {
            params ["_entity"];
            if (_entity getVariable ["WaldoEcoBuy_DropDeleting", false]) exitWith {};
            private _dropPointId = _entity getVariable ["WaldoEcoBuy_DropPointId", ""];
            if (_dropPointId isEqualTo "") exitWith {};
            [_dropPointId, false] call Waldo_fnc_EcoBuy_deleteDropPoint;
        }];

        private _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        _rows pushBack [_dropPointId, _safeType, _pos, _dir, _anchor, _safeSide];
        [_rows] call Waldo_fnc_EcoBuy_setDropPoints;

