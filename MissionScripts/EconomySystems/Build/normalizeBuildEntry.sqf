/*
 * Author: Waldo
 * Normalize build entry.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_normalizeBuildEntry;
 */

        params [["_entry", []]];

        private _name = [(_entry param [0, ""])] call Waldo_fnc_EcoCore_trimString;
        if (_name isEqualTo "") exitWith {[]};

        private _desc = [(_entry param [1, ""])] call Waldo_fnc_EcoCore_trimString;
        private _costs = [(_entry param [2, []])] call Waldo_fnc_EcoCore_normalizeNameValueRows;
        private _requirements = [(_entry param [3, []])] call Waldo_fnc_EcoCore_normalizeNameList;
        private _buildTime = 1 max (floor (_entry param [4, 60]));
        private _icon = [(_entry param [5, call Waldo_fnc_EcoResource_getDefaultResourceIcon])] call Waldo_fnc_EcoCore_trimString;
        private _color = [(_entry param [6, call Waldo_fnc_EcoResource_getDefaultResourceColor])] call Waldo_fnc_EcoResource_normalizeResourceColor;
        private _built = false;
        private _className = [(_entry param [8, ""])] call Waldo_fnc_EcoCore_trimString;
        private _produceResource = [(_entry param [9, ""])] call Waldo_fnc_EcoCore_trimString;
        private _produceAmount = 0 max (floor (_entry param [10, 0]));
        private _produceInterval = 0 max (floor (_entry param [11, 0]));
        private _researchSpeed = 0 max (_entry param [12, 0]);
        private _buildSpeed = 0 max (_entry param [13, 0]);
        private _detectorRange = 0 max (_entry param [14, 0]);
        private _upkeepCosts = [(_entry param [15, []])] call Waldo_fnc_EcoCore_normalizeNameValueRows;
        private _upkeepInterval = 0 max (floor (_entry param [16, 0]));
        private _storageSource = _entry param [17, []];
        if (_storageSource isEqualType [] && {(count _storageSource) > 0} && {!((_storageSource select 0) isEqualType [])}) then {
            _storageSource = [_storageSource];
        };
        private _storageRows = [_storageSource] call Waldo_fnc_EcoCore_normalizeNameValueRows;
        private _upgradeTo = [(_entry param [18, ""])] call Waldo_fnc_EcoCore_trimString;
        private _buildLimit = 0 max (floor (_entry param [19, 0]));
        private _availability = [(_entry param [20, ["ALL"]])] call Waldo_fnc_EcoBuild_normalizeBuildAvailability;
        private _category = [(_entry param [21, ""])] call Waldo_fnc_EcoCore_trimString;

        [
            _name,
            _desc,
            _costs,
            _requirements,
            _buildTime,
            _icon,
            _color,
            _built,
            _className,
            _produceResource,
            _produceAmount,
            _produceInterval,
            _researchSpeed,
            _buildSpeed,
            _detectorRange,
            _upkeepCosts,
            _upkeepInterval,
            _storageRows,
            _upgradeTo,
            _buildLimit,
            _availability,
            _category
        ]

