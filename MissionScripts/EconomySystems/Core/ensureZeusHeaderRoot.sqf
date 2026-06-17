/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - ensureZeusHeaderRoot
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_ensureZeusHeaderRoot via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_tree", controlNull]];

    if (isNull _tree) exitWith {-1};

    private _headerIndex = [_tree, WaldoEcoCore_ZeusHeaderRootText] call Waldo_fnc_EcoCore_getOrAddTreeRootIndex;
    _tree tvSetTooltip [[_headerIndex], WaldoEcoCore_ZeusHeaderRootTooltip];
    _tree tvSetColor [[_headerIndex], WaldoEcoCore_ZeusHeaderRootColor];

    _headerIndex
