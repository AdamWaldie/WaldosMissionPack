/*
 * Author: Waldo
 * Can side use purchase.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuy_canSideUsePurchase;
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _allowed = _entry param [6, "EVERYONE"];
        if (_allowed isEqualTo "EVERYONE") exitWith {true};
        ([_sideKey] call Waldo_fnc_EcoBuy_getPlayerPurchaseSideLabel) isEqualTo _allowed

