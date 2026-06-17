/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getOfficialBuildingManageActionArgs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getOfficialBuildingManageActionArgs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [
            ["_operation", "DISABLE"],
            ["_entry", []]
        ];

        private _isDisable = _operation == "DISABLE";
        private _label = if (_isDisable) then {
            format ["Disable %1", _entry param [0, "Building"]]
        } else {
            format ["Enable %1", _entry param [0, "Building"]]
        };
        private _condition = if (_isDisable) then {
            "private _sideKey = switch (side group _this) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'};}; private _gc = missionNamespace getVariable ['WaldoEcoCommand_GroundCommandUIDs', []]; if ((typeName _gc) != 'ARRAY') then {_gc = [];}; private _key = _this getVariable ['WaldoEcoCommand_GroundCommandKey', '']; if (_key == '') then {_key = player getVariable ['WaldoEcoCommand_GroundCommandKey', ''];}; private _hasGc = ((count _gc) <= 0) || {(_key != '') && {(_gc find _key) >= 0}}; ((_target getVariable ['WaldoEcoBuild_BuildOwnerSideKey', 'NONE']) == _sideKey) && {_hasGc} && {_target getVariable ['WaldoEcoBuild_Operational', true]} && {!(_target getVariable ['WaldoEcoBuild_IsUpgrading', false])}"
        } else {
            "private _sideKey = switch (side group _this) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'};}; private _gc = missionNamespace getVariable ['WaldoEcoCommand_GroundCommandUIDs', []]; if ((typeName _gc) != 'ARRAY') then {_gc = [];}; private _key = _this getVariable ['WaldoEcoCommand_GroundCommandKey', '']; if (_key == '') then {_key = player getVariable ['WaldoEcoCommand_GroundCommandKey', ''];}; private _hasGc = ((count _gc) <= 0) || {(_key != '') && {(_gc find _key) >= 0}}; ((_target getVariable ['WaldoEcoBuild_BuildOwnerSideKey', 'NONE']) == _sideKey) && {_hasGc} && {!(_target getVariable ['WaldoEcoBuild_Operational', true])} && {!(_target getVariable ['WaldoEcoBuild_IsUpgrading', false])}"
        };

        [
            _label,
            {
                params ["_target", "_caller", "_actionId", "_arguments"];

                private _operation = _arguments param [0, ""];
                if !(_operation in ["DISABLE", "ENABLE"]) exitWith {};

                private _actor = _caller;
                if (isNull _actor) then {_actor = player;};

                private _uid = getPlayerUID player;
                if (_uid == "") then {_uid = name _actor;};
                private _requestId = format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)];

                _target setVariable ["WaldoEcoBuild_BuildingManageRequest", [_operation, netId _actor, _requestId], true];

                private _text = if (_operation == "DISABLE") then {"Disable"} else {"Enable"};
                hintSilent format ["%1 request sent.", _text];
            },
            [_operation],
            1.5,
            true,
            true,
            "",
            _condition,
            20
        ]

