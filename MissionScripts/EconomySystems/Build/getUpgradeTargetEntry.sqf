/*
 * Author: WaldoTheWarfighter
 * Resolves a building's next-tier Construction definition.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _building <OBJECT> - building (optional, default: objNull)
 *
 * Return Value:
 * <ARRAY> next-tier definition, or [] when no target exists.
 *
 * Example:
 * [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetEntry;
 * Locality/Authority: Any machine; reads public building/catalog state.
 * Repeat/JIP Behaviour: Repeat-safe lookup; JIP sees current definition and building tag.
 * Current Callers: EcoBuild_startBuildingUpgrade server-side target lookup.
 * Result: Terminal-tier buildings return an empty row.
 */

        params [["_building", objNull]];

        private _targetName = [_building] call Waldo_fnc_EcoBuild_getUpgradeTargetName;
        if (_targetName isEqualTo "") exitWith {[]};

        [_targetName] call Waldo_fnc_EcoBuild_getBuildDefinition

