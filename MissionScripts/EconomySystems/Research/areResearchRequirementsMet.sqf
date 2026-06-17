/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - areResearchRequirementsMet
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_areResearchRequirementsMet via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

