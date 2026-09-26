/*
 * Author: WaldoTheWarfighter
 * Replaces and broadcasts the authoritative purchase delivery-point registry.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoBuy_setDropPoints;
 * Locality/Authority: Economy authority only; clients read the published rows.
 * Repeat/JIP Behaviour: Replacement is repeat-safe; JIP receives the latest registry.
 * Current Callers: Drop-point create/delete and Economy setup/import paths.
 * Result: Purchase delivery lookup uses the supplied rows.
 */

        params [["_rows", []]];
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuy_DropPoints", _rows, true];

