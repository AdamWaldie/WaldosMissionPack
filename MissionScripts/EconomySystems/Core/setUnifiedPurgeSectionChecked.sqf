/*
 * Author: Waldo
 * Set unified purge section checked.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _controls <ARRAY> - controls (optional, default: [])
 * 1: _checked <BOOL> - checked (optional, default: true)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_controls, _checked] call Waldo_fnc_EcoCore_setUnifiedPurgeSectionChecked;
 */

    params [["_controls", []], ["_checked", true]];

    {
        if (!isNull _x) then {
            _x cbSetChecked _checked;
            _x ctrlCommit 0;
        };
    } forEach _controls;
