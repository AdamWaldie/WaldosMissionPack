/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getBuildDefinition
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getBuildDefinition via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_buildName", ""]];

        private _catalog = call Waldo_fnc_EcoBuild_getBuildCatalog;
        private _index = _catalog findIf {
            (toLower (_x param [0, ""])) isEqualTo (toLower _buildName)
        };
        if (_index < 0) exitWith {[]};
        +(_catalog select _index)

