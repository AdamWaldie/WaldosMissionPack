/*
 * Author: Waldo
 * This module allows players to add/remove to/from the fortify budget of a given side, so long as fortify is active and setup for that side.
 *
 * Arguments:
 * 0: modulePos <POSITION>
 * 1: objectPos <OBJECT>
 *
 * Example:
 * [] call Waldo_fnc_FortifyBudgetModule;
 *
 * Public: No
 */

params ["_objectPos"];

[
    "Fortify Budget Manager", 
    [
        // Slider to set the budget alteration amount
        ["SLIDER", ["Alteration Amount", "Set the amount to adjust the budget."], [0, 500, 1000, 0], false],

        // Checkbox to decide if the budget alteration should be subtracted or added
        ["CHECKBOX", ["Subtract Amount?", "If checked, the amount will be subtracted. Otherwise, it will be added."], false],

        // Combo box to select the side to alter the budget for
        ["COMBO", ["Target Side", "Choose the side to adjust the budget for."],
            [
                [west, east, independent, civilian],
                ["BLUFOR", "OPFOR", "INDFOR", "CIVILIAN"],
                0
            ],
            false
        ]
    ],
    {
        // Callback function after the dialog is closed
        params ["_args"];
        _args params ["_budget","_isNegative","_sideToAlter"];

        // Round the price to the nearest multiple of 5
        _budget = ceil(_budget / 5) * 5;

        // If the checkbox for making the budget a negative is ticked, negate the budget
        if (_isNegative) then {
            _budget = ceil(-_budget);
        };

        // Update the ACE fortify budget for the selected side
        [_sideToAlter, _budget, true] call ace_fortify_fnc_updateBudget;
    }
] call zen_dialog_fnc_create;

