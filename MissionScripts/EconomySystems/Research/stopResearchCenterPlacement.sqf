/*
 * Author: Waldo
 * Stop research center placement.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResearch_stopResearchCenterPlacement;
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoResearch_PlacementPending",
            "WaldoEcoResearch_PlacementEH",
            "WaldoEcoResearch_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

