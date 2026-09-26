/*
 * Author: WaldoTheWarfighter
 * Validates a Construction definition's fields, class and linked requirements.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _catalog <ARRAY> - catalog (optional, default: [])
 *
 * Return Value:
 * <BOOL> true when the definition is invalid.
 *
 * Example:
 * [_entry, _catalog] call Waldo_fnc_EcoBuild_hasBuildEntryError;
 * Locality/Authority: Any machine; read-only definition validation.
 * Repeat/JIP Behaviour: Stateless; no JIP effect.
 * Current Callers: Build catalog filtering, status and authoritative start gates.
 * Result: Missing classes or unresolved upgrade links are rejected.
 */

        params [["_entry", []], ["_catalog", []]];

        if ((count _entry) <= 0) exitWith {true};

        private _resourceTypes = call Waldo_fnc_EcoResource_getResourceTypes;
        private _buildNames = _catalog apply {toLower (_x param [0, ""])};
        private _researchCatalog = if (!isNil "Waldo_fnc_EcoResearch_getResearchCatalog") then {call Waldo_fnc_EcoResearch_getResearchCatalog} else {[]};
        private _researchNames = _researchCatalog apply {toLower (_x param [0, ""])};
        private _selfName = toLower (_entry param [0, ""]);
        private _hasError = false;

        // A buildable without a real CfgVehicles class cannot be represented
        // honestly. Do not allow the old marker-light fallback to make it look
        // like construction succeeded.
        private _className = _entry param [8, ""];
        if (_className isEqualTo "") exitWith {true};
        if !(isClass (configFile >> "CfgVehicles" >> _className)) exitWith {true};

        {
            private _resourceName = _x param [0, ""];
            if ((_resourceTypes findIf {_x isEqualTo _resourceName}) < 0) exitWith {
                _hasError = true;
            };
        } forEach (_entry param [2, []]);
        if (_hasError) exitWith {true};

        private _produceResource = _entry param [9, ""];
        private _produceAmount = _entry param [10, 0];
        private _produceInterval = _entry param [11, 0];
        private _upkeepCosts = _entry param [15, []];
        private _upkeepInterval = _entry param [16, 0];
        private _storageRows = [_entry] call Waldo_fnc_EcoBuild_getBuildStorageRows;

        if (
            !(_produceResource isEqualTo "")
            || {_produceAmount > 0}
            || {_produceInterval > 0}
        ) then {
            if ((_resourceTypes findIf {_x isEqualTo _produceResource}) < 0) then {
                _hasError = true;
            };
            if (_produceAmount <= 0 || {_produceInterval <= 0}) then {
                _hasError = true;
            };
        };
        if (_hasError) exitWith {true};

        {
            private _resourceName = _x param [0, ""];
            if ((_resourceTypes findIf {_x isEqualTo _resourceName}) < 0) exitWith {
                _hasError = true;
            };
        } forEach _upkeepCosts;
        if (_hasError) exitWith {true};

        {
            private _resourceName = _x param [0, ""];
            if ((_resourceTypes findIf {_x isEqualTo _resourceName}) < 0) exitWith {
                _hasError = true;
            };
        } forEach _storageRows;
        if (_hasError) exitWith {true};

        if (((count _upkeepCosts) > 0) || {_upkeepInterval > 0}) then {
            if ((count _upkeepCosts) <= 0 || {_upkeepInterval <= 0}) exitWith {
                _hasError = true;
            };
        };
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

        private _upgradeTarget = toLower (_entry param [18, ""]);
        if (_upgradeTarget isNotEqualTo "") then {
            if (_upgradeTarget isEqualTo _selfName) exitWith {true};
            if ((_buildNames find _upgradeTarget) < 0) exitWith {true};
        };

        false

