/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - formatResourceRowsText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_formatResourceRowsText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_rows", []]];
    (_rows apply {format ["%1=%2", _x param [0, ""], _x param [1, 0]]}) joinString toString [10]
