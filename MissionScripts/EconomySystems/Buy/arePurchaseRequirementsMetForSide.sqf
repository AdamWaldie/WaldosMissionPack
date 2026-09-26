/*
 * Author: WaldoTheWarfighter
 * Checks whether a side has completed an asset's Research and Build prerequisites.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true only when every prerequisite is satisfied.
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuy_arePurchaseRequirementsMetForSide;
 * Locality/Authority: Any machine can inspect published prerequisite state; the server
 * repeats this check before purchase.
 * Repeat/JIP Behaviour: Pure read; JIP sees current public state.
 * Current Callers: Purchase status and server purchase validation.
 * Result: Returns false at the first unmet named requirement.
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

