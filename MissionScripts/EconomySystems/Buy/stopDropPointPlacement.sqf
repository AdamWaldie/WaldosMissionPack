/*
 * Author: Waldo
 * Stop drop point placement.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_stopDropPointPlacement;
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoBuy_PlacementPending",
            "WaldoEcoBuy_PlacementEH",
            "WaldoEcoBuy_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

