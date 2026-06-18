/*
 * Author: Waldo
 * Spawn purchase laptop.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 * 1: _dir <SCALAR> - dir (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_pos, _dir] call Waldo_fnc_EcoBuy_spawnPurchaseLaptop;
 */

        params [
            ["_pos", [0, 0, 0]],
            ["_dir", 0]
        ];

        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {objNull};

        private _purchaseTerminal = createVehicle ["Land_Laptop_unfolded_F", _pos, [], 0, "CAN_COLLIDE"];
        _purchaseTerminal setPosATL _pos;
        _purchaseTerminal setDir _dir;
        _purchaseTerminal enableSimulationGlobal false;
        _purchaseTerminal allowDamage false;
        _purchaseTerminal setVariable ["WaldoEcoBuy_IsPurchaseTerminal", true, true];

        clearWeaponCargoGlobal _purchaseTerminal;
        clearMagazineCargoGlobal _purchaseTerminal;
        clearItemCargoGlobal _purchaseTerminal;
        clearBackpackCargoGlobal _purchaseTerminal;
        removeAllActions _purchaseTerminal;

        [[_purchaseTerminal], true] call Waldo_fnc_EcoCore_registerCuratorEditableObjects;

        if (hasInterface) then {
            [_purchaseTerminal] spawn {
                params [["_terminal", objNull]];
                uiSleep 1;
                if (!isNull _terminal) then {
                    [_terminal] call Waldo_fnc_EcoBuy_ensurePurchaseTerminalActionLocal;
                };
            };
        };

        _purchaseTerminal

