/*
 * Author: Waldo
 * Get player purchase status.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _entry <ARRAY> - entry (optional, default: [])
 * 2: _origin <ARRAY> - origin (optional, default: [0, 0, 0])
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_sideKey, _entry, _origin] call Waldo_fnc_EcoBuy_getPlayerPurchaseStatus;
 */

        params [["_sideKey", "NONE"], ["_entry", []], ["_origin", [0, 0, 0]]];

        if ((count _entry) <= 0) exitWith {"invalid"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuy_canSideUsePurchase) exitWith {"side"};
        if (!(isNil "Waldo_fnc_EcoCommand_hasCommandAuthority") && {!([player] call Waldo_fnc_EcoCommand_hasCommandAuthority)}) exitWith {"command"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuy_arePurchaseRequirementsMetForSide) exitWith {"requirements"};
        if !([_entry, _sideKey] call Waldo_fnc_EcoBuy_canAffordPurchaseForSide) exitWith {"cost"};
        if (!isServer) exitWith {
            if ((count ([(_entry param [5, "Ground"]), _sideKey] call Waldo_fnc_EcoBuy_getDropPointsForType)) <= 0) then {"drop"} else {"ready"};
        };
        if ((count ([(_entry param [5, "Ground"]), _origin, _entry param [4, ""], _sideKey] call Waldo_fnc_EcoBuy_findAvailableDropPoint)) <= 0) exitWith {"drop"};
        "ready"

