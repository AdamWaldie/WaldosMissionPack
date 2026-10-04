/*
 * Author: WaldoTheWarfighter
 * Redraws the Construction editor's selected marker icon preview.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - editor display
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_refreshBuildConfigIcon;
 * Locality/Authority: Curator interface client; presentation only.
 * Repeat/JIP Behaviour: Repeat-safe redraw; no JIP state.
 * Current Callers: Construction editor load-row and icon selector controls.
 * Result: Preview matches the current icon index.
 */

        params ["_disp"];
        [_disp, "WaldoEcoBuild_ConfigIconIndex", "WaldoEcoBuild_ConfigIconValue"] call Waldo_fnc_EcoCore_refreshMarkerIconSelector;

