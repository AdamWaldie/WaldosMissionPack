/*
 * Author: WaldoTheWarfighter
 * Creates a side/type-specific purchase delivery point and its world anchor.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 * 1: _typeName <STRING> - type name (optional, default: "Ground")
 * 2: _dir <NUMBER> - bearing in degrees (optional, default: 0)
 * 3: _sideKey <STRING> - side key (optional, default: "ANY")
 *
 * Return Value:
 * <STRING> new drop-point ID on authority; a client call forwards to the server.
 *
 * Example:
 * [_pos, _typeName, _dir, _sideKey] call Waldo_fnc_EcoBuy_createDropPoint;
 * Locality/Authority: Server creates the point; client calls forward there.
 * Repeat/JIP Behaviour: Each call creates a distinct ID; the updated registry is published
 * for joining clients. Do not call twice for one intended point.
 * Current Callers: Purchasing ZEN placement and exported mission setup calls.
 * Result: The new point becomes available to matching-side purchases.
 */

        params [["_pos", [0, 0, 0]], ["_typeName", "Ground"], ["_dir", 0], ["_sideKey", "ANY"]];

        // Authority-only creation; forward to the server when called on a client (dedicated-safe).
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {
            _this remoteExec ["Waldo_fnc_EcoBuy_createDropPoint", 2];
        };

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
        diag_log format ["[WMP ECO] Purchase drop point created id=%1 type=%2 side=%3 position=%4 direction=%5 anchor=%6", _dropPointId, _safeType, _safeSide, _pos, _dir, netId _anchor];
        _dropPointId

