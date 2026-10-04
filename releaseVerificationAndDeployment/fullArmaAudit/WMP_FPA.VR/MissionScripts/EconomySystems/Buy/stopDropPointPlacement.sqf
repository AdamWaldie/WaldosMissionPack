/*
 * Author: WaldoTheWarfighter
 * Ends a curator delivery-point placement session and removes its handlers.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - curator prompt (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuy_stopDropPointPlacement;
 * Locality/Authority: Curator interface client; local placement only.
 * Repeat/JIP Behaviour: Repeat cleanup is safe; unfinished placement is not replayed to JIP.
 * Current Callers: Delivery-point placement complete/cancel paths.
 * Result: Temporary placement state and event handlers are removed.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoBuy_PlacementPending",
            "WaldoEcoBuy_PlacementEH",
            "WaldoEcoBuy_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

