/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - attachBuildingActions
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_attachBuildingActions via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [
            ["_building", objNull],
            ["_entry", []]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        if (isNull _building) exitWith {};
        if ((count _entry) <= 0) then {
            _entry = [_building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]] call Waldo_fnc_EcoBuild_getBuildDefinition;
        };
        if ((count _entry) <= 0) exitWith {};

        [
            _building,
            "WaldoEcoBuild_InspectActionAddedLocal",
            [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingInspectActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_DisableActionAddedLocal",
            ["DISABLE", _entry] call Waldo_fnc_EcoBuild_getOfficialBuildingManageActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_EnableActionAddedLocal",
            ["ENABLE", _entry] call Waldo_fnc_EcoBuild_getOfficialBuildingManageActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_UpgradeActionAddedLocal",
            [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingUpgradeActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_ClaimActionAddedLocal",
            [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingClaimActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction;

