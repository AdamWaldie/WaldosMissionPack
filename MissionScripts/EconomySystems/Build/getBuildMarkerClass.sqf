/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getBuildMarkerClass
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getBuildMarkerClass via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_iconPath", ""]];

        private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _index = _choices findIf {
            ((_x param [1, ""]) isEqualTo _iconPath)
        };

        if (_index < 0) exitWith {"mil_dot"};
        (_choices select _index) param [0, "mil_dot"]

