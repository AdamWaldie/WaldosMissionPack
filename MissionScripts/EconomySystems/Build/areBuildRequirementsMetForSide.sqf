/*
 * Author: Waldo
 * Are build requirements met for side.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuild_areBuildRequirementsMetForSide;
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
                if !([_requirement, _sideKey] call Waldo_fnc_EcoBuild_isBuildRequirementSatisfiedForSide) then {
                    _met = false;
                };
            };
            if !_met exitWith {};
        } forEach (_entry param [3, []]);

        _met

