/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - deleteDisplayControlsByVars
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_deleteDisplayControlsByVars via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_disp", displayNull], ["_varNames", []]];
    if (isNull _disp) exitWith {};

    {
        private _ctrl = _disp getVariable [_x, controlNull];
        if (!isNull _ctrl) then {
            ctrlDelete _ctrl;
        };
        _disp setVariable [_x, controlNull];
    } forEach _varNames;
