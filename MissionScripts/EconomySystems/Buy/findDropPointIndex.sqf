/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - findDropPointIndex
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_findDropPointIndex via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_dropPointId", ""]];

        private _rows = call Waldo_fnc_EcoBuy_getDropPoints;
        _rows findIf {((_x param [0, ""]) isEqualTo _dropPointId)}

