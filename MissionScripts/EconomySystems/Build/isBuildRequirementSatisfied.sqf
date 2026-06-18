/*
 * Author: Waldo
 * Is build requirement satisfied.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _buildName <STRING> - build name (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_buildName] call Waldo_fnc_EcoBuild_isBuildRequirementSatisfied;
 */

        params [["_buildName", ""]];

        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {false};
        private _rows = call Waldo_fnc_EcoBuild_getSpawnedBuildings;
        (_rows findIf {
            !isNull _x
            && {(_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]) isEqualTo (_entry param [0, ""])}
            && {_x getVariable ["WaldoEcoBuild_Operational", true]}
        }) >= 0

