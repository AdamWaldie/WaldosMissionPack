/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - canSideUsePurchase
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_canSideUsePurchase via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_entry", []], ["_sideKey", "NONE"]];

        if ((count _entry) <= 0) exitWith {false};

        private _allowed = _entry param [6, "EVERYONE"];
        if (_allowed isEqualTo "EVERYONE") exitWith {true};
        ([_sideKey] call Waldo_fnc_EcoBuy_getPlayerPurchaseSideLabel) isEqualTo _allowed

