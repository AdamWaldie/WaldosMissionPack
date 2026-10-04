/*
 * Author: WaldoTheWarfighter
 * Checks whether any operational completed building satisfies a named requirement.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _buildName <STRING> - build name (optional, default: "")
 *
 * Return Value:
 * <BOOL> true when a matching operational building exists.
 *
 * Example:
 * [_buildName] call Waldo_fnc_EcoBuild_isBuildRequirementSatisfied;
 * Locality/Authority: Any machine; reads public completed-building registry.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP sees current objects/definitions.
 * Current Callers: No in-pack caller; available to mission scripts checking any-side requirements.
 * Result: Disabled or deleted buildings do not satisfy the requirement.
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

