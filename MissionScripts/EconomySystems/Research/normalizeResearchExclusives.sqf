/*
 * Author: Waldo
 * Normalize research exclusives.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoResearch_normalizeResearchExclusives;
 */

        params [["_rows", []]];
        [_rows] call Waldo_fnc_EcoCore_normalizeNameList

