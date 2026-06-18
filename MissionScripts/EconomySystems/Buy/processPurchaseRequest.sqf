/*
 * Author: Waldo
 * Process purchase request.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _holder <OBJECT> - holder (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_holder, _request] call Waldo_fnc_EcoBuy_processPurchaseRequest;
 */

        params [["_holder", objNull], ["_request", []]];

        if (isNull _holder) exitWith {};
        if !(_request isEqualType []) exitWith {
            _holder setVariable ["WaldoEcoBuy_PurchaseRequest", [], true];
        };
        if ((count _request) < 5) exitWith {
            _holder setVariable ["WaldoEcoBuy_PurchaseRequest", [], true];
        };

        private _requestId = _request param [4, ""];
        if (_requestId isEqualTo "") exitWith {
            _holder setVariable ["WaldoEcoBuy_PurchaseRequest", [], true];
        };

        private _handled = missionNamespace getVariable ["WaldoEcoBuy_PurchaseRequestsHandled", []];
        if !(_handled isEqualType []) then {_handled = [];};
        if (_requestId in _handled) exitWith {
            _holder setVariable ["WaldoEcoBuy_PurchaseRequest", [], true];
        };

        _handled pushBack _requestId;
        while {(count _handled) > 64} do {
            _handled deleteAt 0;
        };
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseRequestsHandled", _handled, true];

        _holder setVariable ["WaldoEcoBuy_PurchaseRequest", [], true];

        private _sideKey = _request param [0, "NONE"];
        private _purchaseName = _request param [1, ""];
        private _origin = _request param [2, []];
        private _actor = objectFromNetId (_request param [3, ""]);

        if (isNull _actor) exitWith {};
        if (!alive _actor) exitWith {};
        if (_purchaseName isEqualTo "") exitWith {};
        if !(_origin isEqualType []) then {_origin = getPosATL _actor;};
        if ((count _origin) < 2) then {_origin = getPosATL _actor;};
        if ((count _origin) < 3) then {_origin = [_origin select 0, _origin select 1, 0];};

        private _actualSideKey = switch (side group _actor) do {
            case west: {"WEST"};
            case east: {"EAST"};
            case independent: {"GUER"};
            default {"CIV"};
        };
        if (_sideKey isNotEqualTo _actualSideKey) exitWith {};

        [_sideKey, _purchaseName, _origin, _actor] call Waldo_fnc_EcoBuy_executePurchase;

