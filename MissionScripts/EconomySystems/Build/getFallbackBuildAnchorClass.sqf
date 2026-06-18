/*
 * Author: Waldo
 * Get fallback build anchor class.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_getFallbackBuildAnchorClass;
 */

        private _fallbackClass = "PortableHelipadLight_01_red_F";
        if (isClass (configFile >> "CfgVehicles" >> _fallbackClass)) exitWith {_fallbackClass};
        "Land_HelipadEmpty_F"

