/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - stopResourceCratePlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_stopResourceCratePlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [
        _disp,
        "WaldoEcoResource_PlacementPending",
        "WaldoEcoResource_PlacementEH",
        "WaldoEcoResource_PlacementKeyEH"
    ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;
