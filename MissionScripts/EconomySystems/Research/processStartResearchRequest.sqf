/*
 * Author: Waldo
 * Process start research request.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _holder <OBJECT> - holder (optional, default: objNull)
 * 1: _request <ARRAY> - request (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_holder, _request] call Waldo_fnc_EcoResearch_processStartResearchRequest;
 */

        params [["_holder", objNull], ["_request", []]];

        if (isNull _holder) exitWith {};
        if !(_request isEqualType []) exitWith {};
        if ((count _request) < 7) exitWith {};

        private _requestId = _request param [6, ""];
        if (_requestId isEqualTo "") exitWith {};

        private _handled = missionNamespace getVariable ["WaldoEcoResearch_StartResearchRequestsHandled", []];
        if !(_handled isEqualType []) then {_handled = [];};
        if (_requestId in _handled) exitWith {
            _holder setVariable ["WaldoEcoResearch_StartResearchRequest", [], true];
        };

        _handled pushBack _requestId;
        while {(count _handled) > 64} do {
            _handled deleteAt 0;
        };
        missionNamespace setVariable ["WaldoEcoResearch_StartResearchRequestsHandled", _handled];

        _holder setVariable ["WaldoEcoResearch_StartResearchRequest", [], true];

        private _sideKey = _request param [0, "NONE"];
        private _researchName = _request param [1, ""];
        private _center = objectFromNetId (_request param [2, ""]);
        private _requestPos = _request param [3, []];
        private _actor = objectFromNetId (_request param [7, ""]);
        if (isNull _actor) then {
            _actor = _holder;
        };

        if (isNull _center || {!(_center getVariable ["WaldoEcoResearch_IsResearchCenter", false])}) exitWith {};
        if (isNull _actor) exitWith {};
        private _withinRequestDistance = true;
        if (_requestPos isEqualType [] && {(count _requestPos) >= 2}) then {
            _withinRequestDistance = (_requestPos distance2D _center) <= 12;
        };
        if (!_withinRequestDistance) exitWith {};
        if ((_actor distance2D _center) > 20) exitWith {};

        [_sideKey, _researchName, _actor] call Waldo_fnc_EcoResearch_startResearch;

