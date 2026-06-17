/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - isBuildRequirementSatisfiedForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_buildName", ""], ["_sideKey", "NONE"]];

        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {false};
        private _rows = call Waldo_fnc_EcoBuild_getSpawnedBuildings;
        (_rows findIf {
            !isNull _x
            && {(_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]) isEqualTo (_entry param [0, ""])}
            && {(_x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) isEqualTo _sideKey}
            && {_x getVariable ["WaldoEcoBuild_Operational", true]}
        }) >= 0

