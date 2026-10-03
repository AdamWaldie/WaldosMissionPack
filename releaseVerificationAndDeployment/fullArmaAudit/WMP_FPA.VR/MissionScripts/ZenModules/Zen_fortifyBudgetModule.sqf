/*
 * Author: WaldoTheWarfighter
 * This module allows players to add/remove to/from the fortify budget of a given side, so long as fortify is active and setup for that side.
 * Locality and authority: Curator interface chooses amount and side; the server validates and
 * applies the budget change through Waldo_fnc_ZenFortifyBudgetServer.
 * Repeat/JIP: Every submitted change is a separate budget adjustment. The dialog has no local
 * handler or JIP replay of its own.
 *
 * Arguments:
 * 0: modulePos <POSITION>
 * 1: objectPos <OBJECT>
 *
 * Example:
 * [] call Waldo_fnc_FortifyBudgetModule;
 * Return Value: Nothing useful; the dialog submits asynchronously.
 * Current caller: ZEN Fortify Budget Manager module registration.
 * Result: The chosen side's active ACE Fortify budget increases or decreases after validation.
 *
 * Public: No
 */

[
    "Fortify Budget Manager", 
    [
        // Slider to set the budget alteration amount
        ["SLIDER", ["Alteration Amount", "Amount added to or removed from the selected side's fortify budget."], [0, 500, 100, 0], false],

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

        // The shared budget belongs to the server. The dedicated curator client only submits it.
        [_sideToAlter, _budget, player] remoteExecCall ["Waldo_fnc_ZenFortifyBudgetServer", 2];
    }
] call zen_dialog_fnc_create;

