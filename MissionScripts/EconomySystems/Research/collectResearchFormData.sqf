/*
 * Author: WaldoTheWarfighter
 * Reads and normalizes one technology row from the Research curator form.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - Research editor display
 *
 * Return Value:
 * <ARRAY> normalized technology row, or [] for a null display.
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoResearch_collectResearchFormData;
 * Locality/Authority: Curator interface client only; reads local controls.
 * Repeat/JIP Behaviour: Repeat-safe form read; server validates the submitted row separately.
 * Current Callers: Research editor Save/Add button handlers.
 * Result: Returns a normalized row without changing the authoritative catalog.
 */

        params ["_disp"];

        if (isNull _disp) exitWith {[]};

        private _nameCtrl = _disp getVariable ["WaldoEcoResearch_ConfigNameEdit", controlNull];
        private _descCtrl = _disp getVariable ["WaldoEcoResearch_ConfigDescEdit", controlNull];
        private _costsCtrl = _disp getVariable ["WaldoEcoResearch_ConfigCostsEdit", controlNull];
        private _reqsCtrl = _disp getVariable ["WaldoEcoResearch_ConfigReqsEdit", controlNull];
        private _exclusiveCtrl = _disp getVariable ["WaldoEcoResearch_ConfigExclusiveEdit", controlNull];
        private _timeCtrl = _disp getVariable ["WaldoEcoResearch_ConfigTimeEdit", controlNull];
        private _colorCtrl = _disp getVariable ["WaldoEcoResearch_ConfigColorEdit", controlNull];
        private _researchedCtrl = _disp getVariable ["WaldoEcoResearch_ConfigResearchedCheck", controlNull];

        if (isNull _nameCtrl || isNull _descCtrl || isNull _costsCtrl || isNull _reqsCtrl || isNull _exclusiveCtrl || isNull _timeCtrl || isNull _colorCtrl || isNull _researchedCtrl) exitWith {[]};

        private _choices = call Waldo_fnc_EcoResource_getMarkerIconChoices;
        private _iconIndex = _disp getVariable ["WaldoEcoResearch_ConfigIconIndex", 0];
        if (_iconIndex < 0) then {_iconIndex = 0;};
        if (_iconIndex >= count _choices) then {_iconIndex = 0;};

        [[
            [ctrlText _nameCtrl] call Waldo_fnc_EcoCore_trimString,
            [ctrlText _descCtrl] call Waldo_fnc_EcoCore_trimString,
            [ctrlText _costsCtrl] call Waldo_fnc_EcoCore_parseNameValueText,
            [ctrlText _reqsCtrl] call Waldo_fnc_EcoCore_parseNameListText,
            1 max (floor (parseNumber (ctrlText _timeCtrl))),
            (_choices select _iconIndex) param [1, call Waldo_fnc_EcoResource_getDefaultResourceIcon],
            [ctrlText _colorCtrl] call Waldo_fnc_EcoResource_normalizeResourceColor,
            cbChecked _researchedCtrl,
            [ctrlText _exclusiveCtrl] call Waldo_fnc_EcoResearch_parseResearchExclusivesText
        ]] call Waldo_fnc_EcoResearch_normalizeResearchEntry

