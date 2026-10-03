/*
 * Author: WaldoTheWarfighter
 * Finds one Construction definition by name, ignoring letter case.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _buildName <STRING> - build name (optional, default: "")
 *
 * Return Value:
 * <ARRAY> matching build row, or [] when absent.
 *
 * Example:
 * [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
 * Locality/Authority: Any machine; reads the published catalog without mutation.
 * Repeat/JIP Behaviour: Repeat-safe lookup; JIP sees current catalog state.
 * Current Callers: Construction placement, status and building-upgrade helpers.
 * Result: Returns a copy of the matching definition.
 */

        params [["_buildName", ""]];

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _index = _catalog findIf {
            (toLower (_x param [0, ""])) isEqualTo (toLower _buildName)
        };
        if (_index < 0) exitWith {[]};
        +(_catalog select _index)

