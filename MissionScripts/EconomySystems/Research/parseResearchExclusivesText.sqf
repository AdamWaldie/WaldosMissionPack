/*
 * Author: Waldo
 * Parse research exclusives text.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _text <STRING> - text (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_text] call Waldo_fnc_EcoResearch_parseResearchExclusivesText;
 */

        params [["_text", ""]];
        [[_text] call Waldo_fnc_EcoCore_parseNameListText] call Waldo_fnc_EcoResearch_normalizeResearchExclusives

