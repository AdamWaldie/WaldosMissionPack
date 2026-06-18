/*
 * Author: Waldo
 * Are research requirements met.
 *
 * Part of the Waldos Economy Systems suite (Research system).
 *
 * Arguments:
 * 0: _sideKey <ANY> - side key
 * 1: _entry <ANY> - entry
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _entry] call Waldo_fnc_EcoResearch_areResearchRequirementsMet;
 */

        params ["_sideKey", "_entry"];

        private _met = true;
        {
            private _requirement = [_x] call Waldo_fnc_EcoCore_trimString;
            if (_requirement isEqualTo "") then {continue;};

            private _researchEntry = [_requirement, call Waldo_fnc_EcoResearch_getResearchCatalog] call Waldo_fnc_EcoResearch_getResearchEntryByName;
            private _requirementMet = false;
            if ((count _researchEntry) > 0) then {
                _requirementMet = [_sideKey, _requirement] call Waldo_fnc_EcoResearch_isResearchCompletedForSide;
            } else {
                if (!isNil "Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide") then {
                    _requirementMet = [_requirement, _sideKey] call Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide;
                };
            };

            if !_requirementMet exitWith {
                _met = false;
            };
        } forEach (_entry param [3, []]);

        _met

