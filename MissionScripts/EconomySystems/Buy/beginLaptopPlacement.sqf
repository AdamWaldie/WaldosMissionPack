/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuy system - beginLaptopPlacement
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuy_beginLaptopPlacement via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        if (!hasInterface) exitWith {};

        private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _disp) exitWith {};

        [_disp] call Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt;
        [_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;
        [_disp] call Waldo_fnc_EcoBuy_stopDropPointPlacement;

        if (!isNil "Waldo_fnc_EcoResource_stopResourceCratePlacement") then {
            [_disp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;
        };

        [
            _disp,
            "WaldoEcoBuy_PlacementPending",
            "WaldoEcoBuy_PlacementEH",
            "WaldoEcoBuy_PlacementKeyEH",
            {
                [call Waldo_fnc_EcoBuy_getPlacementPos, getDir curatorCamera]
            },
            {
                params ["_display", "_payload"];
                private _pos = _payload param [0, [0, 0, 0]];
                private _dir = _payload param [1, 0];
                [_pos, _dir] call Waldo_fnc_EcoBuy_spawnPurchaseLaptop;
            }
        ] call Waldo_fnc_EcoCore_beginZeusPlacementSession;

