/*
 * Author: WaldoTheWarfighter
 * Converts the economy state authored through Purchasing Zeus modules into public setup calls.
 *
 * Arguments:
 * 0: include purchase definitions
 * 1: include delivery points and player terminals
 *
 * Return Value:
 * ARRAY of STRING - ordered SQF statements.
 */
params [
    ["_includeDefinitions", true, [false]],
    ["_includePlacements", true, [false]]
];

private _lines = ["// PURCHASING MODULE SETUP"];

if (_includeDefinitions) then {
    _lines pushBack "// Purchasing: Define Vehicle Catalogue";
    _lines pushBack (str [call Waldo_fnc_EcoBuy_getPurchaseCatalog] + " call Waldo_fnc_EcoBuy_setPurchaseCatalog;");
};

if (_includePlacements) then {
    _lines pushBack "";
    _lines pushBack "// Purchasing: Place Delivery Points";
    {
        private _arguments = [
            _x param [2, [0, 0, 0]],
            _x param [1, "Ground"],
            _x param [3, 0],
            _x param [5, "ANY"]
        ];
        _lines pushBack (str _arguments + " call Waldo_fnc_EcoBuy_createDropPoint;");
    } forEach (call Waldo_fnc_EcoBuy_getDropPoints);

    _lines pushBack "";
    _lines pushBack "// Purchasing: Place Player Terminals";
    {
        _lines pushBack (str [getPosATL _x, getDir _x] + " call Waldo_fnc_EcoBuy_spawnPurchaseLaptop;");
    } forEach ((allMissionObjects "Land_Laptop_unfolded_F") select {
        _x getVariable ["WaldoEcoBuy_IsPurchaseTerminal", false]
    });
};

_lines
