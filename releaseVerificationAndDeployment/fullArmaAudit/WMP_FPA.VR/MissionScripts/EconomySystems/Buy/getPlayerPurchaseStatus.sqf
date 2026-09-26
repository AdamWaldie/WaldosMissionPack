/*
 * Author: WaldoTheWarfighter
 * Reports why a player cannot buy a catalog entry at the given origin.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _sideKey <STRING> - side key (optional, default: "NONE")
 * 1: _entry <ARRAY> - entry (optional, default: [])
 * 2: _origin <ARRAY> - origin (optional, default: [0, 0, 0])
 *
 * Return Value:
 * <STRING> status code; "ready" when all checks pass.
 *
 * Example:
 * [_sideKey, _entry, _origin] call Waldo_fnc_EcoBuy_getPlayerPurchaseStatus;
 * Locality/Authority: Interface/authority query; reads published Economy state and local
 * player command authority. Server validates again before purchase execution.
 * Repeat/JIP Behaviour: Repeat-safe read; JIP sees current public catalog/resources.
 * Current Callers: Purchase terminal action availability and player feedback.
 * Result: Returns the first blocking status, including missing delivery point.
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

