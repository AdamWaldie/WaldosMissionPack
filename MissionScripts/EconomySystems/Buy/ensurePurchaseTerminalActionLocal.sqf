/*
 * Author: Waldo
 * Ensure purchase terminal action local.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _purchaseTerminal <OBJECT> - purchase terminal (optional, default: objNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_purchaseTerminal] call Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal;
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

