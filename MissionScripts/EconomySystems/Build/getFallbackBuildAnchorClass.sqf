/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getFallbackBuildAnchorClass
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getFallbackBuildAnchorClass via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        private _fallbackClass = "PortableHelipadLight_01_red_F";
        if (isClass (configFile >> "CfgVehicles" >> _fallbackClass)) exitWith {_fallbackClass};
        "Land_HelipadEmpty_F"

