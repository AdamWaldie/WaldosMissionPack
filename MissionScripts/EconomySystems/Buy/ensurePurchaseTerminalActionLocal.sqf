/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - ensurePurchaseTerminalActionLocal
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_purchaseTerminal", objNull]];

        if (!hasInterface) exitWith {-1};
        if (isNull _purchaseTerminal) exitWith {-1};
        if !(_purchaseTerminal getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]) exitWith {-1};

        [
            _purchaseTerminal,
            "WaldoEcoBuy_PurchaseActionAddedLocalV2",
            call Waldo_fnc_EcoBuy_getOfficialPurchaseActionArgs
        ] call Waldo_fnc_EcoCore_publishPubZeusObjectAction

