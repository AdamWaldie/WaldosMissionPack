/*
 * Author: Waldo
 * Get official building inspect action args.
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
 * [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingInspectActionArgs;
 */

        params [["_entry", []]];

        [
            format ["Inspect %1", _entry param [0, "Building"]],
            {
                params ["_target"];

                private _buildName = _target getVariable ["WaldoEcoBuild_BuildDefinitionName", "Building"];
                private _catalog = missionNamespace getVariable ["WaldoEcoBuild_BuildCatalog", []];
                if ((typeName _catalog) != "ARRAY") then {_catalog = [];};

                private _entryIndex = _catalog findIf {((_x param [0, ""]) == _buildName)};
                private _entry = if (_entryIndex >= 0) then {_catalog select _entryIndex} else {[]};

                private _ownerSide = _target getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"];
                private _ownerLabel = switch (_ownerSide) do {
                    case "WEST": {"BLUFOR"};
                    case "EAST": {"OPFOR"};
                    case "GUER": {"INDEPENDENT"};
                    case "CIV": {"CIVILIAN"};
                    default {"NONE"};
                };

                private _statusText = if (_target getVariable ["WaldoEcoBuild_Operational", true]) then {"ACTIVE"} else {"DISABLED"};
                if (_target getVariable ["WaldoEcoBuild_IsUpgrading", false]) then {
                    _statusText = format ["UPGRADING to %1", _target getVariable ["WaldoEcoBuild_UpgradeTargetName", ""]];
                };
                private _reason = _target getVariable ["WaldoEcoBuild_DisabledReason", ""];
                if (_reason != "") then {_statusText = _statusText + " - " + _reason;};

                private _desc = if ((count _entry) > 0) then {_entry param [1, ""]} else {_target getVariable ["WaldoEcoBuild_BuildDescription", ""]};
                private _effects = [];
                if ((count _entry) > 0) then {
                    private _produceResource = _entry param [9, ""];
                    private _produceAmount = floor (_entry param [10, 0]);
                    private _produceInterval = floor (_entry param [11, 0]);
                    if (_produceResource != "" && {_produceAmount > 0} && {_produceInterval > 0}) then {
                        _effects pushBack format ["Produces %1 %2/%3s", _produceAmount, _produceResource, _produceInterval];
                    };

                    private _upkeepRows = _entry param [15, []];
                    private _upkeepInterval = floor (_entry param [16, 0]);
                    if ((typeName _upkeepRows) == "ARRAY" && {(count _upkeepRows) > 0} && {_upkeepInterval > 0}) then {
                        private _upkeepText = (_upkeepRows apply {format ["%1 %2", floor (_x param [1, 0]), _x param [0, ""]]}) joinString ", ";
                        _effects pushBack format ["Upkeep %1/%2s", _upkeepText, _upkeepInterval];
                    };

                    private _storageRows = _entry param [17, []];
                    if ((typeName _storageRows) == "ARRAY" && {(count _storageRows) > 0}) then {
                        private _storageText = (_storageRows apply {format ["%1 %2", floor (_x param [1, 0]), _x param [0, ""]]}) joinString ", ";
                        _effects pushBack format ["Storage %1", _storageText];
                    };

                    if ((_entry param [12, 0]) > 0) then {_effects pushBack format ["Research speed +%1%%", _entry param [12, 0]];};
                    if ((_entry param [13, 0]) > 0) then {_effects pushBack format ["Build speed +%1%%", _entry param [13, 0]];};
                    if ((_entry param [14, 0]) > 0) then {_effects pushBack format ["Detector range %1m", _entry param [14, 0]];};
                };
                if ((count _effects) <= 0) then {_effects pushBack "No active effects";};

                hintSilent format [
                    "%1 | Owner: %2 | Status: %3 | %4 | Effects: %5",
                    _buildName,
                    _ownerLabel,
                    _statusText,
                    _desc,
                    _effects joinString "; "
                ];
            },
            nil,
            1.5,
            true,
            true,
            "",
            "true",
            20
        ]

