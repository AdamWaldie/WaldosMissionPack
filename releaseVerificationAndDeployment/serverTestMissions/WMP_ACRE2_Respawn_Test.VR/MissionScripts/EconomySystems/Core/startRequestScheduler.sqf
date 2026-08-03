/* Consolidated server-authority request scheduler for all economy systems. */
if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
if (missionNamespace getVariable ["WaldoEcoCore_RequestSchedulerStarted", false]) exitWith {};
missionNamespace setVariable ["WaldoEcoCore_RequestSchedulerStarted", true];

[] spawn {
    private _nextRecovery = 0;
    while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
        if (serverTime >= _nextRecovery) then {
            call Waldo_fnc_EcoCore_refreshRuntimeRegistries;
            _nextRecovery = serverTime + 10;
        };

        {
            private _zoneRequest = _x getVariable ["WaldoEcoResource_ZoneCaptureRequest", []];
            if (_zoneRequest isEqualType [] && {(count _zoneRequest) > 0}) then {
                [_x, _zoneRequest] call Waldo_fnc_EcoResource_processZoneCaptureRequest;
            };
            private _researchRequest = _x getVariable ["WaldoEcoResearch_StartResearchRequest", []];
            if (_researchRequest isEqualType [] && {(count _researchRequest) > 0}) then {
                [_x, _researchRequest] call Waldo_fnc_EcoResearch_processStartResearchRequest;
            };
        } forEach allPlayers;

        {
            private _anchor = _x param [10, objNull];
            if (!isNull _anchor) then {
                private _request = _anchor getVariable ["WaldoEcoResource_ZoneCaptureRequest", []];
                if (_request isEqualType [] && {(count _request) > 0}) then {
                    [_anchor, _request] call Waldo_fnc_EcoResource_processZoneCaptureRequest;
                };
            };
        } forEach (call Waldo_fnc_EcoResource_getResourceZones);

        {
            private _request = _x getVariable ["WaldoEcoResource_CollectRequest", []];
            if (_request isEqualType [] && {(count _request) > 0}) then {
                [_x, _request] call Waldo_fnc_EcoResource_processCrateCollectRequest;
            };
        } forEach (["CRATES"] call Waldo_fnc_EcoCore_getRuntimeObjects);

        {
            private _request = _x getVariable ["WaldoEcoResearch_StartResearchRequest", []];
            if (_request isEqualType [] && {(count _request) > 0}) then {
                [_x, _request] call Waldo_fnc_EcoResearch_processStartResearchRequest;
            };
            private _constructionRequest = _x getVariable ["WaldoEcoBuild_StartConstructionRequest", []];
            if (_constructionRequest isEqualType [] && {(count _constructionRequest) > 0}) then {
                [_x, _constructionRequest] call Waldo_fnc_EcoBuild_processStartConstructionRequest;
            };
        } forEach (["RESEARCH_CENTERS"] call Waldo_fnc_EcoCore_getRuntimeObjects);

        {
            private _request = _x getVariable ["WaldoEcoBuild_StartConstructionRequest", []];
            if (_request isEqualType [] && {(count _request) > 0}) then {
                [_x, _request] call Waldo_fnc_EcoBuild_processStartConstructionRequest;
            };
        } forEach (["CONSTRUCTION_VEHICLES"] call Waldo_fnc_EcoCore_getRuntimeObjects);

        {
            private _request = _x getVariable ["WaldoEcoBuild_BuildingManageRequest", []];
            if (_request isEqualType [] && {(count _request) > 0}) then {
                [_x, _request] call Waldo_fnc_EcoBuild_processBuildingManageRequest;
            };
        } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);

        {
            private _request = _x getVariable ["WaldoEcoBuy_PurchaseRequest", []];
            if (_request isEqualType [] && {(count _request) > 0}) then {
                [_x, _request] call Waldo_fnc_EcoBuy_processPurchaseRequest;
            };
        } forEach (["PURCHASE_TERMINALS"] call Waldo_fnc_EcoCore_getRuntimeObjects);

        uiSleep 0.25;
    };
    missionNamespace setVariable ["WaldoEcoCore_RequestSchedulerStarted", false];
};
