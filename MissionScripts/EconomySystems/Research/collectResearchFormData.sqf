/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - collectResearchFormData
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_collectResearchFormData via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

