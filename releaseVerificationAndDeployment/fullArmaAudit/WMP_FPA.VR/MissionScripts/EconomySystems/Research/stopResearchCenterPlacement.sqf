/*
 * Author: WaldoTheWarfighter
 * Ends an in-progress curator Research Center placement session.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - curator prompt (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResearch_stopResearchCenterPlacement;
 * Locality/Authority: Curator interface client; removes local placement handlers.
 * Repeat/JIP Behaviour: Repeat cleanup is safe; no unfinished placement is replayed to JIP.
 * Current Callers: Research Center placement completion/cancel flows.
 * Result: Temporary placement state and event handlers are removed.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoResearch_PlacementPending",
            "WaldoEcoResearch_PlacementEH",
            "WaldoEcoResearch_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

