/*
 * Author: WaldoTheWarfighter
 * Parses curator-entered exclusive technology names into a normalized list.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _text <STRING> - text (optional, default: "")
 *
 * Return Value:
 * <ARRAY of STRING> normalized names.
 *
 * Example:
 * [_text] call Waldo_fnc_EcoResearch_parseResearchExclusivesText;
 * Locality/Authority: Curator interface client; pure text parsing.
 * Repeat/JIP Behaviour: Stateless; no JIP effect until a catalog update is submitted.
 * Current Callers: Research editor form collection.
 * Result: Returns the names used by Research entry normalization.
 */

        params [["_text", ""]];
        [[_text] call Waldo_fnc_EcoCore_parseNameListText] call Waldo_fnc_EcoResearch_normalizeResearchExclusives

