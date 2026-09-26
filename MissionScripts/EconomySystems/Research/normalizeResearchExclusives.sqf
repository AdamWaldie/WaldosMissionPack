/*
 * Author: WaldoTheWarfighter
 * Removes blanks and duplicate names from a technology's exclusive choices.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _rows <ARRAY> - rows (optional, default: [])
 *
 * Return Value:
 * <ARRAY of STRING> normalized exclusive technology names.
 *
 * Example:
 * [_rows] call Waldo_fnc_EcoResearch_normalizeResearchExclusives;
 * Locality/Authority: Any machine; pure name-list normalization.
 * Repeat/JIP Behaviour: Deterministic and stateless; no JIP effect.
 * Current Callers: Research entry normalization and curator text parser.
 * Result: Returns a clean list for the technology catalog.
 */

        params [["_rows", []]];
        [_rows] call Waldo_fnc_EcoCore_normalizeNameList

