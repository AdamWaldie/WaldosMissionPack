/*
 * Author: WaldoTheWarfighter
 * Installs or repairs the current Purchase action on one terminal for this client.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _purchaseTerminal <OBJECT> - purchase terminal (optional, default: objNull)
 *
 * Return Value:
 * <NUMBER> local action ID, or -1 without an interface/valid terminal.
 *
 * Example:
 * [_purchaseTerminal] call Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal;
 * Locality/Authority: Interface client only; purchase requests route to server authority.
 * Repeat/JIP Behaviour: Versioned action installation avoids stacking; JIP clients reconcile
 * terminal actions from the published object registry.
 * Current Callers: Economy local world-action reconciliation and terminal registration.
 * Result: This client can open the terminal's Purchasing interaction.
 */

        params [["_purchaseTerminal", objNull]];

        if (!hasInterface) exitWith {-1};
        if (isNull _purchaseTerminal) exitWith {-1};
        if !(_purchaseTerminal getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]) exitWith {-1};

        [
            _purchaseTerminal,
            "WaldoEcoBuy_PurchaseActionAddedLocalV2",
            call Waldo_fnc_EcoBuy_getOfficialPurchaseActionArgs
        ] call Waldo_fnc_EcoCore_publishZeusObjectAction

