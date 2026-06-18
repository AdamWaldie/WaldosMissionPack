/*
 * Author: Waldo
 * Purge building values.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoCore_purgeBuildingValues;
 */

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};

    {
        private _siteItems = _x param [1, []];
        [_siteItems] call Waldo_fnc_EcoBuild_deleteConstructionSite;
    } forEach (call Waldo_fnc_EcoBuild_getConstructionJobRuntime);

    {
        private _building = _x param [1, objNull];
        if (isNull _building) then {continue;};
        [_building] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
        [_building] call Waldo_fnc_EcoBuild_deleteBuildingMarker;
        deleteVehicle _building;
    } forEach (call Waldo_fnc_EcoBuild_getUpgradeJobRuntime);

    {
        if (isNull _x) then {continue;};
        [_x] call Waldo_fnc_EcoBuild_cleanupDetectorVisuals;
        [_x] call Waldo_fnc_EcoBuild_deleteBuildingMarker;
        deleteVehicle _x;
    } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);

    {
        if (isNull _x) then {continue;};
        deleteVehicle _x;
    } forEach (vehicles select {_x getVariable ["WaldoEcoBuild_IsConstructionVehicle", false]});

    {
        if (isNull _x) then {continue;};
        deleteVehicle _x;
    } forEach ((allMissionObjects "Land_Research_HQ_F") select {_x getVariable ["WaldoEcoResearch_IsResearchCenter", false]});

    {
        if (isNull _x) then {continue;};
        deleteVehicle _x;
    } forEach ((allMissionObjects "Land_Laptop_unfolded_F") select {_x getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]});

    {
        private _dropId = _x param [0, ""];
        if (_dropId isEqualTo "") then {continue;};
        [_dropId, true] call Waldo_fnc_EcoBuy_deleteDropPoint;
    } forEach +(call Waldo_fnc_EcoBuy_getDropPoints);

    [[]] call Waldo_fnc_EcoBuild_setSpawnedBuildings;
    [[]] call Waldo_fnc_EcoBuild_setActiveConstructionJobs;
    [[]] call Waldo_fnc_EcoBuild_setConstructionJobRuntime;
    [[]] call Waldo_fnc_EcoBuild_setUpgradeJobRuntime;
    [[]] call Waldo_fnc_EcoBuy_setDropPoints;
