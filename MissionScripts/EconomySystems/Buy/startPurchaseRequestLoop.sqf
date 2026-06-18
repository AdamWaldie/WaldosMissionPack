/*
 * Author: Waldo
 * Start purchase request loop.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoBuy_startPurchaseRequestLoop;
 */

        if (!([] call Waldo_fnc_EcoCore_canRunBackgroundAuthority)) exitWith {};
        if (missionNamespace getVariable ["WaldoEcoBuy_PurchaseRequestLoopStarted", false]) exitWith {};
        missionNamespace setVariable ["WaldoEcoBuy_PurchaseRequestLoopStarted", true];

        [] spawn {
            while {[] call Waldo_fnc_EcoCore_isModuleActive} do {
                {
                    private _request = _x getVariable ["WaldoEcoBuy_PurchaseRequest", []];
                    if (_request isEqualType [] && {(count _request) > 0}) then {
                        [_x, _request] call Waldo_fnc_EcoBuy_processPurchaseRequest;
                    };
                } forEach ((allMissionObjects "Land_Laptop_unfolded_F") select {
                    _x getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]
                });

                uiSleep 0.25;
            };

            missionNamespace setVariable ["WaldoEcoBuy_PurchaseRequestLoopStarted", false];
        };

