/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getResourceRowsSummaryText
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getResourceRowsSummaryText via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_rows", []]];
    if ((count _rows) <= 0) exitWith {"No resources"};
    (_rows apply {format ["%1 x%2", _x param [0, ""], _x param [1, 0]]}) joinString ", "
