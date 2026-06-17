/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - getPlayerPurchaseStatus
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_getPlayerPurchaseStatus via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
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

