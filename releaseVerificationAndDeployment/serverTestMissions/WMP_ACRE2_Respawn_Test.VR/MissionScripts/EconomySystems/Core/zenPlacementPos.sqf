/*
 * Author: WaldoTheWarfighter
 * Zen placement pos.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Converts a ZEN custom-module drop position (which ZEN provides in ASL) into the world
 * position the Economy spawn / prompt handlers expect. Those handlers were originally fed
 * screenToWorld coordinates (AGL), so ASL -> AGL keeps parity. This is the single tuning
 * point for module placement height: if in-engine testing shows objects placed too high /
 * low (e.g. over water), retune the conversion here rather than in every placement module.
 *
 * Arguments:
 * 0: _moduleAslPos <ARRAY> - the ASL position handed to a ZEN module's code (optional, default: [0,0,0])
 *
 * Return Value:
 * World position <ARRAY> - AGL position for the spawn / prompt handlers
 *
 * Example:
 * private _worldPos = [_modulePos] call Waldo_fnc_EcoCore_zenPlacementPos;
 */

    params [["_moduleAslPos", [0, 0, 0]]];

    ASLToAGL _moduleAslPos
