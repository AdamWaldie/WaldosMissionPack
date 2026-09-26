/*
 * Author: WaldoTheWarfighter
 * Advances the building-spawn prompt's owner-side selector.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - spawn prompt
 * 1: _delta <NUMBER> - selector step (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuild_cycleSpawnBuildingSide;
 * Locality/Authority: Curator interface client; local selection only.
 * Repeat/JIP Behaviour: Repeat calls advance selection; no JIP state until placement.
 * Current Callers: Building-spawn prompt side arrows.
 * Result: The side label reflects the new selection.
 */

        params ["_disp", ["_delta", 0]];

        if (isNull _disp) exitWith {};
        _disp setVariable ["WaldoEcoBuild_SpawnSideIndex", (_disp getVariable ["WaldoEcoBuild_SpawnSideIndex", 0]) + _delta];
        [_disp] call Waldo_fnc_EcoBuild_refreshSpawnBuildingSide;

