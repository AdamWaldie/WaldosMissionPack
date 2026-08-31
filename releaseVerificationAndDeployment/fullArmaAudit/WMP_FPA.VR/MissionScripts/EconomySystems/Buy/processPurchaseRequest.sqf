/*
 * Author: WaldoTheWarfighter
 * Process purchase request.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 * Locality / Authority: Server authority only; retains existing catalogue, side, range, cost, delivery
 * and transaction behaviour.
 * Repeat / JIP Behaviour: Existing bounded request-token history rejects duplicate purchases. Requests
 * are transient and not JIP state; legacy mailbox cleanup runs only if a value exists.
 *
 * Arguments:
 * 0: _holder <OBJECT> - holder (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Current Callers: Waldo_fnc_EcoCore_submitRequestServer and the documented legacy processor API.
 *
 * Example:
 * [_holder, _request] call Waldo_fnc_EcoBuy_processPurchaseRequest;
 */

        params [["_holder", objNull], ["_request", []]];

        if (isNull _holder) exitWith {};
        private _clearLegacyRequest = {
            if !((_holder getVariable ["WaldoEcoBuy_PurchaseRequest", []]) isEqualTo []) then {
                _holder setVariable ["WaldoEcoBuy_PurchaseRequest", [], true];
            };
        };
        if !(_request isEqualType []) exitWith {
            call _clearLegacyRequest;
        };
        if ((count _request) < 5) exitWith {
            call _clearLegacyRequest;
        };

        private _requestId = _request param [4, ""];
        if (_requestId isEqualTo "") exitWith {
            call _clearLegacyRequest;
        };

        private _handled = missionNamespace getVariable ["WaldoEcoBuy_PurchaseRequestsHandled", []];
        if !(_handled isEqualType []) then {_handled = [];};
        if (_requestId in _handled) exitWith {
            call _clearLegacyRequest;
        };

        _handled pushBack _requestId;
        while {(count _handled) > 64} do {
            _handled deleteAt 0;
        };
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseRequestsHandled", _handled];

        call _clearLegacyRequest;

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

