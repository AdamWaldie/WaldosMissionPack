/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - arePurchaseRequirementsMetForSide
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_arePurchaseRequirementsMetForSide via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _researchCatalog = if (!isNil "Waldo_fnc_EcoResearch_getResearchCatalog") then {call Waldo_fnc_EcoResearch_getResearchCatalog} else {[]};
        private _researchNames = _researchCatalog apply {toLower (_x param [0, ""])};
        private _met = true;

        {
            private _requirement = _x;
            private _lower = toLower _requirement;
            if ((_researchNames find _lower) >= 0) then {
                if (isNil "Waldo_fnc_EcoResearch_isResearchCompletedForSide") then {
                    _met = false;
                } else {
                    if !([_sideKey, _requirement] call Waldo_fnc_EcoResearch_isResearchCompletedForSide) then {
                        _met = false;
                    };
                };
            } else {
                if (isNil "Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide") then {
                    _met = false;
                } else {
                    if !([_requirement, _sideKey] call Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide) then {
                        _met = false;
                    };
                };
            };
            if !_met exitWith {};
        } forEach (_entry param [3, []]);

        _met

