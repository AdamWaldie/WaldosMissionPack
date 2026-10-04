/*
 * Author: WaldoTheWarfighter
 * Validates a purchasable-asset row against class, fields and prerequisite links.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * <BOOL> true when the catalog row has a validation error.
 *
 * Example:
 * [_entry, _catalog] call Waldo_fnc_EcoBuy_hasPurchaseEntryError;
 * Locality/Authority: Any machine; pure row validation.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Purchase catalog filtering, status and server execution.
 * Result: Invalid rows are rejected before appearing as usable purchases.
 */

        params [["_entry", []], ["_catalog", []]];

        if ((count _entry) <= 0) exitWith {true};

        private _resourceTypes = call Waldo_fnc_EcoResource_getResourceTypes;
        private _hasError = false;
        {
            private _resourceName = toLower (_x param [0, ""]);
            if ((_resourceTypes findIf {(toLower _x) isEqualTo _resourceName}) < 0) exitWith {
                _hasError = true;
            };
        } forEach (_entry param [2, []]);
        if (_hasError) exitWith {true};

        private _requirements = _entry param [3, []];
        private _researchCatalog = if (!isNil "Waldo_fnc_EcoResearch_getResearchCatalog") then {call Waldo_fnc_EcoResearch_getResearchCatalog} else {[]};
        private _buildCatalog = if (!isNil "Waldo_fnc_EcoBuild_getBuildCatalog") then {call Waldo_fnc_EcoBuild_getBuildCatalog} else {[]};

        {
            private _req = toLower _x;
            private _researchFound = (_researchCatalog findIf {(toLower (_x param [0, ""])) isEqualTo _req}) >= 0;
            private _buildFound = (_buildCatalog findIf {(toLower (_x param [0, ""])) isEqualTo _req}) >= 0;
            if !(_researchFound || _buildFound) exitWith {
                _hasError = true;
            };
        } forEach _requirements;

        _hasError

