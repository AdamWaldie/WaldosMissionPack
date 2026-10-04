/*
 * Author: WaldoTheWarfighter
 * Ends a curator Construction placement session and removes its input handlers.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - curator prompt (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_stopConstructionPlacement;
 * Locality/Authority: Curator interface client; local placement only.
 * Repeat/JIP Behaviour: Repeat cleanup is safe; unfinished preview is not JIP state.
 * Current Callers: Construction placement complete/cancel paths.
 * Result: Temporary placement state and handlers are removed.
 */

        params [["_disp", displayNull]];

        if (isNull _disp) exitWith {};

        [
            _disp,
            "WaldoEcoBuild_PlacementPending",
            "WaldoEcoBuild_PlacementEH",
            "WaldoEcoBuild_PlacementKeyEH"
        ] call Waldo_fnc_EcoCore_stopZeusPlacementSession;

