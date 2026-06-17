/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getOfficialBuildingClaimActionArgs
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getOfficialBuildingClaimActionArgs via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []]];

        [
            format ["Claim %1", _entry param [0, "Building"]],
            {
                params ["_target", "_caller"];

                private _actor = _caller;
                if (isNull _actor) then {_actor = player;};

                private _uid = getPlayerUID player;
                if (_uid == "") then {_uid = name _actor;};
                private _requestId = format ["%1_%2_%3", _uid, floor (diag_tickTime * 1000), floor (random 1000000)];

                _target setVariable ["WaldoEcoBuild_BuildingManageRequest", ["CLAIM", netId _actor, _requestId], true];
                hintSilent "Claim request sent.";
            },
            nil,
            1.5,
            true,
            true,
            "",
            "private _sideKey = switch (side group _this) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'};}; (_sideKey in ['WEST','EAST','GUER']) && {(_target getVariable ['WaldoEcoBuild_BuildOwnerSideKey','NONE']) != _sideKey} && {!(_target getVariable ['WaldoEcoBuild_IsUpgrading', false])}",
            20
        ]

