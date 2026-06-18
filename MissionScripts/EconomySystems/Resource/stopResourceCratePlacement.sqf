/*
 * Author: Waldo
 * Stop resource crate placement.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    [
        _disp,
        "WaldoEcoResource_PlacementPending",
        "WaldoEcoResource_PlacementEH",
        "WaldoEcoResource_PlacementKeyEH"
    ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;
