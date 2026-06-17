/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - removeUnifiedZeusMenusFromDisplay
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_removeUnifiedZeusMenusFromDisplay via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _disp) exitWith {};

    private _tree = [_disp] call Waldo_fnc_EcoCore_getZeusTreeControl;
    if (isNull _tree) exitWith {};

    {
        [_tree, _x] call Waldo_fnc_EcoCore_removeTreeSelectionHandlerByVar;
    } forEach [
        "WaldoEcoResource_SelectEH",
        "WaldoEcoResearch_SelectEH",
        "WaldoEcoBuild_SelectEH",
        "WaldoEcoBuy_SelectEH",
        "WaldoEcoCore_SaveSelectEH"
    ];

    {
        [_tree, _x] call Waldo_fnc_EcoCore_removeTreeRootByText;
    } forEach [
        "Buy System",
        "Construction System",
        "Research System",
        "Resource System",
        "Save System",
        WaldoEcoCore_ZeusHeaderRootText
    ];

    {
        _disp setVariable [_x, false];
    } forEach [
        "WaldoEcoResource_MenuInjected",
        "WaldoEcoResearch_MenuInjected",
        "WaldoEcoBuild_MenuInjected",
        "WaldoEcoBuy_MenuInjected",
        "WaldoEcoCore_SaveMenuInjected"
    ];
