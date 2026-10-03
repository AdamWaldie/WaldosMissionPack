/*
 * Author: WaldoTheWarfighter
 * Checks whether an asset is available to the specified side.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _entry <ARRAY> - entry (optional, default: [])
 * 1: _sideKey <STRING> - side key (optional, default: "NONE")
 *
 * Return Value:
 * <BOOL> true for EVERYONE entries or a matching side.
 *
 * Example:
 * [_entry, _sideKey] call Waldo_fnc_EcoBuy_canSideUsePurchase;
 * Locality/Authority: Any machine; pure check against the catalog row.
 * Repeat/JIP Behaviour: Stateless; JIP receives the same published row.
 * Current Callers: Purchase status and authoritative purchase validation.
 * Result: Returns false for an empty row or a side-restricted mismatch.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _allowed = _entry param [6, "EVERYONE"];
        if (_allowed isEqualTo "EVERYONE") exitWith {true};
        ([_sideKey] call Waldo_fnc_EcoBuy_getPlayerPurchaseSideLabel) isEqualTo _allowed

