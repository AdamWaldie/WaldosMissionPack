/*
 * Author: WaldoTheWarfighter
 * Publish the inspect, manage, upgrade and claim actions for a built structure.
 *
 * Locality / Authority: Economy authority only. Action descriptors are published so clients,
 * including JIP clients, can install their own object interactions.
 * Repeat/JIP: The publication keys let the shared action installer replace its
 * local version; do not call this for an invalid or unregistered building.
 * Current Callers: EcoBuild_spawnConfiguredBuilding.
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 * 1: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Nothing; exits without publishing when authority, object or entry is invalid.
 * Result: Valid buildings receive the five official action descriptors.
 *
 * Example:
 * [_building, _entry] call Waldo_fnc_EcoBuild_attachBuildingActions;
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
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_DisableActionAddedLocal",
            ["DISABLE", _entry] call Waldo_fnc_EcoBuild_getOfficialBuildingManageActionArgs
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_EnableActionAddedLocal",
            ["ENABLE", _entry] call Waldo_fnc_EcoBuild_getOfficialBuildingManageActionArgs
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_UpgradeActionAddedLocal",
            [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingUpgradeActionArgs
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction;

        [
            _building,
            "WaldoEcoBuild_ClaimActionAddedLocal",
            [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingClaimActionArgs
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction;

