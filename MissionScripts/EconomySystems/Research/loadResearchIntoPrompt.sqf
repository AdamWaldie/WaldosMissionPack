/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - loadResearchIntoPrompt
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_loadResearchIntoPrompt via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params ["_disp", ["_index", -1]];

        if (isNull _disp) exitWith {};

        private _catalog = call Waldo_fnc_EcoResearch_getResearchCatalog;
        private _nameCtrl = _disp getVariable ["WaldoEcoResearch_ConfigNameEdit", controlNull];
        private _descCtrl = _disp getVariable ["WaldoEcoResearch_ConfigDescEdit", controlNull];
        private _costsCtrl = _disp getVariable ["WaldoEcoResearch_ConfigCostsEdit", controlNull];
        private _reqsCtrl = _disp getVariable ["WaldoEcoResearch_ConfigReqsEdit", controlNull];
        private _exclusiveCtrl = _disp getVariable ["WaldoEcoResearch_ConfigExclusiveEdit", controlNull];
        private _timeCtrl = _disp getVariable ["WaldoEcoResearch_ConfigTimeEdit", controlNull];
        private _colorCtrl = _disp getVariable ["WaldoEcoResearch_ConfigColorEdit", controlNull];
        private _researchedCtrl = _disp getVariable ["WaldoEcoResearch_ConfigResearchedCheck", controlNull];

        if (_index < 0 || {_index >= count _catalog}) exitWith {
            _disp setVariable ["WaldoEcoResearch_ConfigSelectedIndex", -1];
            if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText ""; _nameCtrl ctrlCommit 0;};
            if (!isNull _descCtrl) then {_descCtrl ctrlSetText ""; _descCtrl ctrlCommit 0;};
            if (!isNull _costsCtrl) then {_costsCtrl ctrlSetText ""; _costsCtrl ctrlCommit 0;};
            if (!isNull _reqsCtrl) then {_reqsCtrl ctrlSetText ""; _reqsCtrl ctrlCommit 0;};
            if (!isNull _exclusiveCtrl) then {_exclusiveCtrl ctrlSetText ""; _exclusiveCtrl ctrlCommit 0;};
            if (!isNull _timeCtrl) then {_timeCtrl ctrlSetText "60"; _timeCtrl ctrlCommit 0;};
            if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText "#FFFFFF"; _colorCtrl ctrlCommit 0;};
            if (!isNull _researchedCtrl) then {_researchedCtrl cbSetChecked false;};
            _disp setVariable ["WaldoEcoResearch_ConfigIconIndex", 0];
            [_disp] call Waldo_fnc_EcoResearch_refreshResearchConfigIcon;
        };

        private _entry = _catalog select _index;
        _disp setVariable ["WaldoEcoResearch_ConfigSelectedIndex", _index];

        if (!isNull _nameCtrl) then {_nameCtrl ctrlSetText (_entry param [0, ""]); _nameCtrl ctrlCommit 0;};
        if (!isNull _descCtrl) then {_descCtrl ctrlSetText (_entry param [1, ""]); _descCtrl ctrlCommit 0;};
        if (!isNull _costsCtrl) then {_costsCtrl ctrlSetText ([(_entry param [2, []])] call Waldo_fnc_EcoCore_formatNameValueText); _costsCtrl ctrlCommit 0;};
        if (!isNull _reqsCtrl) then {_reqsCtrl ctrlSetText ([(_entry param [3, []])] call Waldo_fnc_EcoCore_formatNameListText); _reqsCtrl ctrlCommit 0;};
        if (!isNull _exclusiveCtrl) then {_exclusiveCtrl ctrlSetText ([(_entry param [8, []])] call Waldo_fnc_EcoCore_formatNameListText); _exclusiveCtrl ctrlCommit 0;};
        if (!isNull _timeCtrl) then {_timeCtrl ctrlSetText str (_entry param [4, 60]); _timeCtrl ctrlCommit 0;};
        if (!isNull _colorCtrl) then {_colorCtrl ctrlSetText (_entry param [6, "#FFFFFF"]); _colorCtrl ctrlCommit 0;};
        if (!isNull _researchedCtrl) then {_researchedCtrl cbSetChecked (_entry param [7, false]);};

        _disp setVariable ["WaldoEcoResearch_ConfigIconIndex", [(_entry param [5, ""])] call Waldo_fnc_EcoCore_findMarkerIconIndex];
        [_disp] call Waldo_fnc_EcoResearch_refreshResearchConfigIcon;

