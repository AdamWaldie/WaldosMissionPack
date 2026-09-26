/*
 * Author: WaldoTheWarfighter
 * Checks whether a side owns an operational completed building of the named type.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _buildName <STRING> - build name (optional, default: "")
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true for a matching, operational, side-owned building.
 *
 * Example:
 * [_buildName, _sideKey] call Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide;
 * Locality/Authority: Any machine; reads public building ownership/operational state.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP sees current registered buildings.
 * Current Callers: Construction, Research and Purchasing prerequisite checks.
 * Result: Enemy, disabled or deleted buildings do not satisfy the side requirement.
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

