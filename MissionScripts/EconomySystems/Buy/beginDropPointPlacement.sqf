/*
 * Author: Waldo
 * Begin drop point placement.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _display <ANY> - display
 * 1: _payload <ANY> - payload
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_display, _payload] call Waldo_fnc_EcoBuy_beginDropPointPlacement;
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
                [_pos, _dir] call Waldo_fnc_EcoBuy_promptDropPoint;
            }
        ] call Waldo_fnc_EcoCore_beginZeusPlacementSession;

