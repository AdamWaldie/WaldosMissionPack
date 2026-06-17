/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - processBuildingManageRequest
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_processBuildingManageRequest via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_building", objNull], ["_request", []]];

        if (isNull _building) exitWith {};
        if !(_request isEqualType []) exitWith {
            _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [], true];
        };
        if ((count _request) < 3) exitWith {
            _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [], true];
        };

        private _requestId = _request param [2, ""];
        if (_requestId isEqualTo "") exitWith {
            _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [], true];
        };

        private _handled = missionNamespace getVariable ["WaldoEcoBuild_BuildingManageRequestsHandled", []];
        if !(_handled isEqualType []) then {_handled = [];};
        if (_requestId in _handled) exitWith {
            _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [], true];
        };

        _handled pushBack _requestId;
        while {(count _handled) > 64} do {
            _handled deleteAt 0;
        };
        missionNamespace setVariable ["WaldoEcoBuild_BuildingManageRequestsHandled", _handled, true];

        _building setVariable ["WaldoEcoBuild_BuildingManageRequest", [], true];

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

