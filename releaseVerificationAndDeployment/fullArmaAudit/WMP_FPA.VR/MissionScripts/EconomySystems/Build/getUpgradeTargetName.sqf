/*
 * Author: WaldoTheWarfighter
 * Reads the configured next-tier name from a building's current definition.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 *
 * Return Value:
 * <STRING> upgrade target name, or "" when none exists.
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetName;
 * Locality/Authority: Any machine; read-only building/catalog lookup.
 * Repeat/JIP Behaviour: Repeat-safe; JIP sees current public state.
 * Current Callers: Upgrade target lookup and building-management action.
 * Result: Returns an empty string for invalid or terminal-tier buildings.
 */

        params [["_building", objNull]];

        if (isNull _building) exitWith {""};

        private _buildName = _building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""];
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {""};

        _entry param [18, ""]

