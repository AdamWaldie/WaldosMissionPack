/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceTypes
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceTypes via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    (call Waldo_fnc_EcoResource_getResourceCatalog) apply {_x param [0, "Resource"]}
