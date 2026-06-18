/*
 * Author: Waldo
 * Ensure crate action local.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _crate <OBJECT> - crate (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_crate] call Waldo_fnc_EcoResource_ensureCrateActionLocal;
 */

    params [["_crate", objNull]];

    if (isNull _crate) exitWith {-1};
    if !(_crate getVariable ["WaldoEcoResource_IsResourceCrate", false]) exitWith {-1};

    [
        _crate,
        "WaldoEcoResource_CollectActionAddedLocal",
        [
            "Collect Resources",
            {
                params ["_target", "_caller", "_actionId", "_args"];

                if !(isNil "Waldo_fnc_EcoResource_collectCrate") exitWith {
                    [_target, _caller] call Waldo_fnc_EcoResource_collectCrate;
                };

                if (isNull _target) exitWith {};
                if (isNull _caller) exitWith {};
                if (!alive _caller) exitWith {};
                if (_target getVariable ["WaldoEcoResource_Collected", false]) exitWith {};

                private _requestId = format [
                    "%1_%2_%3",
                    getPlayerUID _caller,
                    floor (diag_tickTime * 1000),
                    floor (random 1000000)
                ];
                _target setVariable ["WaldoEcoResource_CollectRequest", [netId _caller, getPlayerUID _caller, name _caller, _requestId], true];
                hintSilent "Collection request sent.";
            },
            nil,
            1.5,
            true,
            true,
            "",
            "true",
            5
        ]
    ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction
