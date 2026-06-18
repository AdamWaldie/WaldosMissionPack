/*
 * Author: Waldo
 * Refresh unified purge prompt.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _disp <ANY> - disp (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCore_refreshUnifiedPurgePrompt;
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    private _bg = _disp getVariable ["WaldoEcoCore_PurgeBG", controlNull];
    private _warning = _disp getVariable ["WaldoEcoCore_PurgeWarning", controlNull];
    private _button = _disp getVariable ["WaldoEcoCore_PurgeButton", controlNull];
    if (isNull _bg || isNull _warning || isNull _button) exitWith {};

    private _remaining = 0 max (_disp getVariable ["WaldoEcoCore_PurgeConfirmRemaining", 0]);
    if (_remaining > 0) then {
        _bg ctrlSetBackgroundColor [0.30, 0.03, 0.03, 0.92];
        _warning ctrlSetText format [
            "Purge Primed, are you sure you wish to go ahead? Press Purge %1 more times to accept the purge.",
            _remaining
        ];
        _button ctrlSetText format ["PURGE (%1)", _remaining];
    } else {
        _bg ctrlSetBackgroundColor [0.06, 0.02, 0.02, 0.90];
        _warning ctrlSetText "Danger zone. Select what to purge, then press Purge to arm the confirmation.";
        _button ctrlSetText "Purge";
    };

    _bg ctrlCommit 0;
    _warning ctrlCommit 0;
    _button ctrlCommit 0;
