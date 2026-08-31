/*
 * Author: WaldoTheWarfighter
 * Process building manage request.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 * Locality / Authority: Server authority only; validates and applies claim, enable, disable and upgrade
 * operations through the existing Economy transaction functions.
 * Repeat / JIP Behaviour: Existing bounded request-token history rejects duplicates. Direct requests
 * are not JIP state; legacy mailbox state is cleared only when it is actually present.
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Current Callers: Waldo_fnc_EcoCore_submitRequestServer and the documented legacy processor API.
 *
 * Example:
 * [_building, _request] call Waldo_fnc_EcoBuild_processBuildingManageRequest;
 */

        params [["_building", objNull], ["_request", []]];

        if (isNull _building) exitWith {};
        private _clearLegacyRequest = {
            if !((_building getVariable ["WaldoEcoBuild_BuildingManageRequest", []]) isEqualTo []) then {
                _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [], true];
            };
        };
        if !(_request isEqualType []) exitWith {
            call _clearLegacyRequest;
        };
        if ((count _request) < 3) exitWith {
            call _clearLegacyRequest;
        };

        private _requestId = _request param [2, ""];
        if (_requestId isEqualTo "") exitWith {
            call _clearLegacyRequest;
        };

        private _handled = missionNamespace getVariable ["WaldoEcoBuild_BuildingManageRequestsHandled", []];
        if !(_handled isEqualType []) then {_handled = [];};
        if (_requestId in _handled) exitWith {
            call _clearLegacyRequest;
        };

        _handled pushBack _requestId;
        while {(count _handled) > 64} do {
            _handled deleteAt 0;
        };
        missionNamespace setVariable ["WaldoEcoBuild_BuildingManageRequestsHandled", _handled];

        call _clearLegacyRequest;

        private _operation = _request param [0, ""];
        private _actor = objectFromNetId (_request param [1, ""]);
        if (isNull _actor) exitWith {};

        if (_operation isEqualTo "DISABLE") exitWith {
            [_building, _actor] call Waldo_fnc_EcoBuild_disableBuilding;
        };
        if (_operation isEqualTo "ENABLE") exitWith {
            [_building, _actor] call Waldo_fnc_EcoBuild_enableBuilding;
        };
        if (_operation isEqualTo "CLAIM") exitWith {
            [_building, _actor] call Waldo_fnc_EcoBuild_claimBuilding;
        };
        if (_operation isEqualTo "UPGRADE") exitWith {
            [_building, _actor] call Waldo_fnc_EcoBuild_startBuildingUpgrade;
        };

