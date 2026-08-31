/*
 * Author: WaldoTheWarfighter
 * Get official building claim action args.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 * Locality / Authority: Built and invoked on each interface client; the action submits its unchanged
 * request payload to Waldo_fnc_EcoCore_submitRequestServer for authoritative server processing.
 * Repeat / JIP Behaviour: Returns stable action arguments whenever local registry reconciliation runs;
 * the existing action installer owns repeat-safe replacement and JIP installation.
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 *
 * Return Value:
 * Any - see function body
 *
 * Current Callers: Economy building action reconciliation.
 *
 * Example:
 * [_entry] call Waldo_fnc_EcoBuild_getOfficialBuildingClaimActionArgs;
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

                [
                    "MANAGE_BUILDING",
                    _target,
                    ["CLAIM", netId _actor, _requestId]
                ] call Waldo_fnc_EcoCore_submitRequestServer;
                ["Claim request sent."] call Waldo_fnc_EcoCore_notifyActorLocal;
            },
            nil,
            1.5,
            true,
            true,
            "",
            "private _sideKey = switch (side group _this) do {case west: {'WEST'}; case east: {'EAST'}; case independent: {'GUER'}; default {'CIV'};}; (_sideKey in ['WEST','EAST','GUER']) && {(_target getVariable ['WaldoEcoBuild_BuildOwnerSideKey','NONE']) != _sideKey} && {!(_target getVariable ['WaldoEcoBuild_IsUpgrading', false])}",
            20
        ]

