/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResearch system - hasResearchEntryError
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResearch_hasResearchEntryError via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []], ["_catalog", []]];

        if ((count _entry) <= 0) exitWith {true};

        private _resourceTypes = call Waldo_fnc_EcoResource_getResourceTypes;
        private _researchNames = _catalog apply {toLower (_x param [0, ""])};
        private _buildCatalog = if (!isNil "Waldo_fnc_EcoBuild_getBuildCatalog") then {call Waldo_fnc_EcoBuild_getBuildCatalog} else {[]};
        private _buildNames = _buildCatalog apply {toLower (_x param [0, ""])};
        private _selfName = toLower (_entry param [0, ""]);
        private _hasError = false;

        {
            private _resourceName = _x param [0, ""];
            if ((_resourceTypes findIf {_x isEqualTo _resourceName}) < 0) exitWith {
                _hasError = true;
            };
        } forEach (_entry param [2, []]);
        if (_hasError) exitWith {true};

        {
            private _requirement = toLower _x;
            if (_requirement isEqualTo _selfName) exitWith {
                _hasError = true;
            };
            if (((_researchNames find _requirement) < 0) && {(_buildNames find _requirement) < 0}) exitWith {
                _hasError = true;
            };
        } forEach (_entry param [3, []]);
        if (_hasError) exitWith {true};

        {
            private _exclusive = toLower _x;
            if (_exclusive isEqualTo _selfName) exitWith {
                _hasError = true;
            };
            if ((_researchNames find _exclusive) < 0) exitWith {
                _hasError = true;
            };
        } forEach (_entry param [8, []]);
        if (_hasError) exitWith {true};

        false

