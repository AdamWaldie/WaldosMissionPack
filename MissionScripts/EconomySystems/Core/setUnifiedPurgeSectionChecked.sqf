/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - setUnifiedPurgeSectionChecked
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_setUnifiedPurgeSectionChecked via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_controls", []], ["_checked", true]];

    {
        if (!isNull _x) then {
            _x cbSetChecked _checked;
            _x ctrlCommit 0;
        };
    } forEach _controls;
