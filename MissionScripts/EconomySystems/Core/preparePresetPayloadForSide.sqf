/*
 * Author: Waldo
 * Prepare preset payload for side.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _payload <ARRAY> - payload (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_payload, _sideKey] call Waldo_fnc_EcoCore_preparePresetPayloadForSide;
 */

    params [
        ["_payload", []],
        ["_sideKey", ""]
    ];

    private _payloads = [_payload] call Waldo_fnc_EcoCore_collectKnownModuleImportPayloads;
    if ((count _payloads) <= 0) exitWith {[]};

    private _purchaseSideName = [_sideKey] call Waldo_fnc_EcoCore_getPresetPurchaseSideName;
    private _prepared = [];

    {
        private _modulePayload = +_x;

        if ((_modulePayload param [0, ""]) isEqualTo "WaldoEcoBuy_PURCHASE_V1") then {
            private _catalog = [];

            {
                private _entry = +_x;
                if ((count _entry) > 6) then {
                    _entry set [6, _purchaseSideName];
                };
                _catalog pushBack _entry;
            } forEach (_modulePayload param [1, []]);

            _modulePayload set [1, _catalog];
        };

        _prepared pushBack _modulePayload;
    } forEach _payloads;

    _prepared
