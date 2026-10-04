/*
 * Author: WaldoTheWarfighter
 * Spawns and registers a Purchase Terminal laptop at a supplied position and bearing.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 * 1: _dir <NUMBER> - bearing in degrees (optional, default: 0)
 *
 * Return Value:
 * <OBJECT> created terminal on authority, or objNull when forwarded from a client.
 *
 * Example:
 * [_pos, _dir] call Waldo_fnc_EcoBuy_spawnPurchaseLaptop;
 * Locality/Authority: Server creates the laptop; client/ZEN calls forward there.
 * Repeat/JIP Behaviour: Each call creates a new object; its public tag and registry allow
 * joining clients to install their own actions.
 * Current Callers: Purchasing ZEN placement and exported mission setup calls.
 * Result: A usable Land_Laptop_unfolded_F Purchase Terminal appears.
 */

        params [
            ["_pos", [0, 0, 0]],
            ["_dir", 0]
        ];

        // Authority-only creation; forward to the server when called on a client (dedicated-safe).
        if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {
            _this remoteExec ["Waldo_fnc_EcoBuy_spawnPurchaseLaptop", 2];
            objNull
        };

        private _purchaseTerminal = createVehicle ["Land_Laptop_unfolded_F", _pos, [], 0, "CAN_COLLIDE"];
        _purchaseTerminal setPosATL _pos;
        _purchaseTerminal setDir _dir;
        _purchaseTerminal enableSimulationGlobal false;
        _purchaseTerminal allowDamage false;
        _purchaseTerminal setVariable ["WaldoEcoBuy_IsPurchaseTerminal", true, true];
        [_purchaseTerminal, "PURCHASE_TERMINALS"] call Waldo_fnc_EcoCore_registerRuntimeObject;

        clearWeaponCargoGlobal _purchaseTerminal;
        clearMagazineCargoGlobal _purchaseTerminal;
        clearItemCargoGlobal _purchaseTerminal;
        clearBackpackCargoGlobal _purchaseTerminal;
        // This object has just been created and has no WMP-owned actions yet.
        // Never use removeAllActions here: mission makers may wrap or replace
        // this creator and unrelated systems must retain ownership of theirs.

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

        diag_log format ["[WMP ECO] Purchase terminal created object=%1 position=%2 direction=%3 authority=%4", netId _purchaseTerminal, getPosATL _purchaseTerminal, getDir _purchaseTerminal, clientOwner];
        _purchaseTerminal

