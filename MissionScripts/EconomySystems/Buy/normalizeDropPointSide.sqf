/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - normalizeDropPointSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_normalizeDropPointSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_value", "ANY"]];

        private _trimmed = toUpper ([_value] call Waldo_fnc_EcoCore_trimString);
        if (_trimmed in ["EVERYONE", "ANY", "ALL"]) exitWith {"ANY"};
        if (_trimmed in ["BLUFOR", "WEST"]) exitWith {"WEST"};
        if (_trimmed in ["OPFOR", "EAST"]) exitWith {"EAST"};
        if (_trimmed in ["INDEP", "INDFOR", "GUER", "INDEPENDENT"]) exitWith {"GUER"};
        "ANY"

