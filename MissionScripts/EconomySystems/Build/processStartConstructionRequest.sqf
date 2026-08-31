/*
 * Author: WaldoTheWarfighter
 * Process start construction request.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 * Locality / Authority: Server authority only; retains the existing placement, access, requirement and
 * resource validation before starting authoritative construction state.
 * Repeat / JIP Behaviour: Bounded request-token history rejects duplicates. Requests are transient and
 * never replayed to JIP; a legacy mailbox is cleared only when populated.
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
 * [_holder, _request] call Waldo_fnc_EcoBuild_processStartConstructionRequest;
 */

        params [["_holder", objNull], ["_request", []]];

        if (isNull _holder) exitWith {};
        if !(_request isEqualType []) exitWith {};
        if ((count _request) < 6) exitWith {};

        private _requestId = _request param [5, ""];
        if (_requestId isEqualTo "") exitWith {};

        private _handled = missionNamespace getVariable ["WaldoEcoBuild_StartConstructionRequestsHandled", []];
        if !(_handled isEqualType []) then {_handled = [];};
        if (_requestId in _handled) exitWith {
            if !((_holder getVariable ["WaldoEcoBuild_StartConstructionRequest", []]) isEqualTo []) then {
                _holder setVariable ["WaldoEcoBuild_StartConstructionRequest", [], true];
            };
        };

        _handled pushBack _requestId;
        while {(count _handled) > 64} do {
            _handled deleteAt 0;
        };
        missionNamespace setVariable ["WaldoEcoBuild_StartConstructionRequestsHandled", _handled];

        if !((_holder getVariable ["WaldoEcoBuild_StartConstructionRequest", []]) isEqualTo []) then {
            _holder setVariable ["WaldoEcoBuild_StartConstructionRequest", [], true];
        };

        private _buildName = _request param [0, ""];
        private _source = objectFromNetId (_request param [1, ""]);
        private _actor = objectFromNetId (_request param [2, ""]);
        private _pos = _request param [3, []];
        private _dir = _request param [4, 0];

        if (isNull _source) then {_source = _holder;};
        if (isNull _actor) exitWith {};
        if (!alive _actor) exitWith {};
        if (_buildName isEqualTo "") exitWith {};
        if !(_pos isEqualType []) exitWith {};
        if ((count _pos) < 2) exitWith {};
        if ((count _pos) < 3) then {_pos = [_pos select 0, _pos select 1, 0];};

        [_pos, _dir, _actor, _buildName, _source] call Waldo_fnc_EcoBuild_startPlacedConstruction;

