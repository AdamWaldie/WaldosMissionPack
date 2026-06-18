/*
 * Author: Waldo
 * Get build definition.
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
 * [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
 */

        params [["_buildName", ""]];

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _index = _catalog findIf {
            (toLower (_x param [0, ""])) isEqualTo (toLower _buildName)
        };
        if (_index < 0) exitWith {[]};
        +(_catalog select _index)

